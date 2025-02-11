public struct BookMatchConfig: Sendable {
    // MARK: Lifecycle

    public init(
        titleSimilarityThreshold: Double = 0.4,
        authorSimilarityThreshold: Double = 0.8,
        titleWeight: Double = 0.8,
        authorWeight: Double = 0.2,
        maxRetries: Int = 3
    ) {
        self.titleSimilarityThreshold = titleSimilarityThreshold
        self.authorSimilarityThreshold = authorSimilarityThreshold
        self.titleWeight = titleWeight
        self.authorWeight = authorWeight

        self.maxRetries = maxRetries
    }

    // MARK: Public

    public let titleSimilarityThreshold: Double
    public let authorSimilarityThreshold: Double

    public let titleWeight: Double
    public let authorWeight: Double

    public let maxRetries: Int
}
