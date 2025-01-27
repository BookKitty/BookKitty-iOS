//
//  QuestionDetailViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import RxRelay
import RxSwift

final class QuestionDetailViewModel: ViewModelType {
    struct Input {
        var testButtonTapTrigger: Observable<Void>
    }

    struct Output {}

    let disposeBag = DisposeBag()
    let navigateToBookDetail = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.testButtonTapTrigger
            .bind(to: navigateToBookDetail)
            .disposed(by: disposeBag)

        return Output()
    }
}
