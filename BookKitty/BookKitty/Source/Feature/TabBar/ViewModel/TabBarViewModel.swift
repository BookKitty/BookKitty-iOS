//
//  TabBarViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/30/25.
//

import Foundation
import RxRelay
import RxSwift

final class TabBarViewModel: ViewModelType {
    struct Input {}

    struct Output {}

    let disposeBag = DisposeBag()

    func transform(_: Input) -> Output {
        Output()
    }
}
