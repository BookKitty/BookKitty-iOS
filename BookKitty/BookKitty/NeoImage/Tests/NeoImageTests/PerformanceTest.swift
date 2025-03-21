import Kingfisher
import NeoImage
import Testing
import UIKit

actor PerformanceResultsManager {
    // MARK: - Properties

    private(set) var neoImageTimes: [Double] = []
    private(set) var kingfisherTimes: [Double] = []

    // MARK: - Functions

    func resetTimes() {
        neoImageTimes = []
        kingfisherTimes = []
    }

    func addNeoImageTime(_ time: Double) {
        neoImageTimes.append(time)
    }

    func addKingfisherTime(_ time: Double) {
        kingfisherTimes.append(time)
    }

    func getNeoImageStats() -> (average: Double, min: Double, max: Double) {
        guard !neoImageTimes.isEmpty else {
            return (0, 0, 0)
        }
        let validTimes = neoImageTimes.filter { $0 > 0 }
        guard !validTimes.isEmpty else {
            return (0, 0, 0)
        }

        let avg = validTimes.reduce(0, +) / Double(validTimes.count)
        let min = validTimes.min() ?? 0
        let max = validTimes.max() ?? 0

        return (avg, min, max)
    }

    func getKingfisherStats() -> (average: Double, min: Double, max: Double) {
        guard !kingfisherTimes.isEmpty else {
            return (0, 0, 0)
        }
        let validTimes = kingfisherTimes.filter { $0 > 0 }
        guard !validTimes.isEmpty else {
            return (0, 0, 0)
        }

        let avg = validTimes.reduce(0, +) / Double(validTimes.count)
        let min = validTimes.min() ?? 0
        let max = validTimes.max() ?? 0

        return (avg, min, max)
    }
}

/// 테스트 인프라를 설정하고 관리하는 클래스
@MainActor
class ImageTestingContext {
    // MARK: - Properties

    /// 테스트용 이미지 URL 목록
    let testImageURLs: [URL] = [
        URL(string: "https://picsum.photos/id/1/2000/2000")!,
        URL(string: "https://picsum.photos/id/2/2000/2000")!,
        URL(string: "https://picsum.photos/id/3/2000/2000")!,
        URL(string: "https://picsum.photos/id/4/2000/2000")!,
        URL(string: "https://picsum.photos/id/5/2000/2000")!,
        URL(string: "https://picsum.photos/id/6/2000/2000")!,
        URL(string: "https://picsum.photos/id/7/2000/2000")!,
        URL(string: "https://picsum.photos/id/8/2000/2000")!,
        URL(string: "https://picsum.photos/id/9/2000/2000")!,
        URL(string: "https://picsum.photos/id/10/2000/2000")!,
        URL(string: "https://picsum.photos/id/11/2000/2000")!,
        URL(string: "https://picsum.photos/id/12/2000/2000")!,
        URL(string: "https://picsum.photos/id/13/2000/2000")!,
        URL(string: "https://picsum.photos/id/14/2000/2000")!,
        URL(string: "https://picsum.photos/id/15/2000/2000")!,
        URL(string: "https://picsum.photos/id/16/2000/2000")!,
        URL(string: "https://picsum.photos/id/17/2000/2000")!,
        URL(string: "https://picsum.photos/id/18/2000/2000")!,
        URL(string: "https://picsum.photos/id/19/2000/2000")!,
        URL(string: "https://picsum.photos/id/20/2000/2000")!,
        URL(string: "https://picsum.photos/id/21/2000/2000")!,
        URL(string: "https://picsum.photos/id/22/2000/2000")!,
        URL(string: "https://picsum.photos/id/23/2000/2000")!,
        URL(string: "https://picsum.photos/id/24/2000/2000")!,
        URL(string: "https://picsum.photos/id/25/2000/2000")!,
        URL(string: "https://picsum.photos/id/26/2000/2000")!,
        URL(string: "https://picsum.photos/id/27/2000/2000")!,
        URL(string: "https://picsum.photos/id/28/2000/2000")!,
        URL(string: "https://picsum.photos/id/29/2000/2000")!,
        URL(string: "https://picsum.photos/id/30/2000/2000")!,
        URL(string: "https://picsum.photos/id/31/2000/2000")!,
        URL(string: "https://picsum.photos/id/32/2000/2000")!,
        URL(string: "https://picsum.photos/id/33/2000/2000")!,
        URL(string: "https://picsum.photos/id/34/2000/2000")!,
        URL(string: "https://picsum.photos/id/35/2000/2000")!,
        URL(string: "https://picsum.photos/id/36/2000/2000")!,
    ]

