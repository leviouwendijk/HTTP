import Foundation

public struct HTTPHeader: Sendable, Hashable, Equatable {
    public let name: String
    public let value: String

    public init(
        _ name: String,
        _ value: String
    ) {
        self.name = name
        self.value = value
    }
}

public enum HTTPHeaderDictionaryPreference: Sendable {
    case first
    case last
}

public struct HTTPHeaders: Sendable, Hashable, Equatable, Sequence {
    public typealias Element = (String, String)

    private var storage: [HTTPHeader] = []

    public init() {}

    public init(
        _ headers: HTTPHeaders
    ) {
        self.storage = headers.storage
    }

    public init(
        _ dict: [String: String]
    ) {
        self.storage = dict.map {
            HTTPHeader(
                $0.key,
                $0.value
            )
        }
    }

    public init(
        _ pairs: [(String, String)]
    ) {
        self.storage = pairs.map {
            HTTPHeader(
                $0.0,
                $0.1
            )
        }
    }

    public var count: Int {
        storage.count
    }

    public var isEmpty: Bool {
        storage.isEmpty
    }

    public var keys: [String] {
        storage.map(\.name)
    }

    public var values: [String] {
        storage.map(\.value)
    }

    public var pairs: [(String, String)] {
        storage.map {
            ($0.name, $0.value)
        }
    }

    public func makeIterator() -> AnyIterator<(String, String)> {
        var iterator = storage.makeIterator()

        return AnyIterator {
            guard let header = iterator.next() else {
                return nil
            }

            return (
                header.name,
                header.value
            )
        }
    }

    public mutating func append(
        _ name: String,
        _ value: String
    ) {
        storage.append(
            HTTPHeader(
                name,
                value
            )
        )
    }

    public mutating func append(
        contentsOf headers: HTTPHeaders
    ) {
        storage.append(
            contentsOf: headers.storage
        )
    }

    public mutating func set(
        _ name: String,
        _ value: String
    ) {
        remove(name)
        append(
            name,
            value
        )
    }

    public mutating func remove(
        _ name: String
    ) {
        let lowercasedName = name.lowercased()

        storage.removeAll {
            $0.name.lowercased() == lowercasedName
        }
    }

    public func get(
        _ name: String
    ) -> String? {
        let lowercasedName = name.lowercased()

        return storage.first {
            $0.name.lowercased() == lowercasedName
        }?.value
    }

    public func values(
        for name: String
    ) -> [String] {
        let lowercasedName = name.lowercased()

        return storage
            .filter {
                $0.name.lowercased() == lowercasedName
            }
            .map(\.value)
    }

    public func contains(
        _ name: String
    ) -> Bool {
        get(name) != nil
    }

    public subscript(
        _ name: String
    ) -> String? {
        get {
            get(name)
        }
        set {
            if let newValue {
                set(
                    name,
                    newValue
                )
            } else {
                remove(name)
            }
        }
    }

    public func toDictionary(
        prefer preference: HTTPHeaderDictionaryPreference = .first
    ) -> [String: String] {
        var dict: [String: String] = [:]

        switch preference {
        case .first:
            for header in storage where dict[header.name] == nil {
                dict[header.name] = header.value
            }

        case .last:
            for header in storage {
                dict[header.name] = header.value
            }
        }

        return dict
    }

    public func forEach(
        _ body: (String, String) -> Void
    ) {
        for header in storage {
            body(
                header.name,
                header.value
            )
        }
    }

    public func lines() -> [String] {
        storage.map {
            "\($0.name): \($0.value)"
        }
    }
}

// public struct HTTPHeaders: Sendable {
//     private var storage: [(String, String)] = []
    
//     public init() {}
    
//     public init(_ dict: [String: String]) {
//         self.storage = dict.map { ($0.key, $0.value) }
//     }
    
//     /// Set or override a header (case-insensitive key)
//     public mutating func set(_ name: String, _ value: String) {
//         let lower = name.lowercased()
//         storage.removeAll { $0.0.lowercased() == lower }
//         storage.append((name, value))
//     }
    
//     /// Get a header value (case-insensitive)
//     public func get(_ name: String) -> String? {
//         let lower = name.lowercased()
//         return storage.first { $0.0.lowercased() == lower }?.1
//     }
    
//     /// Get all headers as dictionary
//     public func toDictionary() -> [String: String] {
//         var dict: [String: String] = [:]
//         for (key, value) in storage {
//             dict[key] = value
//         }
//         return dict
//     }
    
//     /// Iterate over headers
//     public func forEach(_ body: (String, String) -> Void) {
//         for (key, value) in storage {
//             body(key, value)
//         }
//     }
    
//     /// Get all header lines for serialization
//     public func lines() -> [String] {
//         storage.map { "\($0.0): \($0.1)" }
//     }
// }
