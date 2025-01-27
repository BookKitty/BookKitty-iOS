//
//  HomeViewController.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import UIKit

class HomeViewController: BaseViewController {
    // MARK: Internal

    override func configureHierarchy() {
        view.addSubview(testLabel)
    }

    override func configureLayout() {
        testLabel.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    // MARK: Private

    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "P-001"
        label.font = .systemFont(ofSize: 30.0, weight: .bold)

        return label
    }()
}

@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
