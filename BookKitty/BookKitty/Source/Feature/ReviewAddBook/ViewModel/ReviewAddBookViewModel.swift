//
//  ReviewAddBookViewModel.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import RxCocoa
import RxSwift

final class ReviewAddBookViewModel: ViewModelType {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(initialBookList _: [String]) {
        // 필요하면 여기에서 초기 데이터 설정 가능
    }

    // MARK: Internal

    // MARK: - Input & Output

    struct Input {
        let confirmButtonTapped: Observable<Void>
    }

    struct Output {
        let navigateToBookList: Observable<Void>
    }

    let disposeBag = DisposeBag() // ✅ 접근 수준을 `internal`로 변경하여 프로토콜 요구사항 충족

    /// ✅ `navigateToBookList`를 `internal`로 선언하여 `AddBookCoordinator`에서 접근 가능하도록 변경
    let navigateToBookListRelay = PublishRelay<Void>()

    // MARK: - Transform Function

    func transform(_ input: Input) -> Output {
        input.confirmButtonTapped
            .bind(to: navigateToBookListRelay)
            .disposed(by: disposeBag)

        return Output(navigateToBookList: navigateToBookListRelay.asObservable())
    }
}
