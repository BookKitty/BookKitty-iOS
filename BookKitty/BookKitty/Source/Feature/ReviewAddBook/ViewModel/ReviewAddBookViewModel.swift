//
//  ReviewAddBookViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/31/25.
//

import Foundation
import RxRelay
import RxSwift

final class ReviewAddBookViewModel: ViewModelType {
    struct Input {
        var testButton02Trigger: Observable<Void>
    }

    struct Output {}

    let disposeBag = DisposeBag()
    let navigateToBookList = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.testButton02Trigger
            .bind(to: navigateToBookList)
            .disposed(by: disposeBag)

        return Output()
    }
}
