public extension HTTPHeaders {
    var authorization: String? {
        get {
            self[
                "Authorization"
            ]
        }
        set {
            self[
                "Authorization"
            ] = newValue
        }
    }

    var wwwAuthenticate: String? {
        get {
            self[
                "WWW-Authenticate"
            ]
        }
        set {
            self[
                "WWW-Authenticate"
            ] = newValue
        }
    }
}
