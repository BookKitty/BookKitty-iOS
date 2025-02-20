import Foundation
import OSLog

public enum BookMatchLogger {
    // MARK: - Static Properties

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.BookshelfML.BookKitty",
        category: "BookMatchKit"
    )

    // MARK: - Static Functions

    public static func matchingStarted() {
        logger.info("📚 도서매칭 시작")
    }

    public static func detectorInitializationFailed() {
        logger.error("⚠️ CIDetector 초기화 실패")
    }

    public static func textSlopeDetectionFailed() {
        logger.error("⚠️ 텍스트 기울기 감지 실패")
    }

    public static func textsExtracted(_ words: [String]) {
        logger.info("📝 최종 OCR 텍스트 추출 완료: \(words.joined(separator: ", "))")
    }

    public static func textExtracted(_ words: [String]) {
        logger.info("🔍 OCR로 추출된 텍스트: \(words.joined(separator: ", "))")
    }

    public static func searchResultsReceived(count: Int) {
        logger.info("🔍 추출된 텍스트로  \(count)개의 책 검색됨.")
    }

    public static func similarityCalculated(bookTitle: String, score: Double) {
        logger.info("📊  '\(bookTitle)'에 대한 이미지 유사도: \(score)")
    }

    public static func matchingCompleted(success: Bool, bookTitle: String?) {
        if success {
            logger.info("✅ 도서 매칭 완료: \(bookTitle ?? "Unknown")")
        } else {
            logger.error("❌ 도서 매칭 실패")
        }
    }

    // MARK: - Book Recommendation Logging

    public static func recommendationStarted(question: String?) {
        if let question {
            logger.info("🎯 도서 추천 시작 - 질문: \(question)")
        } else {
            logger.info("🎯 보유 도서에 대한 도서 추천 시작")
        }
    }

    public static func gptResponseReceived(result: String) {
        logger.info("🤖 GPT로부터 도서추천반환됨: \(result)")
    }

    public static func bookConversionStarted(title: String, author: String) {
        logger.info("🔄 도서 매칭 중: \(title) : \(author)")
    }

    public static func retryingBookMatch(attempt: Int, currentBook: BookItem) {
        logger
            .info(
                "🔁 GPT에게 도서 재요청 및 재시도: \(attempt)/3 - 현재 도서 = \(currentBook.title) : \(currentBook.author)"
            )
    }

    public static func descriptionStarted() {
        logger.info("📝 도서 추천이유 작성 중...")
    }

    public static func recommendationCompleted(ownedCount: Int, newCount: Int) {
        logger.info("✨ 도서추천 완료 - 보유도서 추천 \(ownedCount)개, 미보유도서 추천 \(newCount)개")
    }

    // MARK: - Error Logging

    public static func error(_ error: Error, context: String) {
        if let error = error as? BookMatchError {
            logger.error("❌ Error in \(context): \(error.description)")
        } else {
            logger.error("❌ Error in \(context): \(error.localizedDescription)")
        }
    }
}
