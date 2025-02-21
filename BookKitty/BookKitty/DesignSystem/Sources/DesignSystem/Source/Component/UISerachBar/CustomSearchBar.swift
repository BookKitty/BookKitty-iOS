//
//  CustomSearchBar.swift
//  DesignSystem
//
//  Created by 권승용 on 2/21/25.
//

import SnapKit
import Then
import UIKit

public protocol CustomSearchBarDelegate: AnyObject {
    func searchBarSearchButtonClicked(_ searchBar: CustomSearchBar)
}

public final class CustomSearchBar: UIView {
    // MARK: - Properties

    public weak var delegate: CustomSearchBarDelegate?

    private let textField = UITextField().then {
        $0.overrideUserInterfaceStyle = .light
        $0.backgroundColor = Colors.background1
        $0.placeholder = "검색할 책의 제목을 입력해 주세요"
        $0.font = Fonts.bodyRegular
        $0.borderStyle = .none
        $0.returnKeyType = .search
        $0.clearButtonMode = .whileEditing
    }

    private let searchImageView = UIImageView().then {
        $0.image = UIImage(resource: .searchIcon)
        $0.contentMode = .scaleAspectFit
        $0.tintColor = Colors.fontSub2
    }

    // MARK: - Computed Properties

    public var searchText: String? {
        textField.text
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureBackground()
        configureHierarchy()
        configureLayout()
        configureDelegates()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    // MARK: - Setup

    private func configureBackground() {
        backgroundColor = Colors.background1
        layer.cornerRadius = Vars.radiusMini
        clipsToBounds = true
    }

    private func configureHierarchy() {
        [
            searchImageView,
            textField,
        ].forEach { addSubview($0) }
    }

    private func configureLayout() {
        searchImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Vars.spacing8)
            make.verticalEdges.equalToSuperview().inset(Vars.spacing12)
            make.size.equalTo(Vars.spacing20)
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(searchImageView.snp.trailing).offset(Vars.spacing12)
            make.centerY.equalTo(searchImageView.snp.centerY)
            make.trailing.equalToSuperview().inset(Vars.spacing8)
        }
    }

    private func configureDelegates() {
        textField.delegate = self
    }
}

// MARK: - UITextFieldDelegate

extension CustomSearchBar: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.searchBarSearchButtonClicked(self)
        return true
    }
}

@available(iOS 17.0, *)
#Preview {
    CustomSearchBar(frame: .zero)
}
