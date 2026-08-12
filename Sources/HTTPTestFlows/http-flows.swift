import TestFlows

enum HTTPFlowSuite: TestFlowRegistry {
    static let title = "HTTP Test Flows"

    static let flows: [TestFlow] = [
        httpProtocolBaselineRegressionFlow,
        httpTypedTransportRegressionFlow,
        httpRequestParserRegressionFlow,
        httpResponseParserRegressionFlow,
        httpResponseBuilderRegressionFlow,
        httpHeaderAccessRegressionFlow,
        httpResponseConstructorRegressionFlow,
        httpClientIPRegressionFlow
    ]
}
