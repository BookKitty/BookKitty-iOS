//
//  BookDetailViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import RxRelay
import RxSwift

final class BookDetailViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
    }

    struct Output {}

    let disposeBag = DisposeBag()
    let isbnRelay = ReplayRelay<String>.create(bufferSize: 1)

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .withLatestFrom(isbnRelay)
            .bind(onNext: { _ in
                // TODO: CoreData에서 isbn으로 책 정보 가져오기
                // TODO: 가져온 데이터를 Output 스트림으로 전달
            }).disposed(by: disposeBag)

        return Output()
    }
}
