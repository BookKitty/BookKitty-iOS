//
//  QuestionDetailViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import LogKit
import RxCocoa
import RxRelay
import RxSwift

final class QuestionDetailViewModel: ViewModelType {
    // MARK: - Nested Types

    // MARK: - Internal

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let deleteButtonTapped: Observable<Void>
        let backButtonTapped: Observable<Void>
        let bookTapped: Observable<Book>
    }

    struct Output {
        let questionDate: Driver<String>
        let userQuestion: Driver<String>
        let recommendationReason: Driver<String>
        let recommendedBooks: Driver<[SectionOfBook]>
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let navigateToBookDetail = PublishRelay<Book>()
    let dismissViewController = PublishRelay<Void>()

    // MARK: - Private

    private let questionHistoryRepository: QuestionHistoryRepository

    private let questionAnswer: QuestionAnswer

    private let questionDateRelay = BehaviorRelay<String>(value: "")
    private let userQuestionRelay = BehaviorRelay<String>(value: "")
    private let recommendationReasonRelay = BehaviorRelay<String>(value: "")
    private let recommendedBooksRelay = BehaviorRelay<[SectionOfBook]>(value: [])

    // MARK: - Lifecycle

    init(questionAnswer: QuestionAnswer, questionHistoryRepository: QuestionHistoryRepository) {
        self.questionAnswer = questionAnswer
        self.questionHistoryRepository = questionHistoryRepository
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(with: self, onNext: { owner, _ in
                let qna = owner.questionAnswer
                owner.questionDateRelay.accept(DateFormatHandler().dateString(from: qna.createdAt))
                owner.userQuestionRelay.accept(qna.userQuestion)
                owner.recommendationReasonRelay.accept(qna.gptAnswer)
                let sectionOfBooks = SectionOfBook(items: qna.recommendedBooks)
                owner.recommendedBooksRelay.accept([sectionOfBooks])
            })
            .disposed(by: disposeBag)

        input.viewWillAppear
            .skip(1)
            .withUnretained(self)
            .map { owner, _ in
                if let updatedQnA = owner.questionHistoryRepository
                    .fetchQuestion(by: owner.questionAnswer.id) {
                    let books = updatedQnA.recommendedBooks
                    return [SectionOfBook(items: books)]
                } else {
                    return [SectionOfBook(items: owner.questionAnswer.recommendedBooks)]
                }
            }
            .bind(to: recommendedBooksRelay)
            .disposed(by: disposeBag)

        input.deleteButtonTapped
            .subscribe(with: self) { owner, _ in
                if !owner.questionHistoryRepository
                    .deleteQuestionAnswer(uuid: owner.questionAnswer.id) {
                    LogKit.error("질문 내역 삭제 실패!")
                }
                owner.dismissViewController.accept(())
            }
            .disposed(by: disposeBag)

        input.backButtonTapped
            .bind(to: dismissViewController)
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
}
