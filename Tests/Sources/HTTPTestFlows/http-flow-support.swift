internal let httpCRLF = "\r\n"

func httpRawMessage(
    headLines: [String],
    body: String = ""
) -> String {
    headLines.joined(
        separator: httpCRLF
    ) + httpCRLF + httpCRLF + body
}

struct HTTPParserRegressionPayload: Decodable, Equatable {
    var name: String
    var count: Int
}
