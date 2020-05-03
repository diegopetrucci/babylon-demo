import struct UIKit.CGSize

#if DEBUG
extension CGSize {
    static func fixture() -> CGSize {
        .init(width: 150, height: 150)
    }
}
#endif
