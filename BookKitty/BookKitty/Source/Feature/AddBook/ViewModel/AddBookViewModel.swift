//
//  AddBookViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/31/25.
//

import Foundation
import RxRelay
import RxSwift

final class AddBookViewModel: ViewModelType {
    struct Input {
        var testButtonTigger: Observable<Void>
    }

    struct Output {}

    let disposeBag = DisposeBag()

    let navigateToReviewAddBook = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.testButtonTigger
            .bind(to: navigateToReviewAddBook)
            .disposed(by: disposeBag)

        return Output()
    }
}
