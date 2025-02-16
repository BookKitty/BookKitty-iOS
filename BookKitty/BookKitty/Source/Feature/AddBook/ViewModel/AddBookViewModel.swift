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
        let error: Observable<AlertPresentableError> // 에러 처리
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    // MARK: - Private

    let navigateBackRelay = PublishRelay<Void>()

    private let errorRelay = PublishRelay<AlertPresentableError>()
    private let bookRepository: BookRepository
    private let bookMatchKit: BookMatchable

    // MARK: - Lifecycle

    init(bookRepository: BookRepository, bookMatchKit: BookMatchable) {
        self.bookRepository = bookRepository
        self.bookMatchKit = bookMatchKit
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        Observable.merge(
            input.leftBarButtonTapTrigger,
            input.cameraPermissionCancelButtonTapTrigger
        )
        .bind(to: navigateBackRelay)
        .disposed(by: disposeBag)

        input.capturedImage
            .flatMapLatest { [weak self] image -> Observable<Book> in
                guard self != nil else {
                    return .empty()
                }

                return Observable.create { observer in
                    let disposable = self?.bookMatchKit.matchBook(image)
                        .subscribe(
                            onSuccess: { book in
                                let finalBook = Book(
                                    isbn: book.isbn,
                                    title: book.title,
                                    author: book.author,
                                    publisher: book.publisher,
                                    thumbnailUrl: URL(string: book.image),
                                    isOwned: true,
                                    description: book.description,
                                    price: book.discount ?? "",
                                    pubDate: book.pubdate ?? ""
                                )

                                observer.onNext(finalBook)
                                observer.onCompleted()

                            },
                            onFailure: { error in
                                switch error {
                                case BookMatchError.networkError:
                                    observer.onError(NetworkError.networkUnstable)
                                case BookMatchError.noMatchFound:
                                    observer.onError(AddBookError.bookNotFound)
                                default:
                                    BookKittyLogger.error("Error: \(error.localizedDescription)")
                                    observer.onError(AddBookError.unknown)
                                }
                            }
                        )

                    return Disposables.create {
                        disposable?.dispose()
                    }
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, book in
                let isSaved = owner.bookRepository.saveBook(book: book)
                if isSaved {
                    owner.navigateBackRelay.accept(())
                } else {
                    owner.errorRelay.accept(AddBookError.duplicatedBook)
                }
            }, onError: { owner, error in
                guard let error = error as? AlertPresentableError else {
                    BookKittyLogger.debug("error is not AlertPresentableError")
                    return
                }
                owner.errorRelay.accept(error)
            })
            .disposed(by: disposeBag)

        return Output(
            error: errorRelay.asObservable()
        )
    }
}
