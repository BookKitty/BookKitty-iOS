//
//  RecommendationViewModelTests.swift
//  BookKitty
//
//  Created by 권승용 on 1/31/25.
//

@testable import BookKitty
import Foundation
import RxSwift
import Testing

struct RecommendationViewModelTests {
    // MARK: Internal

    // 테스트: viewDidLoad에서 유저 질문이 올바르게 처리되는지 확인하는 테스트
    @Test
    func test_viewDidLoad_userQuestion() async {
        // RecommendationViewModel 인스턴스 생성
        let vm = RecommendationViewModel(
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )

        // 입력 값 정의: 유저 질문 및 기타 이벤트
        let input = RecommendationViewModel.Input(
            viewDidLoad: .just("유저 질문"), // 유저 질문
            bookSelected: .empty(), // 선택된 책 없음
            lalalaButtonTapped: .empty() // 버튼 클릭 없음
        )

        // 변환된 출력 값 가져오기
        let output = vm.transform(input)

        // 출력 값이 유저 질문과 일치하는지 확인
        for await value in await output.userQuestion.values {
            #expect(value == "유저 질문")
            break
        }
    }

    // 테스트: viewDidLoad에서 추천 책이 올바르게 처리되는지 확인하는 테스트
    @Test
    func test_viewDidLoad_recommendBook() async {
        // RecommendationViewModel 인스턴스 생성
        let vm = RecommendationViewModel(
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )

        // 입력 값 정의: 유저 질문 및 기타 이벤트
        let input = RecommendationViewModel.Input(
            viewDidLoad: .just("유저 질문"), // 유저 질문
            bookSelected: .empty(), // 선택된 책 없음
            lalalaButtonTapped: .empty() // 버튼 클릭 없음
        )

        // 변환된 출력 값 가져오기
        let output = vm.transform(input)

        // 출력 값이 추천 책과 일치하는지 확인
        for await value in await output.recommendedBooks.values {
            #expect(
                value == Constant.testBookList
            )
            break
        }
    }

    // 테스트: 책 선택 이벤트가 올바르게 처리되는지 확인하는 테스트
    @Test
    func test_bookSelected_navigateToBookDetail() async {
        // RecommendationViewModel 인스턴스 생성
        let vm = RecommendationViewModel(
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )
        let bookSelectedSubject = PublishSubject<Book>()

        // 입력 값 정의: 책 선택 이벤트
        let input = RecommendationViewModel.Input(
            viewDidLoad: .empty(), // viewDidLoad 이벤트 없음
            bookSelected: bookSelectedSubject.asObservable(), // 책 선택 이벤트
            lalalaButtonTapped: .empty() // 버튼 클릭 없음
        )

        // 변환된 출력 값 가져오기
        _ = vm.transform(input)

        // PublishSubject에 값을 전달하기 위해 3초후 책 선택 이벤트 발생
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            bookSelectedSubject.onNext(Constant.testBook)
        }

        // 출력 값이 책 상세 페이지로 이동하는지 확인
        do {
            for try await value in vm.navigateToBookDetail.values {
                #expect(value == Constant.testBook)
                break
            }
        } catch {}
    }

    // 테스트: 버튼 클릭 이벤트가 올바르게 처리되는지 확인하는 테스트
    @Test
    func test_lalalaButtonTapped_navigateToQuestionList() async {
        // RecommendationViewModel 인스턴스 생성
        let vm = RecommendationViewModel(
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )
        let lalalaButtonTappedSubject = PublishSubject<Void>()

        // 입력 값 정의: 버튼 클릭 이벤트
        let input = RecommendationViewModel.Input(
            viewDidLoad: .empty(), // viewDidLoad 이벤트 없음
            bookSelected: .empty(), // 책 선택 이벤트 없음
            lalalaButtonTapped: lalalaButtonTappedSubject.asObservable() // 버튼 클릭 이벤트
        )

        // 변환된 출력 값 가져오기
        _ = vm.transform(input)

        // PublishSubject에 값을 전달하기 위해 3초후 버튼 클릭 이벤트 발생
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            lalalaButtonTappedSubject.onNext(())
        }

        // 출력 값이 질문 목록 페이지로 이동하는지 확인
        do {
            for try await value in vm.navigateToQuestionHistory.values {
                #expect(value == ())
                break
            }
        } catch {}
    }

    // MARK: Private

    // Mock 서비스 및 리포지토리 인스턴스
    private let recommendationService = MockRecommendationService()
    private let bookRepository = TestBookRepository()
    private let questionHistoryRepository = MockQuestionHistoryRepository()
}

/// Mock 책 리포지토리 클래스
class TestBookRepository: BookRepository {
    func fetchBookList(offset _: Int, limit _: Int) -> [BookKitty.Book] {
        []
    }

    func fetchBookDetail() -> BookKitty.Book {
        Constant.testBook
    }

    /// 책 목록 가져오기
    func fetchBookList() {}

    /// 책 상세 정보 가져오기
    func fetchBookDetail() {}

    /// ISBN으로 책 상세 정보 가져오기
    func fetchBookDetailFromISBNs(_: [String]) -> [Book] {
        [
            Constant.testBook,
        ]
    }

    /// 책 목록 저장
    func saveBookList() {}

    /// 책 삭제
    func deleteBook() {}
}

/// Mock 추천 서비스 클래스
class MockRecommendationService: BookMatchable {
    /// 책 추천 처리
    func processBookRecommendation(_: BookKitty.BookMatchModuleInput) async throws -> BookKitty
        .BookMatchModuleOutput {
        BookMatchModuleOutput(
            ownedISBNs: [
                "9784063164130",
                "9784063164147",
            ],
            newBooks: [
                BookItem(
                    title: "Swift Programming",
                    link: "https://bookstore.com/1234567890123",
                    image: "https://bookstore.com/images/1234567890123.jpg",
                    author: "John Doe",
                    discount: "20%",
                    publisher: "TechBooks",
                    isbn: "1234567890123",
                    description: "A comprehensive guide to Swift programming.",
                    pubdate: "2024-01-15"
                ),
            ],
            description: "이러한 이유로 당신에게 책을 추천합니당"
        )
    }
}

/// 테스트용 상수 정의
private enum Constant {
    /// 테스트용 책 인스턴스
    static let testBook = Book(
        isbn: "978-0-123456-47-2",
        title: "The Swift Journey",
        author: "Alice Johnson",
        publisher: "CodePress",
        thumbnailUrl: URL(string: "https://example.com/swift_journey.jpg")
    )

    /// 테스트용 책 목록
    static let testBookList = [
        Book(
            isbn: "978-0-123456-47-2",
            title: "The Swift Journey",
            author: "Alice Johnson",
            publisher: "CodePress",
            thumbnailUrl: URL(string: "https://example.com/swift_journey.jpg")
        ),
        Book(
            isbn: "1234567890123",
            title: "Swift Programming",
            author: "John Doe",
            publisher: "TechBooks",
            thumbnailUrl: URL(string: "https://bookstore.com/images/1234567890123.jpg")
        ),
    ]
}
