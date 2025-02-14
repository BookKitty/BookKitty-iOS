//
//  LottieLocalView.swift
//  DesignSystem
//
//  Created by MaxBook on 2/13/25.
//

import Lottie
import SnapKit
import SwiftUI
import UIKit

public enum LottieAnimationName {
    case loadingCircle
    case searchingBooks
    case homeNew
    case homeBooks
}

public class LottieLocalView: UIView {
    // MARK: - Properties

    // MARK: Internal

    private var lottieAnimationView: LottieAnimationView

    // MARK: - Lifecycle

    public init(lottieName: LottieAnimationName) {
        let animationName: String

        switch lottieName {
        case .loadingCircle:
            animationName = "loading-circle"
        case .searchingBooks:
            animationName = "searching-books"
        case .homeNew:
            animationName = "home-new"
        case .homeBooks:
            animationName = "home-books"
        }

        let animationView = LottieAnimationView(name: animationName, bundle: .module)

        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop

        lottieAnimationView = animationView

        super.init(frame: .zero)

        setupSubviews()
        setupProperties()
        setupLayouts()
    }

    // MARK: Public

    override public func layoutSubviews() {
        super.layoutSubviews()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    public func play() {
        lottieAnimationView.play()
    }

    public func stop() {
        lottieAnimationView.stop()
    }
}

// MARK: - Setup UI

extension LottieLocalView {
    private func setupSubviews() {
        addSubview(lottieAnimationView)
    }

    private func setupProperties() {
        backgroundColor = .clear
    }

    private func setupLayouts() {
        lottieAnimationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.center.equalToSuperview()
        }
    }
}
