// 타입이 동시성 환경에서 안전하게 전달될 수 있음을 나타내는 프로토콜인 Sendable을 채택해야 해결이 가능합니다.
//  Static property 'default' is not concurrency-safe because non-'Sendable' type 'APIConfiguration'
//  may have shared mutable state

public struct BookMatchConfiguration: Sendable {
    // MARK: - Static Properties

    // MARK: - Public

    /// 예약어와 이름이 충돌하므로, 백틱을 통해 변수명임을 명시합니다.
    public static let `default` = BookMatchConfiguration(
        titleSimilarityThreshold: 0.4,
        authorSimilarityThreshold: 0.8,
        maxRetries: 3
    )

    // MARK: - Properties

    public let titleSimilarityThreshold: Double
    public let authorSimilarityThreshold: Double
    public let maxRetries: Int

    // MARK: - Lifecycle

    public init(
        titleSimilarityThreshold: Double = 0.4,
        authorSimilarityThreshold: Double = 0.8,
        maxRetries: Int = 3
    ) {
        self.titleSimilarityThreshold = titleSimilarityThreshold
        self.authorSimilarityThreshold = authorSimilarityThreshold
        self.maxRetries = maxRetries
    }
}
