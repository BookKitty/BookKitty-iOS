//
//  LoadingCircleView.swift
//  BookKitty
//
//  Created by 권승용 on 2/14/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

final class LoadingCircleView: UIView {
    // MARK: - Properties

    let lottieView = LottieLocalView(lottieName: .loadingCircle)

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureBackground()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    func play() {
        lottieView.play()
    }

    func stop() {
        lottieView.stop()
    }

    private func configureHierarchy() {
        addSubview(lottieView)
    }

    private func configureLayout() {
        lottieView.snp.makeConstraints { make in
            make.size.equalTo(Vars.viewSizeMedium)
            make.center.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.size.equalTo(Vars.viewSizeLarge)
        }
    }

    private func configureBackground() {
        backgroundColor = Colors.brandSub
        layer.cornerRadius = Vars.radiusLarge
        clipsToBounds = true
    }
}
