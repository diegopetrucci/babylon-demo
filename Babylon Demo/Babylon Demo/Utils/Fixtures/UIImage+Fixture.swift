import class UIKit.UIImage

#if DEBUG
extension UIImage {
    static func fixture() -> UIImage {
        UIImage(named: "thumbnail_fixture")!
    }
}
#endif
