//
//  QuestionHistoryViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift

/// 질문 내역 화면을 위한 ViewModel
/// 사용자의 질문 내역을 관리하고 표시하는 책임을 가짐
final class QuestionHistoryViewModel: ViewModelType {
    // MARK: - Nested Types

    // MARK: - Internal

    /// ViewModel의 입력(Input) 구조체
    struct Input {
        let viewWillAppear: Observable<Void> // 뷰가 나타날 때 트리거되는 옵저버블
        let questionSelected: Observable<QuestionAnswer> // 질문이 선택될 때 트리거되는 옵저버블
        let reachedScrollEnd: Observable<Void> // 스크롤이 끝에 도달했을 때 트리거되는 옵저버블
    }

    /// ViewModel의 출력(Output) 구조체
    struct Output {
        let questions: Driver<[QuestionAnswer]> // 질문 목록을 방출하는 드라이버
    }

    // MARK: - Properties

    /// 메모리 관리를 위한 DisposeBag
    let disposeBag = DisposeBag()

    /// 질문이 선택되었을 때 상세 화면으로 이동하기 위한 Relay
    let navigateToQuestionDetail = PublishRelay<QuestionAnswer>()

    // MARK: - Private

    private var offset = 0
    private let limit = 10

    /// 질문 데이터를 가져오는 Repository (의존성 주입)
    private let questionHistoryRepository: QuestionHistoryRepository

    /// API 요청 중인지 여부를 나타내는 플래그 (중복 호출 방지)
    private var isLoading = false

    /// 질문 목록을 저장하는 BehaviorRelay (초기값은 빈 배열)
    private let fetchedQuestionsRelay = BehaviorRelay<[QuestionAnswer]>(value: [])
    private var questions: [QuestionAnswer] = []

    // MARK: - Lifecycle

    /// 초기화 메서드
    /// - Parameter questionHsitoryRepository: 질문 데이터를 가져오는 Repository
    init(questionHistoryRepository: QuestionHistoryRepository) {
        self.questionHistoryRepository = questionHistoryRepository
    }

    // MARK: - Functions

    /// ViewModel의 주요 로직을 처리하는 transform 함수
    /// - Parameter input: ViewController에서 전달하는 Input 구조체
    /// - Returns: Output 구조체
    func transform(_ input: Input) -> Output {
        // 선택된 질문을 네비게이션 릴레이에 바인딩하여 상세 화면으로 이동할 수 있도록 설정
        input.questionSelected
            .bind(to: navigateToQuestionDetail)
            .disposed(by: disposeBag)

        // 뷰가 새로 나타날 때 데이터 새로 로드
        let initialLoad = input.viewWillAppear
            .withUnretained(self)
            .map { owner, _ in
                owner.questions.removeAll()
                owner.offset = 0
                return owner.fetchQuestions()
            }

        // 스크롤이 끝에 도달했을 때 추가 질문을 로드 (isLoading이 false일 때만 실행)
        let loadMore = input.reachedScrollEnd
            .withUnretained(self)
            .filter { owner, _ in !owner.isLoading }
            .map { owner, _ in
                owner.fetchQuestions()
            }

        Observable.merge(initialLoad, loadMore)
            .bind(to: fetchedQuestionsRelay)
            .disposed(by: disposeBag)

        return Output(
            questions: fetchedQuestionsRelay.asDriver()
        )
    }

    private func fetchQuestions() -> [QuestionAnswer] {
        guard !isLoading else {
            return []
        }
        isLoading = true
        let fetchedQuestions = questionHistoryRepository.fetchQuestions(
            offset: offset,
            limit: limit
        )
        questions += fetchedQuestions
        offset += fetchedQuestions.count
        isLoading = false
        return questions
    }
}
