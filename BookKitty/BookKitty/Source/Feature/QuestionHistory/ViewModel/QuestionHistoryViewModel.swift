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
    // MARK: Lifecycle

    /// 초기화 메서드
    /// - Parameter questionRepository: 질문 데이터를 가져오는 Repository
    init(questionRepository: QuestionHistoryRepository) {
        self.questionRepository = questionRepository
    }

    // MARK: Internal

    /// ViewModel의 입력(Input) 구조체
    struct Input {
        let viewDidLoad: Observable<Void> // 뷰가 로드될 때 트리거되는 옵저버블
        let questionSelected: Observable<Question> // 질문이 선택될 때 트리거되는 옵저버블
        let reachedScrollEnd: Observable<Void> // 스크롤이 끝에 도달했을 때 트리거되는 옵저버블
    }

    /// ViewModel의 출력(Output) 구조체
    struct Output {
        let questions: Driver<[Question]> // 질문 목록을 방출하는 드라이버
    }

    /// 메모리 관리를 위한 DisposeBag
    let disposeBag = DisposeBag()

    /// 질문이 선택되었을 때 상세 화면으로 이동하기 위한 Relay
    let navigateToQuestionDetail = PublishRelay<Question>()

    /// ViewModel의 주요 로직을 처리하는 transform 함수
    /// - Parameter input: ViewController에서 전달하는 Input 구조체
    /// - Returns: Output 구조체
    func transform(_ input: Input) -> Output {
        // 선택된 질문을 네비게이션 릴레이에 바인딩하여 상세 화면으로 이동할 수 있도록 설정
        input.questionSelected
            .bind(to: navigateToQuestionDetail)
            .disposed(by: disposeBag)

        // 뷰가 로드될 때 질문 데이터를 가져와서 fetchedQuestions에 저장
        input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.questionRepository.fetchQuestions(offset: owner.offset, limit: owner.limit)
            }
            .bind(to: fetchedQuestions)
            .disposed(by: disposeBag)

        // 스크롤이 끝에 도달했을 때 추가 질문을 로드 (isLoading이 false일 때만 실행)
        input.reachedScrollEnd
            .withUnretained(self)
            .filter { owner, _ in !owner.isLoading } // 현재 로딩 중이 아닐 경우에만 실행
            .flatMapLatest { owner, _ in
                owner.isLoading = true // API 호출 전 로딩 상태를 true로 설정
                owner.offset += owner.limit
                return owner.questionRepository.fetchQuestions(
                    offset: owner.offset,
                    limit: owner.limit
                )
            }
            .do(onCompleted: { [weak self] in self?.isLoading = false }) // API 호출이 끝나면 로딩 상태 해제
            .bind(to: fetchedQuestions)
            .disposed(by: disposeBag)

        return Output(
            questions: fetchedQuestions.asDriver() // 질문 목록을 드라이버 형태로 반환하여 UI에서 활용 가능하도록 설정
        )
    }

    // MARK: Private

    private var offset = 0
    private let limit = 10

    /// 질문 데이터를 가져오는 Repository (의존성 주입)
    private let questionRepository: QuestionHistoryRepository

    /// API 요청 중인지 여부를 나타내는 플래그 (중복 호출 방지)
    private var isLoading = false

    /// 질문 목록을 저장하는 BehaviorRelay (초기값은 빈 배열)
    private let fetchedQuestions = BehaviorRelay<[Question]>(value: [])
}
