//
//  BaseViewController.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import DesignSystem
import FirebaseAnalytics
import RxCocoa
import RxRelay
import RxSwift
import UIKit

/// BaseViewController는 모든 ViewController의 기본이 되는 클래스입니다.
/// RxSwift를 사용하기 위한 disposeBag과 기본적인 UI 설정 메서드들을 포함하고 있습니다.
class BaseViewController: UIViewController {
    // MARK: - Properties

    // MARK: - Internal

    /// RxSwift의 메모리 관리를 위한 DisposeBag입니다.
    let disposeBag = DisposeBag()
    let viewDidLoadRelay = PublishRelay<Void>()
    let viewWillAppearRelay = PublishRelay<Void>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureNavItem()
        configureHierarchy()
        configureLayout()
        bind()
        viewDidLoadRelay.accept(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        recordScreenView()
    }

    // MARK: - Functions

    /// 뷰 컨트롤러의 배경색을 설정하는 메서드입니다.
    /// 하위 클래스에서 필요에 따라 오버라이드하여 구현합니다.
    func configureBackground() {
        view.backgroundColor = Colors.background0
    }

    /// 네비게이션 아이템을 설정하는 메서드입니다.
    /// 하위 클래스에서 필요에 따라 오버라이드하여 구현합니다.
    func configureNavItem() {}

    /// 뷰 계층 구조를 설정하는 메서드입니다.
    /// 하위 클래스에서 필요에 따라 오버라이드하여 구현합니다.
    func configureHierarchy() {}

    /// 뷰의 레이아웃을 설정하는 메서드입니다.
    /// 하위 클래스에서 필요에 따라 오버라이드하여 구현합니다.
    func configureLayout() {}

    /// RxSwift 바인딩을 설정하는 메서드입니다.
    /// 하위 클래스에서 필요에 따라 오버라이드하여 구현합니다.
    func bind() {}
}

extension BaseViewController {
    func recordScreenView() {
        guard let screenName = title else {
            return
        }
        let screenClass = classForCoder.description()

        // [START set_current_screen]
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: screenName,
                AnalyticsParameterScreenClass: screenClass,
            ]
        )
        // [END set_current_screen]
    }
}
