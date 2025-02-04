//
//  TabBarViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/30/25.
//

import Foundation
import RxRelay
import RxSwift

/// 탭 바에서 발생하는 이벤트를 관리하는 ViewModel
final class TabBarViewModel: ViewModelType {
    struct Input {
        /// 플로팅 메뉴에서 선택된 항목 스트림
        var selectedFloatingItem: Observable<FloatingMenuItemType>
    }

    struct Output {}

    let disposeBag = DisposeBag()

    let navigateToAddBook = PublishRelay<Void>()
    let navigateToAddQuestion = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.selectedFloatingItem
            .filter { $0 == .addBook }
            .map { _ in }
            .bind(to: navigateToAddBook)
            .disposed(by: disposeBag)

        input.selectedFloatingItem
            .filter { $0 == .addQuestion }
            .map { _ in }
            .bind(to: navigateToAddQuestion)
            .disposed(by: disposeBag)

        return Output()
    }
}
