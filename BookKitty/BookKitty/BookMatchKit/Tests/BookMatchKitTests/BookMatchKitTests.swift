@testable import BookMatchCore
@testable import BookOCRKit
@testable import BookRecommendationKit
import RxSwift
import XCTest

final class BookMatchKitTests: XCTestCase {
    // MARK: - Properties

    let disposeBag = DisposeBag()

    let questions = [
        //        "요즘 스트레스가 많은데, 마음의 안정을 찾을 수 있는 책 추천해주세요.",
//        "SF와 판타지를 좋아하는데, 현실과 가상세계를 넘나드는 소설 없을까요?",
//        "창업 준비 중인데 스타트업 성공사례를 다룬 책을 찾고 있어요.",
//
//        "철학책을 처음 읽어보려고 하는데, 입문자가 읽기 좋은 책이 있을까요?",
        "퇴사 후 새로운 삶을 준비하는 중인데, 인생의 방향을 찾는데 도움이 될 만한 책 있나요?",
//        "육아로 지친 마음을 위로받을 수 있는 책을 찾고 있어요.",
//        "무라카미 하루키 스타일의 미스터리 소설 없을까요?",
//
//        "'사피엔스'를 재미있게 읽었는데, 비슷한 책 추천해주세요.",
//        "우울할 때 읽으면 좋은 따뜻한 책 추천해주세요.",
//        "의욕이 없을 때 동기부여가 될 만한 책 없을까요?",
    ]

    let dummyOwnedBooks: [OwnedBook] = [
        OwnedBook(id: "9788934972464", title: "사피엔스", author: "유발 하라리"),
        OwnedBook(id: "9788901260716", title: "아몬드", author: "손원평"),
        OwnedBook(id: "9788901219943", title: "공정하다는 착각", author: "마이클 샌델"),
        OwnedBook(id: "9788901255828", title: "대도시의 사랑법", author: "박상영"),
        OwnedBook(id: "9788932917245", title: "달러구트 꿈 백화점", author: "이미예"),
        OwnedBook(id: "9788936434267", title: "이기적 유전자", author: "리처드 도킨스"),
        OwnedBook(id: "9788901285610", title: "부의 추월차선", author: "엠제이 드마코"),
        OwnedBook(id: "9788950965510", title: "원씽", author: "게리 켈러"),
        OwnedBook(id: "9788901255279", title: "멋진 신세계", author: "올더스 헉슬리"),
        OwnedBook(id: "9788937460449", title: "1984", author: "조지 오웰"),
    ]

    let module = BookRecommendationKit(
        naverClientId: "",
        naverClientSecret: "",
        openAIApiKey: ""
    )

    // MARK: - Overridden Functions

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Functions

    func test_RecommendForQuestion() async {
        var total = 0
        for question in questions {
            let result = try! await recommendationKit.recommendBooks(for: question, from: []).value
            total += result.newBooks.count

            XCTAssertTrue(!result.description.isEmpty)
            XCTAssertTrue(!result.newBooks.isEmpty)

            print(result)
        }
    }

