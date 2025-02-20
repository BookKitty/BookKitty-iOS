//
//  UIFont+Extensions.swift
//  DesignSystem
//
//  Created by 임성수 on 1/31/25.
//

import CoreText
import UIKit

/// 현재 프로젝트에 사용되는 폰트 종류를 선언.
/// 이번 프로젝트에서 사용하는 폰트의 굵기는 3가지.
public enum FontName: String, CaseIterable {
    case pretendardRegular = "Pretendard-Regular"
    case pretendardSemiBold = "Pretendard-SemiBold"
    case pretendardExtraBold = "Pretendard-ExtraBold"
}

public enum FontWeight {
    case regular
    case semiBold
    case extraBold
}

extension UIFont {
    /// 폰트 등록 메서드
    public static func registerFont(name: String, extension ext: String) {
        guard let fontURL = Bundle.module.url(forResource: name, withExtension: ext) else {
            DSLogger.log("폰트 파일을 찾을 수 없음: \(name).\(ext)")
            return
        }

        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let fontRef = CGFont(fontDataProvider)
        else {
            DSLogger.log("폰트 등록 실패: \(name).\(ext)")
            return
        }

        var error: Unmanaged<CFError>?

        if !CTFontManagerRegisterGraphicsFont(fontRef, &error) {
            DSLogger
                .error("폰트 등록 중 오류 발생: \(name), \(String(describing: error?.takeRetainedValue()))")
        } else {
            DSLogger.log("폰트 등록 완료: \(name)")
        }
    }

    /// **한 번만 호출하면 모든 폰트를 등록하는 메서드**
    /// AppDelegate 에서 아래 함수를 사용.
    public static func registerFonts() {
        for font in FontName.allCases {
            registerFont(name: font.rawValue, extension: "otf")
        }
    }

    /// pretendard 폰트 설정
    ///
    /// - Parameters:
    ///   - fontSize: 원하는 폰트 사이즈 지정
    ///   - weight: 폰트 굵기 지정. 3가지.
    /// - Returns: UIFont 타입으로 반환.
    public static func pretendard(ofSize fontSize: CGFloat, weight: FontWeight) -> UIFont {
        let familyName = "Pretendard"
        var weightString: String
        var normalWeight: UIFont.Weight

        switch weight {
        case .regular:
            weightString = "Regular"
            normalWeight = .regular
        case .semiBold:
            weightString = "SemiBold"
            normalWeight = .semibold
        case .extraBold:
            weightString = "ExtraBold"
            normalWeight = .heavy
        }

        return UIFont(name: "\(familyName)-\(weightString)", size: fontSize) ??
            .systemFont(ofSize: fontSize, weight: normalWeight)
    }
}
