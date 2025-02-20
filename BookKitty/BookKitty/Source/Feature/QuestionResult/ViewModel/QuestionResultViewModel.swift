//
//  QuestionResultViewModel.swift
//  BookKitty
//
//  Created by 권승용 on 1/31/25.
//

import BookRecommendationKit
import Foundation
import RxCocoa
import RxSwift

final class QuestionResultViewModel: ViewModelType {
    // MARK: - Nested Types

    // MARK: - Internal

    struct Input {
        let viewDidLoad: Observable<Void> // 뷰가 로드될 때 전달받은 질문
        let viewWillAppear: Observable<Void> // 뷰가 보일 때 책 소유 여부 업데이트
        let bookSelected: Observable<Book> // 사용자가 선택한 책
        let submitButtonTapped: Observable<Void> // 버튼이 탭됐을 때 이벤트
    }

    struct Output {
        let userQuestion: Driver<String> // 사용자의 질문
        let recommendedBooks: Driver<[SectionOfBook]> // 추천된 책 목록
        let recommendationReason: Driver<String> // 추천 이유
        let requestFinished: PublishRelay<Void> // 요청 완료 (로딩 해제)
        let error: Observable<AlertPresentableError> // 에러 처리
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    // 화면 이동을 위한 Relay
    let navigateToBookDetail = PublishRelay<Book>()
    let navigateToQuestionHistory = PublishRelay<Void>()

    // MARK: - Private

    private let userQuestion: String
    private var questionAnswer: QuestionAnswer?

    private let questionHistoryRepository: QuestionHistoryRepository
    private let bookRepository: BookRepository
    private let recommendationService: BookRecommendable

    private let userQuestionRelay = BehaviorRelay<String>(value: "")
    private let recommendedBooksRelay = BehaviorRelay<[SectionOfBook]>(value: [])
    private let recommendationReasonRelay = BehaviorRelay<String>(value: "")
    private let requestFinishedRelay = PublishRelay<Void>()
    private let errorRelay = PublishRelay<AlertPresentableError>()

    // MARK: - Lifecycle

    init(
        userQuestion: String,
        recommendationService: BookRecommendable,
        bookRepository: BookRepository,
        questionHistoryRepository: QuestionHistoryRepository
    ) {
        self.userQuestion = userQuestion
        self.recommendationService = recommendationService
        self.bookRepository = bookRepository
        self.questionHistoryRepository = questionHistoryRepository
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .withUnretained(self)
            .map { owner, _ in
                owner.userQuestion
            }
            .bind(to: userQuestionRelay) // 질문을 저장
            .disposed(by: disposeBag)

        input.viewWillAppear
            .withUnretained(self)
            .map { owner, _ in
                // 아직 책 정보가 없으면 업데이트 필요 x
                guard !owner.recommendedBooksRelay.value.isEmpty,
                      let uuid = owner.questionAnswer?.id else {
                    return []
                }

                guard let updatedQnA = owner.questionHistoryRepository.fetchQuestion(by: uuid)
                else {
                    return []
                }

                let books = updatedQnA.recommendedBooks
                return [SectionOfBook(items: books)]
            }
            .bind(to: recommendedBooksRelay)
            .disposed(by: disposeBag)

        let fetchBookInfoFromService = fetchBookInfoFromService(input.viewDidLoad)

        fetchBookInfoFromService
            .map(saveQuestionAndmapRecommendedBooks) // 추천된 책 정보 변환
            .bind(to: recommendedBooksRelay)
            .disposed(by: disposeBag)

        fetchBookInfoFromService
            .map(mapRecommendationReason) // 추천 이유 변환
            .bind(to: recommendationReasonRelay)
            .disposed(by: disposeBag)

        input.bookSelected
            .bind(to: navigateToBookDetail) // 책 상세 화면으로 이동
            .disposed(by: disposeBag)

        input.submitButtonTapped
            .bind(to: navigateToQuestionHistory) // 질문 내역 화면으로 이동
            .disposed(by: disposeBag)

        return Output(
            userQuestion: userQuestionRelay.asDriver(),
            recommendedBooks: recommendedBooksRelay.asDriver(),
            recommendationReason: recommendationReasonRelay.asDriver(),
            requestFinished: requestFinishedRelay,
            error: errorRelay.asObservable()
        )
    }

    private func fetchBookInfoFromService(_ viewDidLoad: Observable<Void>)
        -> Observable<(String, BookMatchModuleOutput)> {
        viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                // 코어데이터에서 사용자가 소유한 전체 책 가져오기
                let ownedBooks = owner.bookRepository.fetchBookList(offset: 0, limit: 0).map {
                    OwnedBook(
                        id: $0.isbn,
                        title: $0.title,
                        author: $0.author
                    )
                }

                // 추천 서비스 호출
                return Observable<(String, BookMatchModuleOutput)>.create { observer in
                    let task = Task {
                        // TODO: 에러 받아서 처리하기
                        owner.recommendationService.recommendBooks(
                            for: owner.userQuestion,
                            from: ownedBooks
                        )
                        .subscribe(onSuccess: { result in
                            observer.onNext((owner.userQuestion, result))
                        }, onFailure: { error in
                            guard let error = error as? BookMatchError else {
                                return
                            }

                            switch error {
                            case .networkError:
                                owner.errorRelay.accept(NetworkError.networkUnstable)
                            default:
                                owner.errorRelay.accept(AddBookError.unknown)
                            }
                        }) // 결과 방출
                    }
                    return Disposables.create {
                        task.cancel() // 작업 취소
                    }
                }
            }
            .share()
    }

    /// 추천된 책 정보를 매핑하는 함수
    private func saveQuestionAndmapRecommendedBooks(_ questionAndOutput: (
        String,
        BookMatchModuleOutput
    ))
        -> [SectionOfBook] {
        let question = questionAndOutput.0
        let output = questionAndOutput.1

        // 코어데이터에서 저장된 책 정보 가져오기
        let isbnList = output.ownedISBNs
        let ownedBooks = bookRepository.fetchBookDetailFromISBNs(isbnList: isbnList)

        // 새로운 추천 도서를 Book 모델로 변환
        let newBooks = output.newBooks.map {
            Book(
                isbn: $0.isbn,
                title: $0.title,
                author: $0.author,
                publisher: $0.publisher,
                thumbnailUrl: URL(string: $0.image),
                isOwned: false,
                description: $0.description,
                price: $0.discount ?? "",
                pubDate: $0.pubdate ?? ""
            )
        }

        // 기존 책 + 새로운 책 결합
        let recommendedBooks = ownedBooks + newBooks

        // 질문 및 추천 정보를 저장
        let questionToSave = QuestionAnswer(
            createdAt: Date(),
            userQuestion: question,
            gptAnswer: output.description,
            id: UUID(),
            recommendedBooks: recommendedBooks
        )
        let _ = questionHistoryRepository.saveQuestionAnswer(data: questionToSave)

        questionAnswer = questionToSave

        requestFinishedRelay.accept(())
        return [SectionOfBook(items: recommendedBooks)]
    }

    /// 추천된 이유를 매핑하는 함수
    private func mapRecommendationReason(_ questionAndOutput: (String, BookMatchModuleOutput))
        -> String {
        questionAndOutput.1.description
    }
}
