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

                return Observable.create { observer in
                    let bookMatchKit = BookMatchKit(
                        naverClientId: Environment().naverClientID,
                        naverClientSecret: Environment().naverClientSecret
                    )

                    Task {
                        do {
                            let book = try await bookMatchKit.matchBook(image)
                            guard let book else {
                                throw BookMatchError.noMatchFound
                            }
                            let finalBook = Book(
                                isbn: book.isbn,
                                title: book.title,
                                author: book.author,
                                publisher: book.publisher,
                                thumbnailUrl: URL(string: book.image),
                                description: book.description,
                                price: book.discount ?? "",
                                pubDate: book.pubdate ?? ""
                            )

                            observer.onNext(finalBook)
                            observer.onCompleted()
                        } catch {
                            observer.onError(BookMatchError.noMatchFound)
                            return
                        }
                    }

                    return Disposables.create()
                }
            }
            .observe(on: MainScheduler.instance)
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
