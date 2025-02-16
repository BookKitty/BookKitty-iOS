import RxSwift

public protocol SimilarityCalculatable {
    associatedtype T
    /// 비교할 타입을 제너릭하게 정의
    static func calculateSimilarity(_ value1: T, _ value2: T) -> Double
}
