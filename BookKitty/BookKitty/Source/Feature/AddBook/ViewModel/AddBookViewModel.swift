import BookMatchKit
import Foundation
import RxCocoa
import RxSwift
import UIKit
import Vision

final class AddBookViewModel: ViewModelType {
    // MARK: - Nested Types

    struct Input {
        let captureButtonTapped: Observable<Void>
        let leftBarButtonTapTrigger: Observable<Void>
    }

    struct Output {
        let error: Observable<Error> // 에러 처리
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    // MARK: - Private

    let navigateBackRelay = PublishRelay<Void>()
    let navigateToReviewRelay = PublishRelay<[Book]>()
    let bookListRelay = BehaviorRelay<[Book]>(value: []) // 사진이 캡쳐된 이후, 캡처본에 대한 데이터 흐름을 담당하는 스트림입니다

    private let errorRelay = PublishRelay<Error>()
    private let capturedTextDatasRelay = BehaviorRelay<[String]>(value: [])

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.leftBarButtonTapTrigger
            .bind(to: navigateBackRelay)
            .disposed(by: disposeBag)

        input.captureButtonTapped
            .subscribe(onNext: {
                // TODO: VC에서 가져온 데이터 기반으로 OCR 데이터 Neo님과 상의해주세요.
                // TODO: 정상적으로 책 데이터 추출되면 BookRepository로 책 추가한 이후에 navigateBackRelay.accept(()) 해주세요.
                // TODO: 정삭적으로 책 데이터를 추출하지 못하면 Output으로 스트림 구축해서 accept 해주세요.
            }).disposed(by: disposeBag)

        return Output(
            error: errorRelay.asObservable()
        )
    }

    /// AddBaseViewController 내부 handleCapturedImage 메서드 내부에서 해당 메서드 호출
    func handleCapturedImage(from image: UIImage) {
        recognizeText(from: image) { [weak self] recognizedText in
            let bookTitles = recognizedText.components(separatedBy: "\n").filter { !$0.isEmpty }
            let bookMatchKit = BookMatchKit(
                naverClientId: "emT6GVaVUMCyF7CSqifr",
                naverClientSecret: "eIjwLMH9ZS"
            )
            self?.capturedTextDatasRelay.accept(bookTitles)
        }
    }

    private func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let recognizedText = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            DispatchQueue.main.async {
                completion(recognizedText)
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
}
