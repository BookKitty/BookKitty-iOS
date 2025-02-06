//
//  QuestionResultViewModel.swift
//  BookKitty
//
//  Created by 권승용 on 1/31/25.
//

import BookMatchCore
import BookMatchKit
import Foundation
import RxCocoa
import RxSwift

final class QuestionResultViewModel: ViewModelType {
    // MARK: Lifecycle

    init(
        userQuestion: String,
        recommendationService: BookMatchable,
        bookRepository: BookRepository,
        questionHistoryRepository: QuestionHistoryRepository
    ) {
        self.userQuestion = userQuestion
        self.recommendationService = recommendationService
        self.bookRepository = bookRepository
        self.questionHistoryRepository = questionHistoryRepository
    }

    // MARK: Internal

    struct Input {
        let viewDidLoad: Observable<Void> // 뷰가 로드될 때 전달받은 질문
        let bookSelected: Observable<Book> // 사용자가 선택한 책
        let lalalaButtonTapped: Observable<Void> // 버튼이 탭됐을 때 이벤트
    }

    struct Output {
        let userQuestion: Driver<String> // 사용자의 질문
        let recommendedBooks: Driver<[SectionOfBook]> // 추천된 책 목록
        let recommendationReason: Driver<String> // 추천 이유
        let error: Observable<Error> // 에러 처리
    }

    let disposeBag = DisposeBag()
    // 화면 이동을 위한 Relay
    let navigateToBookDetail = PublishRelay<Book>()
    let navigateToQuestionHistory = PublishRelay<Void>()
    let navigateToRoot = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .withUnretained(self)
            .map { _ in
                self.userQuestion
            }
            .bind(to: userQuestionRelay) // 질문을 저장
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

        input.lalalaButtonTapped
            .bind(to: navigateToQuestionHistory) // 질문 내역 화면으로 이동
            .disposed(by: disposeBag)

        return Output(
            userQuestion: userQuestionRelay.asDriver(),
            recommendedBooks: recommendedBooksRelay.asDriver(),
            recommendationReason: recommendationReasonRelay.asDriver(),
            error: errorRelay.asObservable()
        )
    }

    // MARK: Private

    private let userQuestion: String

    private let questionHistoryRepository: QuestionHistoryRepository
    private let bookRepository: BookRepository
    private let recommendationService: BookMatchable

    private let userQuestionRelay = BehaviorRelay<String>(value: "")
    private let recommendedBooksRelay = BehaviorRelay<[SectionOfBook]>(value: [])
    private let recommendationReasonRelay = BehaviorRelay<String>(value: "")
    private let errorRelay = PublishRelay<Error>()

    private func fetchBookInfoFromService(_ viewDidLoad: Observable<Void>)
        -> Observable<(String, BookMatchModuleOutput)> {
        viewDidLoad
            .withUnretained(self)
            .flatMapLatest { _ in
                // 코어데이터에서 사용자가 소유한 책 가져오기 (예제 데이터)
                let ownedBooks = self.bookRepository.fetchAllBooks().map {
                    OwnedBook(
                        id: $0.isbn,
                        title: $0.title,
                        author: $0.author
                    )
                }

                // 서비스 입력을 위한 데이터 생성
                let input = BookMatchModuleInput(
                    question: self.userQuestion,
                    ownedBooks: ownedBooks
                )

                // 추천 서비스 호출
                return Observable<(String, BookMatchModuleOutput)>.create { observer in
                    let task = Task {
                        do {
                            // TODO: 에러 받아서 처리하기
                            let output = await self.recommendationService.recommendBooks(for: input)
                            observer.onNext((self.userQuestion, output)) // 결과 방출
                        } catch {
                            self.errorRelay.accept(error) // 에러 발생 시 처리
                        }
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
        let ownedBooks = bookRepository.fetchBookDetailFromISBNs(isbnList)

        // 새로운 추천 도서를 Book 모델로 변환
        let newBooks = output.newBooks.map {
            Book(
                isbn: $0.isbn,
                title: $0.title,
                author: $0.author,
                publisher: $0.publisher,
                thumbnailUrl: URL(string: $0.image)
            )
        }

        // 기존 책 + 새로운 책 결합
        let recommendedBooks = ownedBooks + newBooks

        // 질문 및 추천 정보를 저장
        let questionToSave = QuestionAnswer(
            createdAt: Date(),
            userQuestion: question,
            gptAnswer: output.description,
            recommendedBooks: recommendedBooks
        )
        questionHistoryRepository.saveQuestion(questionToSave)

        return [SectionOfBook(items: recommendedBooks)]
    }

    /// 추천된 이유를 매핑하는 함수
    private func mapRecommendationReason(_ questionAndOutput: (String, BookMatchModuleOutput))
        -> String {
        questionAndOutput.1.description
    }
}
