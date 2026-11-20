public extension HTTPHeaders {
    var accept: String? {
        get {
            self[
                "Accept"
            ]
        }
        set {
            self[
                "Accept"
            ] = newValue
        }
    }

    var allow: [String]? {
        get {
            guard contains(
                "Allow"
            ) else {
                return nil
            }

            return values(
                for: "Allow"
            )
            .flatMap { value in
                value
                    .split(
                        separator: ","
                    )
                    .map { component in
                        String(component).trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
            }
            .filter {
                !$0.isEmpty
            }
        }
        set {
            guard let newValue else {
                remove(
                    "Allow"
                )
                return
            }

            set(
                "Allow",
                newValue.joined(
                    separator: ", "
                )
            )
        }
    }

    var allowedMethods: [HTTPMethod]? {
        allow?.compactMap { value in
            HTTPMethod(
                caseInsensitive: value
            )
        }
    }

    var location: String? {
        get {
            self[
                "Location"
            ]
        }
        set {
            self[
                "Location"
            ] = newValue
        }
    }

    var contentLocation: String? {
        get {
            self[
                "Content-Location"
            ]
        }
        set {
            self[
                "Content-Location"
            ] = newValue
        }
    }
}
