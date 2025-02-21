//
//  MyLibraryViewModelTests.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

@testable import BookKitty
import RxSwift
import Testing

/// 테스트 스위트 정의: 테스트가 직렬화되어 실행되도록 설정
@Suite(.serialized)
@MainActor
struct MyLibraryViewModelTests {
    // MARK: - Properties

    // MARK: - Private

    private let repository = MockBookRepository() // MockBookRepository 인스턴스 생성

    // MARK: - Functions

    // MARK: - Internal

    /// 뷰가 로드될 때 책 목록이 방출되는지 테스트
    @Test("viewDidLoad -> Book 목록 방출")
    func test_viewDidLoad() async {
        let vm = MyLibraryViewModel(bookRepository: repository)

        // ViewModel 입력 설정
        let input = MyLibraryViewModel.Input(
            viewWillAppear: Observable.just(()), // 뷰 로드 이벤트
            bookTapped: Observable<Book>.empty(), // 책 탭 이벤트 (현재 비어있음)
            reachedScrollEnd: Observable<Void>.empty() // 스크롤 끝 이벤트 (현재 비어있음)
        )

        // 입력을 변환하여 출력 값을 얻음
        let output = vm.transform(input)
        // 책 목록이 방출될 때까지 기다림
        for await value in output.bookList.values {
            #expect(value[0].items == repository.mockBookList) // 방출된 값이 예상한 책 목록과 같은지 확인
            break
        }
    }

    /// 책이 탭되었을 때 상세 화면으로 이동하는지 테스트
    @Test("bookTapped -> 책 상세 화면 이동 방출")
    func test_bookTapped() async {
        let vm = MyLibraryViewModel(bookRepository: repository)
        let bookTappedSubject = PublishSubject<Book>() // 책 탭 이벤트를 위한 PublishSubject 생성

        // ViewModel 입력 설정
        let input = MyLibraryViewModel.Input(
            viewWillAppear: Observable<Void>.empty(), // 뷰 로드 이벤트 (현재 비어있음)
            bookTapped: bookTappedSubject.asObservable(), // 책 탭 이벤트
            reachedScrollEnd: Observable<Void>.empty() // 스크롤 끝 이벤트 (현재 비어있음)
        )

        // 입력을 변환하여 출력 값을 얻음
        _ = vm.transform(input)

        // 비동기 작업을 통해 책 탭 이벤트 방출
        Task {
            // publishSubject 구독을 기다리기 위해 1초 기다리고 방출
            try await Task.sleep(nanoseconds: 1_000_000_000)
            bookTappedSubject.onNext(repository.mockBookList[0]) // 첫 번째 책 방출
        }

        do {
            // navigateToBookDetail에서 방출된 값이 예상한 책 목록과 같은지 확인
            for try await value in vm.navigateToBookDetail.values {
                #expect(value == repository.mockBookList[0]) // 방출된 값이 첫 번째 책과 같은지 확인
                break
            }
        } catch {}
    }

    /// 스크롤 끝에 도달했을 때 책 목록이 방출되는지 테스트
    @Test("reachScrollEnd -> Book 목록 방출")
    func test_reachedScrollEnd() async {
        let vm = MyLibraryViewModel(bookRepository: repository)

        // ViewModel 입력 설정
        let input = MyLibraryViewModel.Input(
            viewWillAppear: Observable<Void>.empty(), // 뷰 로드 이벤트 (현재 비어있음)
            bookTapped: Observable<Book>.empty(), // 책 탭 이벤트 (현재 비어있음)
            reachedScrollEnd: Observable<Void>.just(()) // 스크롤 끝 이벤트
        )

        // 입력을 변환하여 출력 값을 얻음
        let output = vm.transform(input)
        // 책 목록이 방출될 때까지 기다림
        // BehaviorRelay로 동작하기 때문에 값 곧바로 얻음
        for await value in output.bookList.values {
            #expect(value[0].items == repository.mockBookList) // 방출된 값이 예상한 책 목록과 같은지 확인
            break
        }
    }

    /// 무한 스크롤 시 책 목록이 누적되는지 테스트
    @Test("multiple reachScrollEnd -> 누적된 Book 목록 방출")
    func test_multipleReachedScrollEnd() async {
        let vm = MyLibraryViewModel(bookRepository: repository)
        let scrollEndSubject = PublishSubject<Void>()

        // ViewModel 입력 설정
        let input = MyLibraryViewModel.Input(
            viewWillAppear: Observable.just(()), // 초기 로드
            bookTapped: Observable<Book>.empty(),
            reachedScrollEnd: scrollEndSubject.asObservable()
        )

        let output = vm.transform(input)

        // 첫 번째 스크롤 이벤트 발생
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            scrollEndSubject.onNext(())
        }

        var emissionCount = 0
        for await value in output.bookList.values {
            emissionCount += 1
            if emissionCount == 2 { // 초기 로드와 첫 번째 스크롤 이벤트 후
                #expect(value[0].items.count == repository.mockBookList.count * 2)
                break
            }
        }
    }

    /// 로딩 중에 중복 요청이 방지되는지 테스트
    @Test("loading prevents duplicate requests")
    func test_loadingPrevention() async {
        let vm = MyLibraryViewModel(bookRepository: repository)
        let scrollEndSubject = PublishSubject<Void>()

        let input = MyLibraryViewModel.Input(
            viewWillAppear: Observable<Void>.empty(),
            bookTapped: Observable<Book>.empty(),
            reachedScrollEnd: scrollEndSubject.asObservable()
        )

        let output = vm.transform(input)

        // 연속된 스크롤 이벤트 발생
        Task {
            scrollEndSubject.onNext(())
            scrollEndSubject.onNext(()) // 바로 연속해서 호출
        }

        var emissionCount = 0
        for await value in output.bookList.values {
            emissionCount += 1
            if emissionCount > 1 {
                #expect(value[0].items.count == repository.mockBookList.count)
                break
            }
        }
    }
}

/// 테스트에서 발생할 수 있는 오류를 정의하는 열거형
private enum MyLibraryViewModelTestError: Error {
    case timeout
}
