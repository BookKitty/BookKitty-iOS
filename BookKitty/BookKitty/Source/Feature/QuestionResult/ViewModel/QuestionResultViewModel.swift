//
//  QuestionResultViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 2/3/25.
//

import Foundation
import RxCocoa
import RxSwift

final class QuestionResultViewModel: ViewModelType {
    // MARK: Internal

    struct Input {
        let viewDidLoad: Observable<Void>
        let bookThumbnailButtonTapTigger: Observable<String>
        let confirmButtonTrigger: Observable<Void>
    }

    struct Output {
        let question: Driver<String>
    }

    let disposeBag = DisposeBag()
    /// 질문 내용을 저장하는 Relay
    let questionRelay = ReplayRelay<String>.create(bufferSize: 1)
    /// 책 상세 화면으로 이동하는 이벤트
    let navigateToBookDetail = PublishRelay<String>()
    /// 루트 화면으로 이동하는 이벤트
    let navigateToRoot = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .withLatestFrom(questionRelay)
            .bind(to: requestQuestion)
            .disposed(by: disposeBag)

        input.bookThumbnailButtonTapTigger
            .bind(to: navigateToBookDetail)
            .disposed(by: disposeBag)

        input.confirmButtonTrigger
            .bind(to: navigateToRoot)
            .disposed(by: disposeBag)

        return Output(question: requestQuestion.asDriver(onErrorJustReturn: ""))
    }

    // MARK: Private

    private let requestQuestion = PublishRelay<String>()
}
