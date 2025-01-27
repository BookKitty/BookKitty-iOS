//
//  QuestionHistoryViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
//

import Foundation
import RxRelay
import RxSwift

final class QuestionHistoryViewModel: ViewModelType {
    struct Input {
        var testButtonTapTrigger: Observable<Void>
    }

    struct Output {}

    let disposeBag = DisposeBag()
    let navigateToQuestionDetail = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.testButtonTapTrigger
            .bind(to: navigateToQuestionDetail)
            .disposed(by: disposeBag)

        return Output()
    }
}
