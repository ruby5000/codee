import Foundation
import UIKit

class CarouselCollectionView: UICollectionView {
    
    override func awakeFromNib() {
    super.awakeFromNib()
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.backgroundColor = .clear
        self.decelerationRate = .fast
        
        let carouselFlowLayout = CarouselAnimatedFlowLayout()
        carouselFlowLayout.cellOffset = 12.0
        carouselFlowLayout.minLineSpacing = 0
        carouselFlowLayout.zoomLevel = 0.85
        self.collectionViewLayout = carouselFlowLayout
    }
}
