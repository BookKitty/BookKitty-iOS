import BookMatchCore
import BookOCRKit
import Foundation
import LogKit
import RxCocoa
import RxSwift
import UIKit
import Vision

final class AddBookViewModel: ViewModelType {
    // MARK: - Nested Types

    struct Input {
        let cameraPermissionCancelButtonTapTrigger: Observable<Void>
        let leftBarButtonTapTrigger: Observable<Void>
        let addBookByTextButtonTapTrigger: Observable<Void>
        let confirmButtonTapTrigger: Observable<Book>
        let capturedImage: Observable<UIImage>
    }

    struct Output {
        let bookMatchSuccess: PublishRelay<Book>
        let error: PublishRelay<AlertPresentableError> // 에러 처리
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    // MARK: - Private

    let navigateBackRelay = PublishRelay<Void>()
    let navigateToAddBookByText = PublishRelay<Void>()

    private let errorRelay = PublishRelay<AlertPresentableError>()
    private let bookMatchSuccessRelay = PublishRelay<Book>()

    private let bookRepository: BookRepository
    private let bookOCRKit: BookMatchable

    // MARK: - Lifecycle

    init(bookRepository: BookRepository, bookOCRKit: BookMatchable) {
        self.bookRepository = bookRepository
        self.bookOCRKit = bookOCRKit
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        Observable.merge(
            input.leftBarButtonTapTrigger,
            input.cameraPermissionCancelButtonTapTrigger
        )
        .bind(to: navigateBackRelay)
        .disposed(by: disposeBag)

        input.addBookByTextButtonTapTrigger
            .bind(to: navigateToAddBookByText)
            .disposed(by: disposeBag)

        input.capturedImage
            .flatMapLatest { [weak self] image -> Observable<Book> in
                guard self != nil else {
                    return .empty()
                }

                return Observable.create { observer in
                    let disposable = self?.bookOCRKit.recognizeBookFromImage(image)
                        .subscribe(
                            onSuccess: { book in
                                let finalBook = Book(
                                    isbn: book.isbn,
                                    title: book.title,
                                    author: book.author,
                                    publisher: book.publisher,
                                    thumbnailUrl: URL(string: book.image),
                                    isOwned: true,
                                    createdAt: Date(),
                                    updatedAt: Date(),
                                    description: book.description,
                                    price: book.discount ?? "",
                                    pubDate: book.pubdate ?? ""
                                )

                                observer.onNext(finalBook)
                                observer.onCompleted()

                            },
                            onFailure: { error in
                                LogKit.error("Error: \(error.localizedDescription)")
                                switch error {
                                case BookMatchError.networkError:
                                    self?.errorRelay.accept(NetworkError.networkUnstable)
                                case BookMatchError.noMatchFound:
                                    self?.errorRelay.accept(AddBookError.bookNotFound)
                                default:
                                    self?.errorRelay.accept(AddBookError.unknown)
                                }
                            }
                        )

                    return Disposables.create {
                        disposable?.dispose()
                    }
                }
            }
            .observe(on: MainScheduler.instance)
            .bind(to: bookMatchSuccessRelay)
            .disposed(by: disposeBag)

        input.confirmButtonTapTrigger
            .subscribe(with: self, onNext: { owner, book in
                let isSaved = owner.bookRepository.saveBook(book: book)
                if isSaved {
                    owner.navigateBackRelay.accept(())
                } else {
                    LogKit.error("중복된 책 에러 발생")
                    owner.errorRelay.accept(AddBookError.duplicatedBook)
                }
            }, onError: { owner, error in
                guard let error = error as? AlertPresentableError else {
                    LogKit.debug("error is not AlertPresentableError")
                    return
                }
                owner.errorRelay.accept(error)
            })
            .disposed(by: disposeBag)

        return Output(
            bookMatchSuccess: bookMatchSuccessRelay,
            error: errorRelay
        )
    }
}
