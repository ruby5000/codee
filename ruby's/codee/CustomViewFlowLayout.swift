import Foundation
import UIKit

class CustomViewFlowLayout: UICollectionViewFlowLayout {
    
    // Use delegate spacing instead of hardcoded value to prevent overlap
    private func getSpacing() -> CGFloat {
        guard let collectionView = self.collectionView,
              let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else {
            return 8.0 // Default spacing
        }
        return delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: 0) ?? 8.0
    }
    
    override init() {
        super.init()
        self.scrollDirection = .horizontal
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.scrollDirection = .horizontal
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        self.minimumLineSpacing = 0.0
        self.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 6)
        
        // Get spacing from delegate to ensure consistency and prevent overlap
        let spacing = getSpacing()
        
        // Get all attributes - super will call sizeForItemAt for each
        guard let attributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        
        // Sort attributes by index to ensure correct sequential positioning
        // This is critical for correct positioning during fast scrolling
        let sortedAttributes = attributes.sorted(by: { $0.indexPath.item < $1.indexPath.item })
        
        // Recalculate positions sequentially based on actual frame sizes
        // This ensures correct positioning even if cells are reused during fast scrolling
        var leftMargin = sectionInset.left
        
        sortedAttributes.forEach { layoutAttribute in
            // Get fresh size from delegate to ensure we're using correct sizes
            // This prevents using stale cached sizes during fast scrolling
            if let collectionView = self.collectionView,
               let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
                let correctSize = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: layoutAttribute.indexPath)
                if let size = correctSize {
                    layoutAttribute.frame.size = size
                }
            }
            
            // Calculate position sequentially to prevent overlap
            // For each item, calculate position based on all previous items
            var calculatedLeftMargin = sectionInset.left
            for i in 0..<layoutAttribute.indexPath.item {
                let previousIndexPath = IndexPath(item: i, section: layoutAttribute.indexPath.section)
                // Try to get size from delegate first, then fall back to super
                if let collectionView = self.collectionView,
                   let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
                   let previousSize = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: previousIndexPath) {
                    calculatedLeftMargin += previousSize.width + spacing
                } else if let previousAttributes = super.layoutAttributesForItem(at: previousIndexPath) {
                    calculatedLeftMargin += previousAttributes.frame.width + spacing
                }
            }
            
            // Use calculated position to prevent overlap
            layoutAttribute.frame.origin.x = calculatedLeftMargin
            leftMargin = calculatedLeftMargin + layoutAttribute.frame.width + spacing
        }
        
        return sortedAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // Invalidate layout when bounds change to ensure correct positioning
        if let oldBounds = collectionView?.bounds, !oldBounds.size.equalTo(newBounds.size) {
            return true
        }
        return false
    }
    
    override func invalidateLayout() {
        // Clear any cached layout information when invalidating
        super.invalidateLayout()
    }
    
    override func prepare() {
        super.prepare()
        // Ensure layout is recalculated with fresh data
        // This is called before layout calculations
        // Reset spacing and insets to ensure consistent layout
        self.minimumLineSpacing = 0.0
        self.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 6)
    }
    
    override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        // Invalidate if size changes to ensure correct positioning
        return preferredAttributes.size != originalAttributes.size
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }
        
        // Get spacing from delegate to ensure consistency
        let spacing = getSpacing()
        
        // Calculate position based on all previous items
        // Use sizes from super which already called sizeForItemAt
        var leftMargin = sectionInset.left
        for i in 0..<indexPath.item {
            let previousIndexPath = IndexPath(item: i, section: indexPath.section)
            if let previousAttributes = super.layoutAttributesForItem(at: previousIndexPath) {
                leftMargin += previousAttributes.frame.width + spacing
            }
        }
        
        attributes.frame.origin.x = leftMargin
        return attributes
    }
    
    override var collectionViewContentSize: CGSize {
        // Force recalculation of content size to ensure it's correct
        let size = super.collectionViewContentSize
        return size
    }
}
