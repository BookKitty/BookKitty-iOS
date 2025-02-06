//
//  BookDetailViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift

struct TestBookModel: Hashable {
    let isbn: String
    let title: String
    let author: String
    let publisher: String
    let price: String
    let description: String
    let bookInfoLink: String
    let imageLink: String
    let createdAt: Date
    let pubdate: String
    let isOwned: Bool
}

final class BookDetailViewModel: ViewModelType {
    // MARK: Internal

    struct Input {
        let viewDidLoad: Observable<Void>
        let leftBarButtonTapTrigger: Observable<Void>
        let popupViewConfirmButtonTapTrigger: Observable<Void>
    }

    struct Output {
        let model: PublishRelay<TestBookModel>
    }

    let disposeBag = DisposeBag()
    let isbnRelay = ReplayRelay<String>.create(bufferSize: 1)
    let modelRelay = ReplayRelay<TestBookModel>.create(bufferSize: 1) // TODO: TestBookModel -> Book
    let navigate = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .withLatestFrom(modelRelay)
            .withUnretained(self) // Test
            .map { owner, _ in owner.textBookDtailModel } // Test
            .bind(to: model)
            .disposed(by: disposeBag)

        // Test
        input.viewDidLoad
            .withUnretained(self)
            .map { owner, _ in owner.textBookDtailModel }
            .bind(to: model)
            .disposed(by: disposeBag)

        input.leftBarButtonTapTrigger
            .bind(to: navigate)
            .disposed(by: disposeBag)

        input.popupViewConfirmButtonTapTrigger
            .bind(to: navigate) // add, remove
            .disposed(by: disposeBag)

        return Output(model: model)
    }

    // MARK: Private

    private let model = PublishRelay<TestBookModel>() // TODO: TestBookModel -> Book

    private let textBookDtailModel = TestBookModel( // Test
        isbn: "123412431234",
        title: "Nudge",
        author: "리처드 탈러, 캐스 선트타인",
        publisher: "리더스북",
        price: "20,000",
        description:
        """
        “넛지 헬스케어”는 사람들이 무의식적으로 더 건강한 선택을 하도록 유도하는 넛지(Nudge) 이론을 기반으로 한 혁신적인 헬스케어 전략을 다룬 책입니다.
        이 책은 단순히 운동과 식단 조절을 강조하는 기존의 건강 관리 방식에서 벗어나, 인간의 행동 심리를 활용하여 자연스럽고 지속 가능한 건강 습관을 형성하는 방법을 탐구합니다.
        넛지 이론은 사람들이 강요나 제한 없이도 보다 나은 선택을 하도록 돕는 데 초점을 맞추고 있으며, 이를 통해 헬스케어 분야에서도 효과적인 변화를 이끌어낼 수 있음을 강조합니다.
        저자는 다양한 연구 사례와 실험 결과를 바탕으로, 작은 변화가 우리의 건강 행동에 미치는 영향을 분석하며, 실생활에서 쉽게 적용할 수 있는 구체적인 실천 방안을 제시합니다.
        또한, 개인뿐만 아니라 기업, 정부, 의료 기관 등 다양한 조직이 넛지 기법을 활용하여 건강 증진을 촉진할 수 있는 방법도 설명하며, 보다 넓은 사회적 차원에서 웰빙을 증진할 수 있는 가능성을 탐색합니다. 
        이 책은 건강을 지키는 것이 어렵고 부담스러운 것이 아니라, 일상 속에서 자연스럽게 유도될 수 있다는 점을 강조하며, 보다 나은 삶을 위한 실용적인 통찰과 전략을 제공합니다.
        """,
        bookInfoLink: "",
        imageLink: "https://shopping-phinf.pstatic.net/main_4718969/47189696637.20240421070849.jpg",
        createdAt: Date(),
        pubdate: "1999년 01월 01일 출판",
        isOwned: true
    )
}
