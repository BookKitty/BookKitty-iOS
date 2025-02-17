public struct ServiceConfiguration: Sendable {
    // MARK: - Static Properties

    public static let `default` = ServiceConfiguration(
        naverClientId: "",
        naverClientSecret: "",
        openAIApiKey: "",
        similarityThreshold: [0.4, 0.8],
        maxRetries: 3,
        titleWeight: 0.8
    )

    // MARK: - Properties

    let naverClientId: String
    let naverClientSecret: String
    let openAIApiKey: String
    let similarityThreshold: [Double]
    let maxRetries: Int
    let titleWeight: Double

    // MARK: - Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String,
        openAIApiKey: String,
        similarityThreshold: [Double] = [0.4, 0.8],
        maxRetries: Int = 3,
        titleWeight: Double = 0.8
    ) {
        self.naverClientId = naverClientId
        self.naverClientSecret = naverClientSecret
        self.openAIApiKey = openAIApiKey
        self.similarityThreshold = similarityThreshold
        self.maxRetries = maxRetries
        self.titleWeight = titleWeight
    }
}
