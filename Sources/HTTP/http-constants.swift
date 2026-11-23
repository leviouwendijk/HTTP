import Foundation

public enum HTTPConstants {
    public static let crlfCrLf = "\r\n\r\n"
    public static let crlf = "\r\n"
    public static let headerSeparator = ":"
    public static let httpVersion = "HTTP/1.1"
    public static let httpVersion10 = "HTTP/1.0"
    public static let hostHeader = "Host"
    public static let connectionHeader = "Connection"
    
    public static let contentLengthHeader = "Content-Length"
    public static let transferEncodingHeader = "Transfer-Encoding"
    public static let contentTypeHeader = "Content-Type"
    public static let authorizationHeader = "Authorization"
    
    public static let defaultContentType = "text/plain; charset=utf-8"
}
