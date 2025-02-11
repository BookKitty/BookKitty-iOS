//
//  LottieView.swift
//  DesignSystem
//
//  Created by MaxBook on 2/09/25.
//

import Lottie
import SnapKit
import SwiftUI
import UIKit

public class LottieView: UIView {
    // MARK: - Properties

    // MARK: Internal

    let imageLink: String
    let animationView = LottieAnimationView()

    // MARK: - Lifecycle

    public init(imageLink: String = "https://cdn.lottielab.com/l/6XZaTv8W8WJzxC.json") {
        self.imageLink = imageLink
        super.init(frame: .zero)

        setupSubviews()
        setupProperties()
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
}

// MARK: - Setup UI

extension LottieView {
    private func setupSubviews() {
        addSubview(animationView)
    }

    private func setupProperties() {
        backgroundColor = .clear

        guard let url = URL(string: imageLink) else {
            return
        }

        LottieAnimation.loadedFrom(
            url: url,
            closure: { [weak self] animation in
                self?.animationView.animation = animation
                self?.animationView.play()
            }
        )

        animationView.loopMode = .loop
    }

    private func setupLayouts() {
        animationView.frame = bounds
    }
}
