//
//  OnboardingViewController.swift
//  BookKitty
//
//  Created by 반성준 on 2/25/25.
//

import DesignSystem
import Lottie
import UIKit

class OnboardingViewController: UIViewController {
    // MARK: - Properties

    var onFinish: (() -> Void)?

    private let scrollView = UIScrollView()
    private let pageControl = UIStackView()
    private let nextButton = UIButton(type: .system)
    private let viewModel = OnboardingViewModel()
    private var pageIndicators: [UIView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadTutorials()
    }

    // MARK: - Functions

    private func setupUI() {
        view.backgroundColor = .white

        // ✅ DesignSystem에서 색상 가져오기
        let brandSubColor = Colors.brandSub
        let brandSub2Color = Colors.brandSub2

        // ScrollView 설정
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self

        // PageControl (원형 Indicator)
        pageControl.axis = .horizontal
        pageControl.alignment = .center
        pageControl.distribution = .fillEqually
        pageControl.spacing = 10

        for i in 0 ..< 4 {
            let dot = UIView()
            dot.backgroundColor = i == 0 ? brandSubColor : brandSub2Color
            dot.layer.cornerRadius = 6 // ✅ 원형 유지 (12 × 12)
            dot.clipsToBounds = true
            dot.translatesAutoresizingMaskIntoConstraints = false
            pageControl.addArrangedSubview(dot)
            pageIndicators.append(dot)

            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 12),
                dot.heightAnchor.constraint(equalToConstant: 12),
            ])
        }

        // "다음" 버튼 설정
        nextButton.setTitle("다음", for: .normal)
        nextButton.backgroundColor = brandSubColor
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        nextButton.layer.cornerRadius = 10
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)

        // ✅ 계층 구조 추가
        view.addSubview(scrollView)
        view.addSubview(nextButton)
        view.addSubview(pageControl)

        // ✅ 버튼과 원형 인디케이터를 최상위로 올리기
        view.bringSubviewToFront(nextButton)
        view.bringSubviewToFront(pageControl)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ✅ 원형 인디케이터 높이 추가 (보이도록)
            pageControl.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -30),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.widthAnchor.constraint(equalToConstant: 80),
            pageControl.heightAnchor.constraint(equalToConstant: 12), // ✅ 높이 추가

            nextButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -40
            ), // ✅ 더 아래로 배치
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 354),
            nextButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func bindViewModel() {
        viewModel.onTutorialsLoaded = { [weak self] in
            self?.createTutorialViews()
        }
    }

    private func createTutorialViews() {
        for (index, tutorial) in viewModel.tutorials.enumerated() {
            let pageView = UIView()

            let animationView = LottieAnimationView()
            animationView.animation = LottieAnimation.named(tutorial.fileName)
            animationView.loopMode = .loop
            animationView.play()

            pageView.addSubview(animationView)

            animationView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                animationView.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
                animationView.topAnchor.constraint(equalTo: pageView.topAnchor, constant: 80),
                animationView.widthAnchor.constraint(
                    equalTo: pageView.widthAnchor,
                    multiplier: 1.0
                ),
                animationView.heightAnchor.constraint(equalToConstant: 523),
            ])

            scrollView.addSubview(pageView)
            pageView.frame = CGRect(
                x: CGFloat(index) * view.frame.width,
                y: 0,
                width: view.frame.width,
                height: view.frame.height
            )
        }

        scrollView.contentSize = CGSize(
            width: view.frame.width * CGFloat(viewModel.tutorials.count),
            height: view.frame.height
        )

        updatePageControl()
    }

    /// ✅ "다음" 버튼을 눌렀을 때 페이지 이동
    @objc
    private func nextButtonTapped() {
        let brandSubColor = Colors.brandSub

        let currentPage = Int(scrollView.contentOffset.x / view.frame.width)
        let nextPage = currentPage + 1

        if nextPage < viewModel.tutorials.count {
            let offset = CGPoint(x: CGFloat(nextPage) * view.frame.width, y: 0)
            scrollView.setContentOffset(offset, animated: true)
        } else {
            // ✅ 마지막 페이지에서는 온보딩 완료 처리
            UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
            onFinish?()
        }
    }

    private func updatePageControl() {
        let brandSubColor = Colors.brandSub
        let brandSub2Color = Colors.brandSub2

        for (index, dot) in pageIndicators.enumerated() {
            dot.backgroundColor = index == Int(scrollView.contentOffset.x / view.frame.width) ?
                brandSubColor : brandSub2Color
        }
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_: UIScrollView) {
        updatePageControl()
    }
}
