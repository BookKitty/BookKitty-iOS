//
//  RecommendationViewModel.swift
//  BookKitty
//
//  Created by 권승용 on 1/31/25.
//

import Foundation
import RxCocoa
import RxSwift

final class RecommendationViewModel: ViewModelType {
    // MARK: Lifecycle

    init(
        recommendationService: BookMatchable,
        bookRepository: BookRepository,
        questionHistoryRepository: QuestionHistoryRepository
    ) {
        self.recommendationService = recommendationService
        self.bookRepository = bookRepository
        self.questionHistoryRepository = questionHistoryRepository
    }

    // MARK: Internal

    struct Input {
        let viewDidLoad: Observable<String> // 뷰가 로드될 때 전달받은 질문
        let bookSelected: Observable<Book> // 사용자가 선택한 책
        let lalalaButtonTapped: Observable<Void> // 버튼이 탭됐을 때 이벤트
    }

    struct Output {
        let userQuestion: Driver<String> // 사용자의 질문
        let recommendedBooks: Driver<[Book]> // 추천된 책 목록
        let recommendationReason: Driver<String> // 추천 이유
        let error: PublishRelay<Error> // 에러 처리
    }

    let disposeBag = DisposeBag()

    // 화면 이동을 위한 Relay
    let navigateToBookDetail = PublishRelay<Book>()
    let navigateToQuestionHistory = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
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
            error: errorRelay
        )
    }

    // MARK: Private

    private let questionHistoryRepository: QuestionHistoryRepository
    private let bookRepository: BookRepository
    private let recommendationService: BookMatchable

    private let userQuestionRelay = BehaviorRelay<String>(value: "")
    private let recommendedBooksRelay = BehaviorRelay<[Book]>(value: [])
    private let recommendationReasonRelay = BehaviorRelay<String>(value: "")
    private let errorRelay = PublishRelay<Error>()

    private func fetchBookInfoFromService(_ viewDidLoad: Observable<String>)
        -> Observable<(String, BookMatchModuleOutput)> {
        viewDidLoad
            .withUnretained(self)
            .flatMapLatest { _, question in
                // 코어데이터에서 사용자가 소유한 책 가져오기 (예제 데이터)
                let ownedBooks = [OwnedBook(
                    isbn: "978-3-16-148410-0",
                    title: "Swift Programming for Beginners",
                    author: "John Doe"
                )]

                // 서비스 입력을 위한 데이터 생성
                let input = BookMatchModuleInput(question: question, ownedBooks: ownedBooks)

                // 추천 서비스 호출
                return Observable<(String, BookMatchModuleOutput)>.create { observer in
                    let task = Task {
                        do {
                            let output = try await self.recommendationService
                                .processBookRecommendation(input)
                            observer.onNext((question, output)) // 결과 방출
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
        -> [Book] {
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

        return recommendedBooks
    }

    /// 추천된 이유를 매핑하는 함수
    private func mapRecommendationReason(_ questionAndOutput: (String, BookMatchModuleOutput))
        -> String {
        questionAndOutput.1.description
    }
}

// MARK: - 테스트를 위한 BookService -> Service 도입 후 삭제할 예정

struct BookMatchModuleInput {
    let question: String
    let ownedBooks: [OwnedBook]
}

struct BookMatchModuleOutput {
    let ownedISBNs: [String]
    let newBooks: [BookItem]
    let description: String
}

struct OwnedBook {
    let isbn: String
    let title: String
    let author: String
}

struct BookItem: Identifiable, Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case title
        case link
        case image
        case author
        case discount
        case publisher
        case isbn
        case description
        case pubdate
    }

    let id = UUID()
    let title: String
    let link: String
    let image: String
    let author: String
    let discount: String?
    let publisher: String
    let isbn: String
    let description: String
    let pubdate: String
}

protocol BookMatchable {
    func processBookRecommendation(_ input: BookMatchModuleInput) async throws
        -> BookMatchModuleOutput
}

struct BookRecommendationService: BookMatchable {
    func processBookRecommendation(_: BookMatchModuleInput) async throws -> BookMatchModuleOutput {
        BookMatchModuleOutput(ownedISBNs: [], newBooks: [], description: "")
    }
}
