//
//  GuideViewModel.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import Foundation
import RxRelay
import RxSwift

/// RxSwift를 사용한 MVVM 패턴의 예시를 보여주는 ViewModel입니다
/// 이 ViewModel은 다음과 같은 내용을 설명합니다:
/// 1. Input과 Output 구조 설계 방법
/// 2. Input을 Output으로 변환하는 방법
/// 3. 에러 처리 방법
final class GuideViewModel: ViewModelType {
    private let addBookService: AddBookServiceable
    private let bookRepository: DefaultBookRepository

    init(addBookService: AddBookServiceable, bookRepository: DefaultBookRepository) {
        self.addBookService = addBookService
        self.bookRepository = bookRepository
    }

    /// Input 구조체는 View로부터 ViewModel이 받을 수 있는 모든 입력을 정의합니다
    struct Input {
        /// 비즈니스 로직을 트리거할 수 있는 예시 입력
        var guideInput: Observable<Void>
    }

    /// Output 구조체는 ViewModel이 View에게 전달할 수 있는 모든 출력을 정의합니다
    struct Output {
        /// View가 관찰할 수 있는 메인 출력 스트림
        var guideOutput: Observable<Void>
        /// 에러 처리와 표시를 위한 에러 출력 스트림
        var guideErrorOutput: PublishRelay<Error>
    }

    /// 구독을 관리하기 위한 DisposeBag
    let disposeBag = DisposeBag()

    /// 입력 이벤트를 출력 이벤트로 변환합니다
    /// - Parameter input: 모든 가능한 입력을 포함하는 Input 구조체
    /// - Returns: 모든 가능한 출력을 포함하는 Output 구조체
    func transform(_ input: Input) -> Output {
        // 에러 처리를 위한 relay 생성
        let guideErrorOutput = PublishRelay<Error>()

        // 입력을 출력으로 변환
        let guideOutput = input.guideInput
            .map { _ in
                // 일반적으로 여기서 수행하는 작업:
                // 1. 입력 데이터에 비즈니스 로직 적용
                // 2. API 호출 또는 데이터베이스 작업 수행
                // 3. View에서 사용할 수 있는 형태로 데이터 변환
                // 4. 에러 발생 시 guideErrorOutput.accept(error) 호출
            }
            .asObservable()

        return Output(
            guideOutput: guideOutput,
            guideErrorOutput: guideErrorOutput
        )
    }
}
