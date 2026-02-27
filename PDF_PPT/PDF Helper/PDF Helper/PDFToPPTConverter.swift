import UIKit
import PDFKit
import ZIPFoundation

/// Converts PDF to PPTX by rendering each page as an image slide.
struct PDFToPPTConverter {

    private static let debugTag = "[PDFToPPT]"

    /// Returns PDF file as Data from the given URL.
    /// Call startAccessingSecurityScopedResource() on the URL before calling if it came from document picker.
    /// - Parameter url: File URL of the PDF
    /// - Returns: PDF data, or nil if loading fails
    static func getPDFData(from url: URL) -> Data? {
        let path = url.path
        guard FileManager.default.fileExists(atPath: path) else {
            print("\(debugTag) getPDFData FAILED: File does not exist at path: \(path)")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            print("\(debugTag) getPDFData OK: Loaded \(data.count) bytes from \(url.lastPathComponent)")
            return data
        } catch {
            print("\(debugTag) getPDFData FAILED: Cannot read file - \(error.localizedDescription)")
            return nil
        }
    }

    /// Converts PDF to PPTX and saves to FileManager Documents directory.
    /// Uses getPDFData() to load PDF, then creates PPTX with one image per page.
    /// - Parameters:
    ///   - pdfURL: URL of the source PDF
    ///   - outputFileName: Name for the output file (default: "converted.pptx")
    /// - Returns: URL of saved PPTX file, or nil on failure
    static func convertAndSavePDFToPPT(pdfURL: URL, outputFileName: String = "converted.pptx") -> URL? {
        print("\(debugTag) convertAndSavePDFToPPT START: pdfURL=\(pdfURL.path)")

        guard let pdfData = getPDFData(from: pdfURL) else {
            print("\(debugTag) convertAndSavePDFToPPT FAILED at step: getPDFData")
            return nil
        }

        guard let pptData = convertPDFDataToPPTX(pdfData: pdfData) else {
            print("\(debugTag) convertAndSavePDFToPPT FAILED at step: convertPDFDataToPPTX")
            return nil
        }
        print("\(debugTag) convertAndSavePDFToPPT: PPTX data size=\(pptData.count) bytes")

        let fileName = outputFileName.hasSuffix(".pptx") ? outputFileName : outputFileName + ".pptx"
        guard let savedURL = saveToFileManager(data: pptData, fileName: fileName) else {
            print("\(debugTag) convertAndSavePDFToPPT FAILED at step: saveToFileManager")
            return nil
        }
        print("\(debugTag) convertAndSavePDFToPPT SUCCESS: saved to \(savedURL.path)")
        return savedURL
    }

