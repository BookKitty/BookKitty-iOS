//
//  NewQuestionViewModelTests.swift
//  BookKitty
//
//  Created by 권승용 on 1/31/25.
//

@testable import BookKitty
import RxSwift
import Testing

struct NewQuestionViewModelTests {
    /// 질문하기 버튼이 탭되었을 때 답변 화면으로 이동하는지 테스트
    @Test("질문하기 버튼 탭 -> 네비게이션 이벤트 방출")
    func test_questionButtonTapped() async {
        let vm = NewQuestionViewModel()
        let submitButtonTappedSubject = PublishSubject<String>()

        let input = NewQuestionViewModel.Input(
            submitButtonTapped: submitButtonTappedSubject.asObservable(),
            leftBarButtonTapTrigger: .empty()
        )

        _ = vm.transform(input)

        // 비동기 작업을 통해 책 탭 이벤트 방출
        Task {
            // publishSubject 구독을 기다리기 위해 3초 기다리고 방출
            try await Task.sleep(nanoseconds: 3_000_000_000)
            submitButtonTappedSubject.onNext("tapped") // 질문하기 버튼 탭 트리거 방출
        }

        do {
            // submitButtonTappedSubject에서 방출한 값과 같은지 확인
            for try await value in vm.navigateToQuestionResult.values {
                #expect(value == "tapped")
                break
            }
        } catch {}
    }
}
