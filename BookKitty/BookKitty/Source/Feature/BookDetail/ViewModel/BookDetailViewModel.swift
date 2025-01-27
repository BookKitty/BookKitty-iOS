//
//  BookDetailViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import RxSwift

final class BookDetailViewModel: ViewModelType {
    struct Input {}

    struct Output {}

    let disposeBag = DisposeBag()

    func transform(_: Input) -> Output {
        Output()
    }
}
