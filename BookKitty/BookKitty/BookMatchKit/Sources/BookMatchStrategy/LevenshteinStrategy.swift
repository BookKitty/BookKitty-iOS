import BookMatchCore
import RxSwift

public struct LevenshteinStrategy: SimilarityCalculatable {
    // MARK: - Nested Types

    // MARK: - Public

    public typealias T = String

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Functions

    public func calculateSimilarity(_ str1: String, _ str2: String) -> Single<Double> {
        Single.create { single in
            let sourceChars = Array(str1)
            let targetChars = Array(str2)
            let sourceLength = sourceChars.count
            let targetLength = targetChars.count

            // 빈 문자열 처리
            if sourceLength == 0 {
                single(.success(Double(targetLength)))
                return Disposables.create()
            }
            if targetLength == 0 {
                single(.success(Double(sourceLength)))
                return Disposables.create()
            }

            // 거리 계산을 위한 2차원 배열
            var matrix = Array(
                repeating: Array(repeating: 0, count: targetLength + 1),
                count: sourceLength + 1
            )

            // 첫 행과 열 초기화
            for i in 0 ... sourceLength {
                matrix[i][0] = i
            }
            for j in 0 ... targetLength {
                matrix[0][j] = j
            }

            // 행렬 채우기
            for i in 1 ... sourceLength {
                for j in 1 ... targetLength {
                    let substitutionCost = sourceChars[i - 1] == targetChars[j - 1] ? 0 : 1
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1, // 삭제
                        matrix[i][j - 1] + 1, // 삽입
                        matrix[i - 1][j - 1] + substitutionCost // 교체
                    )
                }
            }

            // 거리를 유사도 점수(0~1)로 변환
            let distance = Double(matrix[sourceLength][targetLength])
            let maxLength = Double(max(sourceLength, targetLength))
            let similarity = 1 - (distance / maxLength)

            single(.success(similarity))
            return Disposables.create()
        }
    }
}
