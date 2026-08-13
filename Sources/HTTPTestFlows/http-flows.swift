import TestFlows

enum HTTPFlowSuite: TestFlowRegistry {
    static let title = "HTTP Test Flows"

    static let flows: [TestFlow] = [
        httpProtocolBaselineRegressionFlow,
        httpRequestLineGrammarRegressionFlow,
        httpRequestTargetGrammarRegressionFlow,
        httpHeaderFieldGrammarRegressionFlow,
        httpStatusLineGrammarRegressionFlow,
        httpRequestModelParsingRegressionFlow,
        httpResponseModelParsingRegressionFlow,
        httpTypedTransportRegressionFlow,
        httpEndpointContractRegressionFlow,
        httpRequestParserRegressionFlow,
        httpResponseParserRegressionFlow,
        httpResponseBuilderRegressionFlow,
        httpHeaderAccessRegressionFlow,
        httpResponseConstructorRegressionFlow,
        httpClientIPRegressionFlow
    ]
}