    // 테스트 인프라
    var testWindow: UIWindow!
    let resultsManager = PerformanceResultsManager()
    let testImageSize = CGSize(width: 160, height: 160)
    let gridImageCount = 36

    // 테스트 컨테이너
    var neoImageViews: [UIImageView] = []
    var kingfisherImageViews: [UIImageView] = []
    var containerView: UIView!

    // MARK: - Lifecycle

    init() {
        // 테스트 윈도우 설정
        testWindow = UIWindow(frame: UIScreen.main.bounds)
        testWindow.makeKeyAndVisible()

        // 컨테이너 뷰 설정
        containerView = UIView(frame: testWindow.bounds)
        testWindow.addSubview(containerView)

        // 이미지뷰 배열 초기화
        neoImageViews = []
        kingfisherImageViews = []

        // 이미지 뷰 생성 및 배치
        setupImageViews()
    }

    // MARK: - Functions

    func cleanUp() {
        // UI 자원 정리
        containerView.removeFromSuperview()
        testWindow.isHidden = true

        // 참조 제거
        neoImageViews = []
        kingfisherImageViews = []
        containerView = nil
        testWindow = nil
    }

    func clearAllCaches() async {
        // NeoImage 캐시 지우기
        ImageCache.shared.clearCache()

        // Kingfisher 캐시 지우기
        KingfisherManager.shared.cache.clearMemoryCache()
        await KingfisherManager.shared.cache.clearDiskCache()

        // 결과 초기화
        await resultsManager.resetTimes()
    }

    // MARK: - NeoImage 테스트 메서드

    func loadWithNeoImageAsync(imageView: UIImageView, url: URL) async throws -> Double {
        let startTime = Date()
        do {
            try await imageView.neo.setImage(with: url)
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("loaded with NeoImage in \(String(format: "%.3f", elapsedTime)) seconds")

            return elapsedTime
        } catch {
            print("Error loading image with NeoImage: \(error)")
            throw error
        }
    }

