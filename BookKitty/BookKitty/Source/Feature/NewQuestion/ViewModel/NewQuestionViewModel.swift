//
//  NewQuestionViewModel.swift
//  BookKitty
//
//  Created by 권승용 on 1/31/25.
//

import Foundation
import RxCocoa
import RxSwift

/// 새로운 질문 화면을 위한 ViewModel
/// 사용자가 입력한 질문을 질문 결과 화면으로 전달하는 책임을 가짐
final class NewQuestionViewModel: ViewModelType {
    /// ViewModel의 Input 구현체
    struct Input {
        /// 질문하기 버튼 탭
        let submitButtonTapped: Observable<String>
    }

    /// ViewModel의 Output 구현체
    /// 이 뷰모델은 뷰컨으로 전달하는 Output이 없습니다
    struct Output {}

    let disposeBag = DisposeBag()

    /// 질문 결과 화면으로 이동하는 트리거 이벤트를 발행하는 시퀀스
    let navigateToQuestionResult = PublishRelay<String>()

    /// ViewModel의 주요 로직을 처리하는 transform 함수
    /// - Parameter input: ViewController에서 전달하는 Input 구조체
    /// - Returns: Output 구조체
    func transform(_ input: Input) -> Output {
        input.submitButtonTapped
            .bind(to: navigateToQuestionResult)
            .disposed(by: disposeBag)

        return Output()
    }
}
