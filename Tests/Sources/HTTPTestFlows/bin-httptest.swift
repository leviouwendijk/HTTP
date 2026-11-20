import TestFlows

@main
enum HTTPTestFlowMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: HTTPFlowSuite.self,
            arguments: CommandLine.arguments
        )
    }
}