    func loadWithNeoImage(imageView: UIImageView, url: URL) async throws -> Double {
        let startTime = Date()
        return try await withCheckedThrowingContinuation { continuation in
            imageView.neo.setImage(
                with: url
            ) { result in
                switch result {
                case .success:
                    let elapsedTime = Date().timeIntervalSince(startTime)
                    print("loaded with NeoImage in \(String(format: "%.6f", elapsedTime)) seconds")
                    continuation.resume(returning: elapsedTime)
                case let .failure(error):
                    print("Error loading image with Kingfisher: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func loadWithKingfisher(imageView: UIImageView, url: URL) async throws -> Double {
        let startTime = Date()
        return try await withCheckedThrowingContinuation { continuation in
            imageView.kf.setImage(
                with: url,
                options: nil
            ) { result in
                switch result {
                case .success:
                    let elapsedTime = Date().timeIntervalSince(startTime)
                    print(
                        "loaded with Kingfisher in \(String(format: "%.3f", elapsedTime)) seconds"
                    )
                    continuation.resume(returning: elapsedTime)
                case let .failure(error):
                    print("Error loading image with Kingfisher: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func loadImagesWithNeoImage() async throws {
        for (index, url) in testImageURLs.prefix(gridImageCount).enumerated() {
            guard index < neoImageViews.count else {
                break
            }

            do {
                let imageView = neoImageViews[index]
                let elapsedTime = try await loadWithNeoImageAsync(imageView: imageView, url: url)
                await resultsManager.addNeoImageTime(elapsedTime)
            } catch {
                print("Error in NeoImage test at index \(index): \(error)")
                await resultsManager.addNeoImageTime(-1.0)
            }
        }
    }

    func loadSameImagesWithNeoImage() async throws {
        for index in 0 ..< 36 {
            do {
                let imageView = neoImageViews[index]
                let elapsedTime = try await loadWithNeoImageAsync(
                    imageView: imageView,
                    url: testImageURLs[0]
                )
                await resultsManager.addNeoImageTime(elapsedTime)
            } catch {
                print("Error in Kingfisher test at index \(index): \(error)")
                await resultsManager.addNeoImageTime(-1.0)
            }
        }
    }

    // MARK: - Kingfisher 테스트 메서드

    func loadImagesWithKingfisher() async throws {
        for (index, url) in testImageURLs.prefix(gridImageCount).enumerated() {
            guard index < kingfisherImageViews.count else {
                break
            }

            do {
                let imageView = kingfisherImageViews[index]
                let elapsedTime = try await loadWithKingfisher(imageView: imageView, url: url)
                await resultsManager.addKingfisherTime(elapsedTime)
            } catch {
                print("Error in Kingfisher test at index \(index): \(error)")
                await resultsManager.addKingfisherTime(-1.0)
            }
        }
    }

    func loadSameImagesWithKingfisher() async throws {
        for index in 0 ..< 36 {
            do {
                let imageView = kingfisherImageViews[index]
                let elapsedTime = try await loadWithKingfisher(
                    imageView: imageView,
                    url: testImageURLs[0]
                )
                await resultsManager.addKingfisherTime(elapsedTime)
            } catch {
                print("Error in Kingfisher test at index \(index): \(error)")
                await resultsManager.addKingfisherTime(-1.0)
            }
        }
    }

    private func setupImageViews() {
        // 그리드 설정
        let columns = 2
        let spacing: CGFloat = 10
        let width = testImageSize.width
        let height = testImageSize.height

        // NeoImage와 Kingfisher 뷰 생성
        for i in 0 ..< gridImageCount {
            let row = i / columns
            let col = i % columns

            let x = CGFloat(col) * (width + spacing)
            let y = CGFloat(row) * (height + spacing)

            // NeoImage용 이미지뷰
            let neoFrame = CGRect(x: x, y: y, width: width, height: height)
            let neoImageView = UIImageView(frame: neoFrame)
            neoImageView.contentMode = .scaleAspectFill
            neoImageView.clipsToBounds = true
            neoImageView.tag = i // 태그로 인덱스 저장
            containerView.addSubview(neoImageView)
            neoImageViews.append(neoImageView)

            // Kingfisher용 이미지뷰
            let kfFrame = CGRect(x: x + width * 2 + spacing * 2, y: y, width: width, height: height)
            let kfImageView = UIImageView(frame: kfFrame)
            kfImageView.contentMode = .scaleAspectFill
            kfImageView.clipsToBounds = true
            kfImageView.tag = i // 태그로 인덱스 저장
            containerView.addSubview(kfImageView)
            kingfisherImageViews.append(kfImageView)
        }
    }
}

// MARK: - Swift Testing Tests

@Suite("NeoImage Performance Tests")
struct NeoImagePerformanceTests {
    @Test("NeoImage 기본 성능 테스트")
    func testNeoImagePerformance() async throws {
        let context = await ImageTestingContext()

        // 모든 캐시 비우기
        await context.clearAllCaches()

        // 이미지 로드
        try await context.loadImagesWithNeoImage()

        // 결과 분석
        let stats = await context.resultsManager.getNeoImageStats()

        print("""
        NeoImage Performance:
        평균: \(String(format: "%.3f", stats.average)) 초
        최단소요: \(String(format: "%.3f", stats.min)) 초
        최장소요: \(String(format: "%.3f", stats.max)) 초
        """)

        // 기준에 따른 성능 검증
        #expect(stats.average < 2.0, "NeoImage 평균 로딩 시간이 2초 이내여야 합니다")
        await context.cleanUp()
    }

    @Test("Kingfisher 기본 성능 테스트")
    func testKingfisherPerformance() async throws {
        let context = await ImageTestingContext()

        // 모든 캐시 비우기
        await context.clearAllCaches()

        // 이미지 로드
        try await context.loadImagesWithKingfisher()

        // 결과 분석
        let stats = await context.resultsManager.getKingfisherStats()

        print("""
        Kingfisher Performance:
        평균: \(String(format: "%.3f", stats.average)) 초
        최단소요: \(String(format: "%.3f", stats.min)) 초
        최장소요: \(String(format: "%.3f", stats.max)) 초
        """)

        // 기준에 따른 성능 검증
        #expect(stats.average < 2.0, "Kingfisher 평균 로딩 시간이 2초 이내여야 합니다")
        await context.cleanUp()
    }

    /// 1
    @Test("NeoImage와 Kingfisher 성능 비교")
    func testCompareLibraryPerformance() async throws {
        let context = await ImageTestingContext()

        // 모든 캐시 비우기
        await context.clearAllCaches()

        // 두 라이브러리 모두 테스트
        try await context.loadImagesWithNeoImage()
        try await context.loadImagesWithKingfisher()

        // 결과 가져오기
        let neoStats = await context.resultsManager.getNeoImageStats()
        let kfStats = await context.resultsManager.getKingfisherStats()

        // 성능 비교 출력
        print("""
        ======== 성능 비교 결과 ========
        NeoImage  평균: \(String(format: "%.3f", neoStats.average)) 초 (최소: \(String(format: "%.3f",
                                                                                  neoStats
                                                                                      .min)), 최대: \(
            String(
                format: "%.3f",
                neoStats.max
            )
        ))
        Kingfisher 평균: \(String(format: "%.3f", kfStats.average)) 초 (최소: \(String(format: "%.3f",
                                                                                  kfStats
                                                                                      .min)), 최대: \(
            String(
                format: "%.3f",
                kfStats.max
            )
        ))
        차이: \(String(format: "%.3f", abs(neoStats.average - kfStats.average))) 초
        ==============================
        """)

        // 각 라이브러리가 기준 시간 내에 동작하는지 확인
        #expect(neoStats.average < 2.0, "NeoImage 평균 로딩 시간이 2초 이내여야 합니다")
        #expect(kfStats.average < 2.0, "Kingfisher 평균 로딩 시간이 2초 이내여야 합니다")
        await context.cleanUp()
    }

    /// 2
    @Test("NeoImage와 Kingfisher 중복 이미지 다운르도 방지 기능 비교")
    func testCompareLibraryPerformanceForSameImages() async throws {
        let context = await ImageTestingContext()

        // 모든 캐시 비우기
        await context.clearAllCaches()

        // 두 라이브러리 모두 테스트
        try await context.loadSameImagesWithNeoImage()
        try await context.loadSameImagesWithKingfisher()

        // 결과 가져오기
        let neoStats = await context.resultsManager.getNeoImageStats()
        let kfStats = await context.resultsManager.getKingfisherStats()

        // 성능 비교 출력
        print("""
        ======== 성능 비교 결과 ========
        NeoImage  평균: \(String(format: "%.3f", neoStats.average)) 초 (최소: \(String(format: "%.3f",
                                                                                  neoStats
                                                                                      .min)), 최대: \(
            String(
                format: "%.3f",
                neoStats.max
            )
        ))
        Kingfisher 평균: \(String(format: "%.3f", kfStats.average)) 초 (최소: \(String(format: "%.3f",
                                                                                  kfStats
                                                                                      .min)), 최대: \(
            String(
                format: "%.3f",
                kfStats.max
            )
        ))
        차이: \(String(format: "%.3f", abs(neoStats.average - kfStats.average))) 초
        ==============================
        """)

        // 각 라이브러리가 기준 시간 내에 동작하는지 확인
        #expect(neoStats.average < 2.0, "NeoImage 평균 로딩 시간이 2초 이내여야 합니다")
        #expect(kfStats.average < 2.0, "Kingfisher 평균 로딩 시간이 2초 이내여야 합니다")
        await context.cleanUp()
    }

    /// 3
    @Test("캐시 성능 비교: NeoImage vs Kingfisher")
    func testCompareCachePerformance() async throws {
        let context = await ImageTestingContext()

        // 모든 캐시 비우기
        await context.clearAllCaches()

        // 첫 번째 로드 - 캐시 없음
        try await context.loadImagesWithNeoImage()
        let neoFirstLoadStats = await context.resultsManager.getNeoImageStats()

        await context.resultsManager.resetTimes()

        try await context.loadImagesWithKingfisher()
        let kfFirstLoadStats = await context.resultsManager.getKingfisherStats()

        // 결과 초기화
        await context.resultsManager.resetTimes()

        // 두 번째 로드 - 캐시됨
        try await context.loadImagesWithNeoImage()
        let neoSecondLoadStats = await context.resultsManager.getNeoImageStats()

        await context.resultsManager.resetTimes()
        try await context.loadImagesWithKingfisher()
        let kfSecondLoadStats = await context.resultsManager.getKingfisherStats()

        // 개선율 계산
        let neoImprovementRate = 1 - (neoSecondLoadStats.average / neoFirstLoadStats.average)
        let kfImprovementRate = 1 - (kfSecondLoadStats.average / kfFirstLoadStats.average)

        print("""
        ======== 캐시 성능 비교 ========
        NeoImage 개선율: \(String(format: "%.1f", neoImprovementRate * 100))%
        Kingfisher 개선율: \(String(format: "%.1f", kfImprovementRate * 100))%
        ==============================
        """)

        // 각 라이브러리의 캐시 개선율을 확인
        #expect(neoImprovementRate > 0.5, "NeoImage 캐시 사용 시 최소 50% 이상 속도가 개선되어야 합니다")
        #expect(kfImprovementRate > 0.5, "Kingfisher 캐시 사용 시 최소 50% 이상 속도가 개선되어야 합니다")

        await context.cleanUp()
    }

    @Test("NeoImage 중복 이미지 다운르도 방지 기능 비교")
    func testNeoImagePerformanceForSameImages() async throws {
        let context = await ImageTestingContext()
        await context.clearAllCaches()

        try await context.loadSameImagesWithNeoImage()

        let neoStats = await context.resultsManager.getNeoImageStats()

        print("""
        ======== 성능 비교 결과 ========
        NeoImage  평균: \(String(format: "%.3f", neoStats.average)) 초 (최소: \(String(format: "%.3f",
                                                                                  neoStats
                                                                                      .min)), 최대: \(
            String(
                format: "%.3f",
                neoStats.max
            )
        ))
        ==============================
        """)

        #expect(neoStats.average < 2.0, "NeoImage 평균 로딩 시간이 2초 이내여야 합니다")
        await context.cleanUp()
    }

    @Test("NeoImage 캐시 성능 테스트")
    func testNeoImageCachePerformance() async throws {
        let context = await ImageTestingContext()

        // 모든 캐시 비우기
        await context.clearAllCaches()

        // 첫 번째 로드 - 캐시 없음
        try await context.loadImagesWithNeoImage()
        let firstLoadStats = await context.resultsManager.getNeoImageStats()

        await context.resultsManager.resetTimes()

        try await context.loadImagesWithNeoImage()
        let secondLoadStats = await context.resultsManager.getNeoImageStats()

        print("""
        ======== NeoImage 캐시 성능 ========
        첫 번째 로드 평균: \(String(format: "%.3f", firstLoadStats.average)) 초
        두 번째 로드 평균: \(String(format: "%.3f", secondLoadStats.average)) 초
        개선율: \(String(
            format: "%.1f",
            (1 - secondLoadStats.average / firstLoadStats.average) * 100
        ))%
        ==================================
        """)

        // 캐시된 로드가 더 빨라야 함
        #expect(secondLoadStats.average < firstLoadStats.average, "캐시된 이미지 로드가 더 빨라야 합니다")

        // 최소 50% 이상 개선되어야 함 (이 값은 조정 가능)
        let improvementRate = 1 - (secondLoadStats.average / firstLoadStats.average)
        #expect(improvementRate > 0.5, "캐시 사용 시 최소 50% 이상 속도가 개선되어야 합니다")
        await context.cleanUp()
    }

    @Test("Kingfisher 캐시 성능 테스트")
    func testKingfisherCachePerformance() async throws {
        let context = await ImageTestingContext()

        // 모든 캐시 비우기
        await context.clearAllCaches()

        // 첫 번째 로드 - 캐시 없음
        try await context.loadImagesWithKingfisher()
        let firstLoadStats = await context.resultsManager.getKingfisherStats()

        // 결과 초기화
        await context.resultsManager.resetTimes()

        // 두 번째 로드 - 캐시됨
        try await context.loadImagesWithKingfisher()
        let secondLoadStats = await context.resultsManager.getKingfisherStats()

        print("""
        ======== Kingfisher 캐시 성능 ========
        첫 번째 로드 평균: \(String(format: "%.3f", firstLoadStats.average)) 초
        두 번째 로드 평균: \(String(format: "%.3f", secondLoadStats.average)) 초
        개선율: \(String(
            format: "%.1f",
            (1 - secondLoadStats.average / firstLoadStats.average) * 100
        ))%
        ====================================
        """)

        // 캐시된 로드가 더 빨라야 함
        #expect(secondLoadStats.average < firstLoadStats.average, "캐시된 이미지 로드가 더 빨라야 합니다")

        // 최소 50% 이상 개선되어야 함 (이 값은 조정 가능)
        let improvementRate = 1 - (secondLoadStats.average / firstLoadStats.average)
        #expect(improvementRate > 0.5, "캐시 사용 시 최소 50% 이상 속도가 개선되어야 합니다")

        await context.cleanUp()
    }
}
