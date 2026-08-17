public struct HTTPQuery:
    Sendable,
    Equatable,
    Hashable,
    CustomStringConvertible
{
    public let raw: String

    public init(
        raw: String
    ) {
        self.raw = raw
    }

    public var description: String {
        raw
    }
}
