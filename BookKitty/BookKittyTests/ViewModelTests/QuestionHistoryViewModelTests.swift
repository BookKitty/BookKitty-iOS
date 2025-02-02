//
//  QuestionHistoryViewModelTests.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

@testable import BookKitty
import Foundation
import RxSwift
import Testing

// QuestionHistoryViewModel의 단위 테스트
// 테스트 대상: QuestionHistoryViewModel의 입력 이벤트가 올바른 출력을 생성하는지 확인

@testable import BookKitty
import Foundation
import RxSwift
import Testing

@MainActor
struct QuestionHistoryViewModelTests {
    // MARK: Internal

    /// viewDidLoad 이벤트가 발생하면 질문 목록이 올바르게 방출되는지 테스트
    @Test("viewDidLoad -> 질문 목록 방출")
    func test_viewDidLoad() async {
        let vm = QuestionHistoryViewModel(questionRepository: repository)

        // Input 정의: viewDidLoad 이벤트가 발생함
        let input = QuestionHistoryViewModel.Input(
            viewDidLoad: .just(()),
            questionSelected: .never(),
            reachedScrollEnd: .never()
        )

        let output = vm.transform(input)
        var didEmit = false

        // Output 검증: 질문 목록이 올바르게 방출되는지 확인
        for await value in output.questions.values {
            #expect(value == repository.mockQuestionList)
            didEmit = true
            break
        }

        // 만약 방출되지 않았다면 실패 처리
        if !didEmit {
            #expect(Bool(false))
        }
    }

    /// 질문을 선택하면 해당 질문의 상세 화면으로 이동하는 이벤트가 발생하는지 테스트
    @Test("질문 선택 -> 질문 상세로 이동 이벤트 방출", .timeLimit(.minutes(1)))
    func test_questionSelected() async {
        let vm = QuestionHistoryViewModel(questionRepository: repository)
        let questionSelectedSubject = PublishSubject<Question>()

        // Input 정의: 질문이 선택됨
        let input = QuestionHistoryViewModel.Input(
            viewDidLoad: .never(),
            questionSelected: questionSelectedSubject.asObservable(),
            reachedScrollEnd: .never()
        )

        _ = vm.transform(input)
        var didEmit = false

        // 3초 후에 질문 선택 이벤트를 발생시킴
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            questionSelectedSubject.onNext(repository.mockQuestionList[0])
        }

        // Output 검증: 올바른 질문이 선택되었는지 확인
        do {
            for try await value in vm.navigateToQuestionDetail.values {
                #expect(value == repository.mockQuestionList[0])
                didEmit = true
                break
            }
        } catch {}

        // 만약 방출되지 않았다면 실패 처리
        if !didEmit {
            #expect(Bool(false))
        }
    }

    /// 스크롤이 마지막에 도달하면 새로운 질문 목록이 방출되는지 테스트
    @Test("마지막으로 스크롤 -> 새로운 이벤트 방출")
    func test_reachedScrollEnd() async {
        let vm = QuestionHistoryViewModel(questionRepository: repository)

        // Input 정의: 스크롤이 마지막에 도달하는 이벤트 발생
        let input = QuestionHistoryViewModel.Input(
            viewDidLoad: .never(),
            questionSelected: .never(),
            reachedScrollEnd: .just(())
        )

        let output = vm.transform(input)
        var didEmit = false

        // Output 검증: 새로운 질문 목록이 방출되는지 확인
        for await value in output.questions.values {
            #expect(value == repository.mockQuestionList)
            didEmit = true
            break
        }

        // 만약 방출되지 않았다면 실패 처리
        if !didEmit {
            #expect(Bool(false))
        }
    }

    // MARK: Private

    /// Mock 데이터 저장소를 사용하여 테스트 수행
    private let repository = MockQuestionHistoryRepository()
}
