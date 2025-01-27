//
//  TabBarViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
//

import Foundation
import RxRelay
import RxSwift

final class TabBarViewModel: ViewModelType {
    struct Input {}

    struct Output {}

    var disposeBag = DisposeBag()

    func transform(_: Input) -> Output {
        Output()
    }
}
