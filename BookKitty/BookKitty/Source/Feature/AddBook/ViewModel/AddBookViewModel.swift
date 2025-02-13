import BookMatchCore
import BookMatchKit
import Foundation
import RxCocoa
import RxSwift
import UIKit
import Vision

final class AddBookViewModel: ViewModelType {
    // MARK: - Nested Types

    struct Input {
        let leftBarButtonTapTrigger: Observable<Void>

        let cameraPermissionCancelButtonTapTrigger: Observable<Void>

        let capturedImage: Observable<UIImage>
    }

    struct Output {
        let error: Observable<Error> // 에러 처리
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    // MARK: - Private

    let navigateBackRelay = PublishRelay<Void>()

    private let errorRelay = PublishRelay<Error>()

    private let bookRepository: BookRepository

    // MARK: - Lifecycle

    init(bookRepository: BookRepository) {
        self.bookRepository = bookRepository
    }

    // MARK: - Functions

    @MainActor
    func transform(_ input: Input) -> Output {
        Observable.merge(
            input.leftBarButtonTapTrigger,
            input.cameraPermissionCancelButtonTapTrigger
        )
        .bind(to: navigateBackRelay)
        .disposed(by: disposeBag)

        input.capturedImage
            .flatMapLatest { [weak self] image -> Observable<Book> in
                guard let self else {
                    return .empty()
                }

                let bookMatchKit = BookMatchKit(
                    naverClientId: Environment().naverClientID,
                    naverClientSecret: Environment().naverClientSecret
                )

                return bookMatchKit.matchBook(image: image)
                    .map { bookItem in
                        guard let bookItem else {
                            throw BookMatchError.noMatchFound
                        }
                        return Book(
                            isbn: bookItem.isbn,
                            title: bookItem.title,
                            author: bookItem.author,
                            publisher: bookItem.publisher,
                            thumbnailUrl: URL(string: bookItem.image),
                            description: bookItem.description,
                            price: bookItem.discount ?? "",
                            pubDate: bookItem.pubdate ?? ""
                        )
                    }
                    .asObservable()
                    .catch { error in
                        self.errorRelay.accept(error)
                        self.navigateBackRelay.accept(())
                        return .empty()
                    }
            }
            .subscribe(onNext: { [weak self] book in
                _ = self?.bookRepository.saveBook(book: book)
                self?.navigateBackRelay.accept(())
            })
            .disposed(by: disposeBag)

        return Output(
            error: errorRelay.asObservable()
        )
    }
}
