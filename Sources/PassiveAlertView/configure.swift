/// A value configuration function to encapsulate all configuration code.
@discardableResult
func configure<T>(
    _ value: T,
    using closure: (inout T) throws -> Void
) rethrows -> T {
    var value = value
    try closure(&value)
    return value
}
