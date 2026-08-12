import Foundation

public extension HTTPHeaders {
    struct Vary: Sendable, Hashable {
        private var values: [String]

        fileprivate init(
            _ headerValues: [String]
        ) {
            let values = headerValues.flatMap { value in
                value
                    .split(
                        separator: ","
                    )
                    .map {
                        String($0).trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
            }

            if values.contains("*") {
                self.values = [
                    "*"
                ]

                return
            }

            var seen: Set<String> = []
            var unique: [String] = []

            for value in values {
                guard !value.isEmpty else {
                    continue
                }

                guard seen.insert(
                    value.lowercased()
                ).inserted else {
                    continue
                }

                unique.append(
                    value
                )
            }

            self.values = unique
        }

        public mutating func insert(
            _ value: String
        ) {
            let value = value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !value.isEmpty else {
                return
            }

            if value == "*" {
                values = [
                    "*"
                ]

                return
            }

            guard !values.contains("*") else {
                return
            }

            guard !values.contains(
                where: {
                    $0.caseInsensitiveCompare(
                        value
                    ) == .orderedSame
                }
            ) else {
                return
            }

            values.append(
                value
            )
        }

        fileprivate var headerValue: String? {
            guard !values.isEmpty else {
                return nil
            }

            return values.joined(
                separator: ", "
            )
        }
    }

    var vary: Vary {
        get {
            Vary(
                values(
                    for: "Vary"
                )
            )
        }
        set {
            if let value = newValue.headerValue {
                set(
                    "Vary",
                    value
                )
            } else {
                remove(
                    "Vary"
                )
            }
        }
    }
}
