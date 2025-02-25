//
//  OnboardingViewModel.swift
//  BookKitty
//
//  Created by 반성준 on 2/25/25.
//

import Lottie

struct Tutorial {
    let fileName: String
    let title: String
}

class OnboardingViewModel {
    // MARK: - Properties

    var tutorials: [Tutorial] = []
    var onTutorialsLoaded: (() -> Void)?

    // MARK: - Functions

    func loadTutorials() {
        // JSON 파일 이름과 타이틀 설정
        tutorials = [
            Tutorial(fileName: "Tutorial 1", title: "첫 번째 튜토리얼"),
            Tutorial(fileName: "Tutorial 2", title: "두 번째 튜토리얼"),
            Tutorial(fileName: "Tutorial 3", title: "세 번째 튜토리얼"),
            Tutorial(fileName: "Tutorial 4", title: "네 번째 튜토리얼"),
        ]
        onTutorialsLoaded?()
    }
}
