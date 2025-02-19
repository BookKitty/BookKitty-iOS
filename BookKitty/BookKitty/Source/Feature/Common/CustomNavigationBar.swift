//
//  CustomNavigationBar.swift
//  BookKitty
//
//  Created by 전성규 on 2/11/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

/// 우측 네비게이션 버튼 타입 정의
enum RightBarButtonType: String {
    case delete = "삭제"
    case add = "등록"
    case input = "제목 입력하기"
}

/// 앱 전반에서 재사용할 수 있는 커스텀 네비게이션 바
/// - `backButtonTapped`: 뒤로가기 버튼 이벤트 방출
/// - `rightButtonTapped`: 우측 버튼 이벤트 방출
final class CustomNavigationBar: UIView {
    // MARK: - Properties

    let backButtonTapped = PublishRelay<Void>()
    let rightButtonTapped = PublishRelay<Void>()

    private let disposeBag = DisposeBag()

    private let backButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.title = "돌아가기"
        config.image = UIImage(systemName: "chevron.left")
        config.imagePlacement = .leading
        config.imagePadding = 5.0
        config.contentInsets = .zero
        config.baseForegroundColor = Colors.brandSub

        $0.configuration = config
    }

    private let titleLabel = UILabel().then {
        $0.font = Fonts.titleExtraBold
        $0.textColor = Colors.fontMain
    }

    private lazy var rightButton = UIButton()

    private let separator = UIView().then {
        $0.backgroundColor = Colors.background1
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureHierarchy()
        configureLayout()
        bindBackButton()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    /// 우측 네비게이션 버튼을 설정하는 메서드
    /// - Parameter type: `RightBarButtonType`(삭제, 등록, 제목 입력)
    func setupRightBarButton(with type: RightBarButtonType) {
        rightButton.setTitle(type.rawValue, for: .normal)
        rightButton.setTitleColor(Colors.brandSub, for: .normal)

        addSubview(rightButton)

        rightButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(Vars.spacing8)
            $0.verticalEdges.equalToSuperview()
        }

        rightButton.rx.tap
            .bind(to: rightButtonTapped)
            .disposed(by: disposeBag)
    }

    func setupTitle(with title: String) {
        titleLabel.text = title

        addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func configureHierarchy() {
        [backButton, separator].forEach { addSubview($0) }
    }

    private func configureLayout() {
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(Vars.spacing8)
            $0.verticalEdges.equalToSuperview()
        }

        separator.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(1.0)
        }
    }

    private func bindBackButton() {
        backButton.rx.tap
            .bind(to: backButtonTapped)
            .disposed(by: disposeBag)
    }
}

@available(iOS 17.0, *)
#Preview {
    CustomNavigationBar()
}
