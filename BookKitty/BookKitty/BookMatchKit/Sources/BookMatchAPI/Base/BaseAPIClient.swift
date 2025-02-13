import RxSwift

public class BaseAPIClient {
    // MARK: - Properties

    let configuration: APIConfiguration
    let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    public init(configuration: APIConfiguration) {
        self.configuration = configuration
    }
}
