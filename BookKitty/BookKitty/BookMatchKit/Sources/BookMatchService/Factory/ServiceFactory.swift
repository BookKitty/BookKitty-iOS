import BookMatchAPI
import BookMatchCore
import BookMatchStrategy
import Foundation
import RxSwift

public final class ServiceFactory {
    // MARK: - Static Properties

    @MainActor public static let shared = ServiceFactory()

    // MARK: - Properties

    private let config: ServiceConfiguration

    private let disposeBag = DisposeBag()

    private lazy var apiConfiguration = APIConfiguration(
        naverClientId: config.naverClientId,
        naverClientSecret: config.naverClientSecret,
        openAIApiKey: config.openAIApiKey
    )

    private lazy var naverAPI = NaverAPI(configuration: apiConfiguration)

    private lazy var openAIAPI = OpenAIAPI(configuration: apiConfiguration)

    private lazy var imageDownloadAPI = ImageDownloadAPI(configuration: apiConfiguration)

    // MARK: - Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String,
        openAIApiKey: String,
        similarityThreshold: [Double] = [0.4, 0.8],
        maxRetries: Int = 3,
        titleWeight: Double = 0.8
    ) {
        config = ServiceConfiguration(
            naverClientId: naverClientId,
            naverClientSecret: naverClientSecret,
            openAIApiKey: openAIApiKey,
            similarityThreshold: similarityThreshold,
            maxRetries: maxRetries,
            titleWeight: titleWeight
        )
    }

    private init(config: ServiceConfiguration = .default) {
        self.config = config
    }

    // MARK: - Functions

    /// 책 검색 서비스 인스턴스를 생성합니다.
    public func makeBookSearchService() -> BookSearchService {
        BookSearchService(naverAPI: naverAPI)
    }

    /// 이미지 처리 서비스 인스턴스를 생성합니다.
    public func makeImageProcessService() -> ImageProcessService {
        ImageProcessService()
    }

    /// 텍스트 추출 서비스 인스턴스를 생성합니다.
    public func makeTextExtractionService() -> TextExtractionService {
        TextExtractionService()
    }

    /// 도서 검증 서비스 인스턴스를 생성합니다.
    public func makeBookValidationService() -> BookValidationService {
        BookValidationService(
            similiarityThreshold: config.similarityThreshold,
            maxRetries: config.maxRetries,
            titleWeight: config.titleWeight,
            searchService: makeBookSearchService()
        )
    }

    /// OpenAI API 인스턴스를 생성합니다.
    public func makeOpenAIAPI() -> OpenAIAPI {
        openAIAPI
    }

    /// 이미지 다운로드 API 인스턴스를 생성합니다.
    public func makeImageDownloadAPI() -> ImageDownloadAPI {
        imageDownloadAPI
    }
}
