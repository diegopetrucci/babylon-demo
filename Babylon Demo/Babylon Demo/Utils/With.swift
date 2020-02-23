protocol With {}

extension With {
    @discardableResult func with(_ block: (inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try block(&copy)
        return copy
    }
}
