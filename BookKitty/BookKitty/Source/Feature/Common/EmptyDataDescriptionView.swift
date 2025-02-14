//
//  EmptyDataDescriptionView.swift
//  BookKitty
//
//  Created by 전성규 on 2/14/25.
//

import DesignSystem
import UIKit

enum EmptyDataType {
    case question
    case book
}

final class EmptyDataDescriptionView: UIStackView {
    // MARK: - Properties

    private let type: EmptyDataType

    private lazy var titleLabel = TitleLabel(weight: .semiBold).then {
        switch type {
        case .question:
            $0.text = "등록된 질문이 없어요."
        case .book:
            $0.text = "등록된 책이 없어요."
        }
    }

    private lazy var bodyLabel = BodyLabel(weight: .regular).then {
        switch type {
        case .question:
            $0.text = "오른쪽 아래 추가 버튼을 눌러\n 가지고 있는 책을 추가해 보세요."
        case .book:
            $0.text = "오른쪽 아래 추가 버튼을 눌러\n 새로운 질문을 추가해 보세요."
        }

        $0.textAlignment = .center
    }

    // MARK: - Lifecycle

    init(with type: EmptyDataType) {
        self.type = type
        super.init(frame: .zero)

        configureUI()
        configureHierarchy()
//        configureLayout()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    private func configureUI() {
        axis = .vertical
        alignment = .center
        spacing = Vars.spacing12
    }

    private func configureHierarchy() {
        [titleLabel, bodyLabel].forEach { addArrangedSubview($0) }
    }

    private func configureLayout() {
        snp.makeConstraints {
            $0.width.equalTo(200.0)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    EmptyDataDescriptionView(with: .book)
}