    func test_RecommendFromOwnedBooks() async {
        let result = try! await recommendationKit.recommendBooks(from: dummyOwnedBooks).value

        print(result)
        XCTAssertTrue(!result.isEmpty)
    }

//
//    func accurancyTester(question: String, title: String) async -> Int {
//        let prompt = """
//        질문: \(question)
//        도서 제목: \(title)
//        """
//
//        let advancedSystem = """
//          당신은 공감력이 뛰어난 전문 북큐레이터입니다. 도서의 제목과 상세정보를 보고, 질문에 적합한 도서인지 여부를 0이나 1로 표현해주세요:
//
//          1. 입/출력 형식
//          입력:
//          - 질문 (문자열)
//          - 도서 제목: (문자열)
//          - 도서 상세정보: (문자열)
//
//          출력: 0 또는 1
//          0: 책이 질문의 맥락이나 의도와 전혀 관련이 없는 경우에만 해당
//          1: 다음 중 하나라도 해당되는 경우
//          - 책이 질문과 직접적으로 관련된 경우
//          - 책이 질문의 근본적인 감정이나 니즈를 간접적으로라도 충족시킬 수 있는 경우
//          - 책이 질문자의 상황이나 심리상태에 위로나 통찰을 줄 수 있는 경우
//          - 최근 판매량과 같이 객관적 확인이 어려운 질문의 경우
//
//          2. 필수 규칙
//          - 최근 한달 간 제일 많이 팔린 책과 같이 확인이 어려운 질문은 1로 반환
//        """
//
//        let requestBody: [String: Any] = [
//            "model": "gpt-4o",
//            "messages": [
//                ["role": "system", "content": advancedSystem],
//                ["role": "user", "content": prompt],
//            ],
//            "temperature": 0.01,
//            "max_tokens": 50,
//        ]
//
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            return -1
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(config.openAIApiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
//
//            let (data, _) = try await URLSession.shared.data(for: request)
//
//            let response = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
//
//            if let result = response.choices.first?.message.content, let resultInt = Int(result) {
//                return resultInt
//            } else {
//                return -1
//            }
//        } catch {
//            return -1
//        }
//    }
    func testrecognizeBookFromImageWithValidImage() {
        guard let testImage = loadTestImage(named: "book1") else {
            XCTFail("Failed to load test image")
            return
        }

        // When
        let bookMatch = bookMatchKit.recognizeBookFromImage(testImage)
        let matchExpectation = expectation(for: bookMatch)

        // Then
        wait(for: [matchExpectation], timeout: 10.0)
    }

    func testrecognizeBookFromImageWithMultipleImages() async {
        let imageNames = (1 ... 20).map { "book\($0)" }
        var cnt = 0
        for imageName in imageNames {
            guard let testImage = loadTestImage(named: imageName) else {
                XCTFail("Failed to load test image: \(imageName)")
                continue
            }
            do {
                let bookMatch = try await bookMatchKit.recognizeBookFromImage(testImage).value
                print(bookMatch.title)
                cnt += 1
            } catch {
                print("error in \(imageName)")
            }
        }
        print("accurancy: \(cnt / imageNames.count)")
    }

    func testrecognizeBookFromImageWithInvalidImage() {
        // Given
        let invalidImage = UIImage()

        // When
        let bookMatch = bookMatchKit.recognizeBookFromImage(invalidImage)

        // Then
        bookMatch
            .subscribe(
                onSuccess: { _ in
                    XCTFail("Should not succeed with invalid image")
                },
                onFailure: { error in
                    XCTAssertTrue(error is BookMatchError)
                    if let bookMatchError = error as? BookMatchError {
                        XCTAssertEqual(bookMatchError, .OCRError("convertToGrayscale Failed"))
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    func testrecognizeBookFromImagePerformance() {
        guard let testImage = loadTestImage(named: "book1") else {
            XCTFail("Failed to load test image")
            return
        }

        measure {
            let bookMatch = bookMatchKit.recognizeBookFromImage(testImage)
            let matchExpectation = expectation(for: bookMatch)
            wait(for: [matchExpectation], timeout: 10.0)
        }
    }

    func testrecognizeBookFromImageConcurrency() {
        // This test validates that multiple concurrent matching requests work correctly
        let imageNames = ["book1", "book2", "book3", "book4", "book5"]
        var expectations: [XCTestExpectation] = []

        for imageName in imageNames {
            guard let testImage = loadTestImage(named: imageName) else {
                XCTFail("Failed to load test image: \(imageName)")
                continue
            }

            let bookMatch = bookMatchKit.recognizeBookFromImage(testImage)
            expectations.append(expectation(for: bookMatch))
        }

        wait(for: expectations, timeout: 30.0)
    }

    // MARK: - Helper Methods

    private func loadTestImage(named: String) -> UIImage? {
        guard let url = Bundle.module.url(
            forResource: named,
            withExtension: "png",
            subdirectory: "images"
        ),
            let image = UIImage(contentsOfFile: url.path) else {
            XCTFail("Could not load image at path: TestImages/\(named).png")
            return nil
        }
        return image
    }

    private func expectation(for bookMatch: Single<BookItem>) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "Book matching completion")

        bookMatch
            .subscribe(
                onSuccess: { _ in
                    expectation.fulfill()
                },
                onFailure: { error in
                    XCTFail("Book matching failed with error: \(error)")
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        return expectation
    }
}
