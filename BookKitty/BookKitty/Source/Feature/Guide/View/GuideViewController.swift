//
//  GuideViewController.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import RxCocoa
import RxSwift
import UIKit

/// 사용자에게 앱의 사용 방법을 안내하는 가이드 화면을 담당하는 뷰컨트롤러입니다.
final class GuideViewController: BaseViewController {
    // MARK: - Lifecycle

    /// GuideViewModel을 주입받아 뷰컨트롤러를 초기화합니다.
    /// - Parameter viewModel: 가이드 화면의 비즈니스 로직을 처리할 뷰모델
    init(viewModel: GuideViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    /// 스토리보드를 통한 초기화를 비활성화합니다.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal

    // MARK: - View Configuration

    /// 뷰의 레이아웃을 설정합니다.
    /// 화면에 필요한 UI 요소들의 제약조건을 설정합니다.
    override func configureLayout() {
        // 가이드 화면의 레이아웃 구성 필요
    }

    // MARK: - Data Binding

    /// 뷰모델과 뷰 컨트롤러 간의 데이터 바인딩을 설정합니다.
    /// Input/Output 패턴을 사용하여 데이터 흐름을 관리합니다.
    override func bind() {
        // Input 설정
        let input = GuideViewModel.Input(
            guideInput: PublishRelay<Void>().asObservable()
        )

        // Output 변환
        let output = viewModel.transform(input)

        // 가이드 데이터 출력 구독
        output.guideOutput
            .withUnretained(self)
            .subscribe { _ in
                // 가이드 데이터 표시 로직 구현
            }
            .disposed(by: disposeBag)

        // 에러 처리
        output.guideErrorOutput
            .withUnretained(self)
            .subscribe { _ in
                // 사용자에게 적절한 에러 메시지 표시
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Private

    /// 가이드 화면의 비즈니스 로직을 처리하는 뷰모델
    private let viewModel: GuideViewModel
}
