/// API 통신에 필요한 설정 정보를 관리하는 구조체입니다.
/// 네이버 책 검색 API와 OpenAI API에 대한 인증 정보와 기본 URL을 포함합니다./**
/// 기본 설정값으로 APIConfiguration 인스턴스를 생성합니다.
///
/// - Parameters:
///  - naverClientId: 네이버 개발자 센터에서 발급받은 클라이언트 ID
///  - naverClientSecret: 네이버 개발자 센터에서 발급받은 클라이언트 시크릿
///  - openAIApiKey: OpenAI API 키
public struct APIConfiguration {
    // MARK: - Properties

    public let naverClientId: String
    public let naverClientSecret: String
    public let openAIApiKey: String

    // MARK: - Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String,
        openAIApiKey: String
    ) {
        self.naverClientId = naverClientId
        self.naverClientSecret = naverClientSecret
        self.openAIApiKey = openAIApiKey
    }
}