    /// Saves data to FileManager Documents directory.
    static func saveToFileManager(data: Data, fileName: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("\(debugTag) saveToFileManager FAILED: Cannot get Documents directory")
            return nil
        }
        let outputURL = documentsURL.appendingPathComponent(fileName)
        do {
            try data.write(to: outputURL)
            print("\(debugTag) saveToFileManager OK: Wrote \(data.count) bytes to \(outputURL.path)")
            return outputURL
        } catch {
            print("\(debugTag) saveToFileManager FAILED: \(error.localizedDescription)")
            return nil
        }
    }

    private static func convertPDFDataToPPTX(pdfData: Data) -> Data? {
        print("\(debugTag) convertPDFDataToPPTX: pdfData size=\(pdfData.count) bytes")

        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("\(debugTag) convertPDFDataToPPTX FAILED: PDFDocument could not parse data (invalid PDF?)")
            return nil
        }

        let pageCount = pdfDocument.pageCount
        print("\(debugTag) convertPDFDataToPPTX: pageCount=\(pageCount)")

        guard pageCount > 0 else {
            print("\(debugTag) convertPDFDataToPPTX FAILED: PDF has no pages")
            return nil
        }

        var pageData: [(image: Data, bounds: CGRect)] = []
        let ptsToEmu: CGFloat = 12700
        let slideWidthEmu: Int = 9144000
        let slideHeightEmu: Int = 6858000
        let renderScale: CGFloat = 2.0

        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else {
                print("\(debugTag) convertPDFDataToPPTX: Warning - could not get page \(i)")
                continue
            }
            let bounds = page.bounds(for: .mediaBox)
            let maxDimension: CGFloat = 2880
            let scale = min(renderScale, maxDimension / max(bounds.width, bounds.height))
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)

            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            format.opaque = true
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(origin: .zero, size: size))
                context.cgContext.translateBy(x: 0, y: size.height)
                context.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            if let pngData = image.pngData() {
                pageData.append((pngData, bounds))
                print("\(debugTag) convertPDFDataToPPTX: Rendered page \(i + 1)/\(pageCount), image size=\(pngData.count) bytes")
            } else {
                print("\(debugTag) convertPDFDataToPPTX: Warning - could not get PNG data for page \(i + 1)")
            }
        }

        guard !pageData.isEmpty else {
            print("\(debugTag) convertPDFDataToPPTX FAILED: No images could be rendered")
            return nil
        }
        print("\(debugTag) convertPDFDataToPPTX: Rendered \(pageData.count) images, creating PPTX...")

        return createPPTX(pageData: pageData, ptsToEmu: ptsToEmu, slideWidthEmu: slideWidthEmu, slideHeightEmu: slideHeightEmu)
    }

    private static func createPPTX(pageData: [(image: Data, bounds: CGRect)], ptsToEmu: CGFloat, slideWidthEmu: Int, slideHeightEmu: Int) -> Data? {
        guard let tempDir = try? FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory,
            create: true
        ) else {
            print("\(debugTag) createPPTX FAILED: Cannot create temp directory")
            return nil
        }
        print("\(debugTag) createPPTX: tempDir=\(tempDir.path)")

        let pptDir = tempDir.appendingPathComponent("ppt", isDirectory: true)
        let slidesDir = pptDir.appendingPathComponent("slides", isDirectory: true)
        let mediaDir = pptDir.appendingPathComponent("media", isDirectory: true)
        let slideMastersDir = pptDir.appendingPathComponent("slideMasters", isDirectory: true)
        let slideLayoutsDir = pptDir.appendingPathComponent("slideLayouts", isDirectory: true)
        let themeDir = pptDir.appendingPathComponent("theme", isDirectory: true)
        let docPropsDir = tempDir.appendingPathComponent("docProps", isDirectory: true)
        let relsDir = tempDir.appendingPathComponent("_rels", isDirectory: true)
        let pptRelsDir = pptDir.appendingPathComponent("_rels", isDirectory: true)
        let slidesRelsDir = slidesDir.appendingPathComponent("_rels", isDirectory: true)
        let slideMastersRelsDir = slideMastersDir.appendingPathComponent("_rels", isDirectory: true)
        let slideLayoutsRelsDir = slideLayoutsDir.appendingPathComponent("_rels", isDirectory: true)

        try? FileManager.default.createDirectory(at: slidesDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: slideMastersDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: slideLayoutsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: themeDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: docPropsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: relsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: pptRelsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: slidesRelsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: slideMastersRelsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: slideLayoutsRelsDir, withIntermediateDirectories: true)

        let slideCount = pageData.count
        let contentTypes = createContentTypesXML(slideCount: slideCount)
        let rels = createPackageRelsXML()
        let presentationRels = createPresentationRelsXML(slideCount: slideCount)
        let presentation = createPresentationXML(slideCount: slideCount)
        let slideMaster = createSlideMasterXML()
        let slideMasterRels = createSlideMasterRelsXML()
        let slideLayout = createSlideLayoutXML()
        let slideLayoutRels = createSlideLayoutRelsXML()
        let theme = createThemeXML()
        let docPropsApp = createDocPropsAppXML()
        let docPropsCore = createDocPropsCoreXML()

        do {
            try contentTypes.write(to: tempDir.appendingPathComponent("[Content_Types].xml"))
            try rels.write(to: relsDir.appendingPathComponent(".rels"))
            try presentationRels.write(to: pptRelsDir.appendingPathComponent("presentation.xml.rels"))
            try presentation.write(to: pptDir.appendingPathComponent("presentation.xml"))
            try slideMaster.write(to: slideMastersDir.appendingPathComponent("slideMaster1.xml"))
            try slideMasterRels.write(to: slideMastersRelsDir.appendingPathComponent("slideMaster1.xml.rels"))
            try slideLayout.write(to: slideLayoutsDir.appendingPathComponent("slideLayout1.xml"))
            try slideLayoutRels.write(to: slideLayoutsRelsDir.appendingPathComponent("slideLayout1.xml.rels"))
            try theme.write(to: themeDir.appendingPathComponent("theme1.xml"))
            try docPropsApp.write(to: docPropsDir.appendingPathComponent("app.xml"))
            try docPropsCore.write(to: docPropsDir.appendingPathComponent("core.xml"))

            for (i, item) in pageData.enumerated() {
                try item.image.write(to: mediaDir.appendingPathComponent("image\(i + 1).png"))
                let slideXML = createSlideXML(imageIndex: i + 1, bounds: item.bounds, ptsToEmu: ptsToEmu, slideWidthEmu: slideWidthEmu, slideHeightEmu: slideHeightEmu)
                let slideRels = createSlideRelsXML(imageIndex: i + 1)
                try slideXML.write(to: slidesDir.appendingPathComponent("slide\(i + 1).xml"))
                try slideRels.write(to: slidesRelsDir.appendingPathComponent("slide\(i + 1).xml.rels"))
            }

            let outputURL = tempDir.appendingPathComponent("output.pptx")
            try? FileManager.default.removeItem(at: outputURL)
            try FileManager.default.zipItem(at: tempDir, to: outputURL, shouldKeepParent: false, compressionMethod: .deflate)

            let resultData = try Data(contentsOf: outputURL)
            print("\(debugTag) createPPTX OK: Created PPTX, size=\(resultData.count) bytes")
            try? FileManager.default.removeItem(at: tempDir)
            return resultData
        } catch {
            print("\(debugTag) createPPTX FAILED: \(error)")
            try? FileManager.default.removeItem(at: tempDir)
            return nil
        }
    }

    private static func createContentTypesXML(slideCount: Int) -> Data {
        var parts = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Default Extension="png" ContentType="image/png"/>
        <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
        <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
        <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
        <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
        <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
        <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
        """
        for i in 1...slideCount {
            parts += "\n<Override PartName=\"/ppt/slides/slide\(i).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\"/>"
        }
        parts += "\n</Types>"
        return Data(parts.utf8)
    }

    private static func createPackageRelsXML() -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
        <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
        </Relationships>
        """
        return Data(xml.utf8)
    }

    private static func createPresentationRelsXML(slideCount: Int) -> Data {
        var parts = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
        """
        for i in 1...slideCount {
            parts += "\n<Relationship Id=\"rId\(i + 2)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\" Target=\"slides/slide\(i).xml\"/>"
        }
        parts += "\n</Relationships>"
        return Data(parts.utf8)
    }

    private static func createPresentationXML(slideCount: Int) -> Data {
        var slideIds = ""
        for i in 1...slideCount {
            slideIds += "\n<p:sldId id=\"\(256 + i)\" r:id=\"rId\(i + 2)\"/>"
        }
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <p:sldSz cx="9144000" cy="6858000"/>
        <p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>
        <p:sldIdLst>\(slideIds)
        </p:sldIdLst>
        </p:presentation>
        """
        return Data(xml.utf8)
    }

    private static func createSlideXML(imageIndex: Int, bounds: CGRect, ptsToEmu: CGFloat, slideWidthEmu: Int, slideHeightEmu: Int) -> Data {
        let imgWidthEmu = Int(bounds.width * ptsToEmu)
        let imgHeightEmu = Int(bounds.height * ptsToEmu)
        let scaleX = CGFloat(slideWidthEmu) / CGFloat(imgWidthEmu)
        let scaleY = CGFloat(slideHeightEmu) / CGFloat(imgHeightEmu)
        let scale = min(scaleX, scaleY)
        let extCx = Int(CGFloat(imgWidthEmu) * scale)
        let extCy = Int(CGFloat(imgHeightEmu) * scale)
        let offX = (slideWidthEmu - extCx) / 2
        let offY = (slideHeightEmu - extCy) / 2

        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
        <p:cSld>
        <p:spTree>
        <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
        <p:grpSpPr/>
        <p:sp nvSpPr="1">
        <p:nvSpPr><p:cNvPr id="2" name="Picture 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr/></p:nvSpPr>
        <p:spPr/>
        <p:txBody><a:bodyPr/><a:lstStyle/><a:p/></p:txBody>
        </p:sp>
        <p:pic nvPicPr="1">
        <p:nvPicPr><p:cNvPr id="3" name="image\(imageIndex).png"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>
        <p:blipFill>
        <a:blip r:embed="rId2"/>
        <a:stretch><a:fillRect/></a:stretch>
        </p:blipFill>
        <p:spPr><a:xfrm><a:off x="\(offX)" y="\(offY)"/><a:ext cx="\(extCx)" cy="\(extCy)"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>
        </p:pic>
        </p:spTree>
        </p:cSld>
        <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
        </p:sld>
        """
        return Data(xml.utf8)
    }

    private static func createSlideRelsXML(imageIndex: Int) -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image\(imageIndex).png"/>
        </Relationships>
        """
        return Data(xml.utf8)
    }

    private static func createSlideMasterXML() -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sldMaster xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
        <p:cSld><p:bg><p:bgPr><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill><a:effectLst/></p:bgPr></p:bg></p:cSld>
        <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
        <p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>
        </p:sldMaster>
        """
        return Data(xml.utf8)
    }

    private static func createSlideMasterRelsXML() -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
        </Relationships>
        """
        return Data(xml.utf8)
    }

    private static func createSlideLayoutXML() -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sldLayout xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
        <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
        <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
        </p:sldLayout>
        """
        return Data(xml.utf8)
    }

    private static func createSlideLayoutRelsXML() -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
        </Relationships>
        """
        return Data(xml.utf8)
    }

    private static func createThemeXML() -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
        <a:themeElements>
        <a:clrScheme name="Office">
        <a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>
        <a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>
        <a:dk2><a:srgbClr val="1F497D"/></a:dk2>
        <a:lt2><a:srgbClr val="EEECE1"/></a:lt2>
        <a:accent1><a:srgbClr val="4F81BD"/></a:accent1>
        <a:accent2><a:srgbClr val="C0504D"/></a:accent2>
        <a:accent3><a:srgbClr val="9BBB59"/></a:accent3>
        <a:accent4><a:srgbClr val="8064A2"/></a:accent4>
        <a:accent5><a:srgbClr val="4BACC6"/></a:accent5>
        <a:accent6><a:srgbClr val="F79646"/></a:accent6>
        <a:hlink><a:srgbClr val="0000FF"/></a:hlink>
        <a:folHlink><a:srgbClr val="800080"/></a:folHlink>
        </a:clrScheme>
        <a:fontScheme name="Office">
        <a:majorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>
        <a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>
        </a:fontScheme>
        <a:fmtScheme name="Office">
        <a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst>
        <a:lnStyleLst><a:ln w="9525" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln></a:lnStyleLst>
        <a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst>
        <a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst>
        </a:fmtScheme>
        </a:themeElements>
        <a:objectDefaults/>
        <a:extraClrSchemeLst/>
        </a:theme>
        """
        return Data(xml.utf8)
    }

    private static func createDocPropsAppXML() -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
        <Application>PDF Helper</Application>
        <DocSecurity>0</DocSecurity>
        <ScaleCrop>false</ScaleCrop>
        <LinksUpToDate>false</LinksUpToDate>
        <SharedDoc>false</SharedDoc>
        <HyperlinksChanged>false</HyperlinksChanged>
        <AppVersion>1.0</AppVersion>
        </Properties>
        """
        return Data(xml.utf8)
    }

    private static func createDocPropsCoreXML() -> Data {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dateStr = formatter.string(from: Date())
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <dc:creator>PDF Helper</dc:creator>
        <cp:lastModifiedBy>PDF Helper</cp:lastModifiedBy>
        <dcterms:created xsi:type="dcterms:W3CDTF">\(dateStr)</dcterms:created>
        <dcterms:modified xsi:type="dcterms:W3CDTF">\(dateStr)</dcterms:modified>
        </cp:coreProperties>
        """
        return Data(xml.utf8)
    }
}
