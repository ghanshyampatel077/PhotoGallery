import SwiftUI
import UIKit

// MARK: - Placeholder Image
enum PhotoPlaceholder {
    static var image: UIImage {
        UIImage(named: AppConstants.Assets.photoPlaceholder)
            ?? UIImage(systemName: AppConstants.SystemImage.photo)
            ?? UIImage()
    }
}
