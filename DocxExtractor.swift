//
//  DocxExtractor.swift
//  PDF Helper
//
//  Extracts text from .docx (ZIP + word/document.xml) using native APIs.
//

import Foundation
import Compression

enum DocxExtractor {

    /// Extract plain text from .docx data (paragraphs separated by newlines).
    static func extractText(from data: Data) -> String? {
        guard let xmlData = extractWordDocumentXML(from: data) else { return nil }
        return parseTextFromWordXML(xmlData)
    }

    /// From docx (ZIP), get the decompressed content of word/document.xml.
    private static func extractWordDocumentXML(from zipData: Data) -> Data? {
        let bytes = [UInt8](zipData)
        let targetPath = "word/document.xml"
        var offset = 0
        while offset + 30 <= bytes.count {
            let sig = UInt32(bytes[offset]) | (UInt32(bytes[offset + 1]) << 8) | (UInt32(bytes[offset + 2]) << 16) | (UInt32(bytes[offset + 3]) << 24)
            guard sig == 0x04034b50 else {
                offset += 1
                continue
            }
            let compMethod = UInt16(bytes[offset + 8]) | (UInt16(bytes[offset + 9]) << 8)
            let nameLen = Int(UInt16(bytes[offset + 26]) | (UInt16(bytes[offset + 27]) << 8))
            let extraLen = Int(UInt16(bytes[offset + 28]) | (UInt16(bytes[offset + 29]) << 8))
            let headerEnd = offset + 30 + nameLen + extraLen
            guard headerEnd <= bytes.count, nameLen > 0 else {
                offset += 1
                continue
            }
            let nameStart = offset + 30
            let nameData = Data(bytes[nameStart ..< nameStart + nameLen])
            guard let name = String(data: nameData, encoding: .utf8), name == targetPath || name.hasSuffix("/" + targetPath) else {
                let compressedSize = UInt32(bytes[offset + 18]) | (UInt32(bytes[offset + 19]) << 8)
                let uncompressedSize = UInt32(bytes[offset + 22]) | (UInt32(bytes[offset + 23]) << 8)
                offset = headerEnd + Int(compressedSize)
                continue
            }
            let compressedSize = Int(UInt32(bytes[offset + 18]) | (UInt32(bytes[offset + 19]) << 8))
            let compressedStart = headerEnd
            let compressedEnd = compressedStart + compressedSize
            guard compressedEnd <= bytes.count else { return nil }
            let compressed = Data(bytes[compressedStart ..< compressedEnd])
            if compMethod == 0 {
                return compressed
            }
            if compMethod == 8 {
                return decompressDeflate(compressed)
            }
            return nil
        }
        return nil
    }

    /// Decompress raw deflate (ZIP) by wrapping as zlib and using Compression framework.
    private static func decompressDeflate(_ rawDeflate: Data) -> Data? {
        let zlibHeader = Data([0x78, 0x9c])
        let adlerPlaceholder = Data([0, 0, 0, 0])
        let zlibData = zlibHeader + rawDeflate + adlerPlaceholder
        let destSize = 16 * 1024 * 1024
        let destBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destSize)
        defer { destBuffer.deallocate() }
        let decoded = zlibData.withUnsafeBytes { srcPtr in
            guard let srcBase = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            return compression_decode_buffer(destBuffer, destSize, srcBase, zlibData.count, nil, COMPRESSION_ZLIB)
        }
        guard decoded > 0, decoded < destSize else { return nil }
        return Data(bytes: destBuffer, count: decoded)
    }

    /// Parse word/document.xml: split by paragraphs (<w:p>) and extract text from <w:t>.
    private static func parseTextFromWordXML(_ xmlData: Data) -> String? {
        guard let xml = String(data: xmlData, encoding: .utf8) else { return nil }
        let pattern = "<w:t[^>]*>([^<]*)</w:t>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        func decode(_ s: String) -> String {
            s.replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&apos;", with: "'")
        }
        let normalized = xml.replacingOccurrences(of: "<w:p>", with: "<w:p ")
        let paragraphChunks = normalized.components(separatedBy: "<w:p ")
        var paragraphs: [String] = []
        for chunk in paragraphChunks {
            let matches = regex.matches(in: chunk, range: NSRange(chunk.startIndex..., in: chunk))
            let texts = matches.compactMap { match -> String? in
                guard match.numberOfRanges > 1, let r = Range(match.range(at: 1), in: chunk) else { return nil }
                return decode(String(chunk[r]))
            }
            let para = texts.joined().trimmingCharacters(in: .whitespacesAndNewlines)
            if !para.isEmpty { paragraphs.append(para) }
        }
        if !paragraphs.isEmpty { return paragraphs.joined(separator: "\n\n") }
        if paragraphChunks.count == 1, let first = paragraphChunks.first {
            let matches = regex.matches(in: first, range: NSRange(first.startIndex..., in: first))
            let texts = matches.compactMap { match -> String? in
                guard match.numberOfRanges > 1, let r = Range(match.range(at: 1), in: first) else { return nil }
                return decode(String(first[r]))
            }
            if !texts.isEmpty { return texts.joined(separator: " ") }
        }
        let allMatches = regex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
        let texts = allMatches.compactMap { match -> String? in
            guard match.numberOfRanges > 1, let r = Range(match.range(at: 1), in: xml) else { return nil }
            return decode(String(xml[r]))
        }
        guard !texts.isEmpty else { return nil }
        return texts.joined(separator: " ")
    }
}
