//
//  QuestionDetailViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift

final class QuestionDetailViewModel: ViewModelType {
    // MARK: Lifecycle

    init(questionAnswer: QuestionAnswer, questionHistoryRepository: QuestionHistoryRepository) {
        self.questionAnswer = questionAnswer
        self.questionHistoryRepository = questionHistoryRepository
    }

    // MARK: Internal

    struct Input {
        let viewDidLoad: Observable<Void>
        let deleteButtonTapped: Observable<Void>
        let bookTapped: Observable<Book>
    }

    struct Output {
        let questionDate: Driver<String>
        let userQuestion: Driver<String>
        let recommendationReason: Driver<String>
        let recommendedBooks: Driver<[SectionOfBook]>
    }

    let disposeBag = DisposeBag()
    let navigateToBookDetail = PublishRelay<Book>()
    let dismissViewController = PublishRelay<Void>()

    // 뒤로가기도 코디네이터에서 navigation 하는지?

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .withUnretained(self)
            .subscribe(onNext: { _ in
                let qna = self.questionAnswer
                self.questionDateRelay.accept(DateFormatHandler().dateString(from: qna.createdAt))
                self.userQuestionRelay.accept(qna.userQuestion)
                self.recommendationReasonRelay.accept(qna.gptAnswer)
                let sectionOfBooks = SectionOfBook(items: qna.recommendedBooks)
                self.recommendedBooksRelay.accept([sectionOfBooks])
            })
            .disposed(by: disposeBag)

        input.deleteButtonTapped
            .withUnretained(self)
            .subscribe { _ in
                self.questionHistoryRepository.deleteQuestionAnswer(uuid: self.questionAnswer.id)
                self.dismissViewController.accept(())
            }
            .disposed(by: disposeBag)

        input.bookTapped
            .bind(to: navigateToBookDetail)
            .disposed(by: disposeBag)

        return Output(
            questionDate: questionDateRelay.asDriver(),
            userQuestion: userQuestionRelay.asDriver(),
            recommendationReason: recommendationReasonRelay.asDriver(),
            recommendedBooks: recommendedBooksRelay.asDriver()
        )
    }

    // MARK: Private

    private let questionHistoryRepository: QuestionHistoryRepository

    private let questionAnswer: QuestionAnswer

    private let questionDateRelay = BehaviorRelay<String>(value: "")
    private let userQuestionRelay = BehaviorRelay<String>(value: "")
    private let recommendationReasonRelay = BehaviorRelay<String>(value: "")
    private let recommendedBooksRelay = BehaviorRelay<[SectionOfBook]>(value: [])
}
