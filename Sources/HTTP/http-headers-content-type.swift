public extension HTTPHeaders {
    var contentType: String? {
        get {
            self[
                "Content-Type"
            ]
        }
        set {
            self[
                "Content-Type"
            ] = newValue
        }
    }
}
