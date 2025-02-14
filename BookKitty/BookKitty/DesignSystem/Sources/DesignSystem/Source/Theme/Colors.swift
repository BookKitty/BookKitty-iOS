//
//  Colors.swift
//  DesignSystem
//
//  Created by 임성수 on 1/29/25.
//  기본적으로 컬러는 Colors 에셋 파일에서 직접 가져다 쓰는 것을 원칙으로 합니다.

import UIKit

/// 시스템 컬러는 검정과 프로젝트 맞춤 컬러 보라색 두가지만 사용합니다.
public enum SystemColors: String {
    case Black = "Black"
}

/// 컬러의 ramp 어레인지를 다음과 같이 제한합니다.
public enum SystemColorRamps: String {
    case r50 = "50"
    case r100 = "100"
    case r200 = "200"
    case r300 = "300"
    case r400 = "400"
    case r500 = "500"
    case r600 = "600"
    case r700 = "700"
    case r800 = "800"
    case r900 = "900"
}

public enum Colors {
    // MARK: - Static Computed Properties

    // MARK: - Background Color

    public static var background0: UIColor { UIColor.designSystemColor(name: "Background0") }
    public static var background1: UIColor { UIColor.designSystemColor(name: "Background1") }
    public static var background2: UIColor { UIColor.designSystemColor(name: "Background2") }
    public static var backgroundModal: UIColor { UIColor.designSystemColor(name: "BackgroundModal")
    }

    // MARK: - Brand

    public static var brandMain: UIColor { UIColor.designSystemColor(name: "BrandMain") }
    public static var brandSub: UIColor { UIColor.designSystemColor(name: "BrandSub") }
    public static var brandSub2: UIColor { UIColor.designSystemColor(name: "BrandSub2") }
    public static var brandSub3: UIColor { UIColor.designSystemColor(name: "BrandSub3") }

    // MARK: - Font Color

    public static var fontDisabled: UIColor { UIColor.designSystemColor(name: "FontDisabled") }
    public static var fontMain: UIColor { UIColor.designSystemColor(name: "FontMain") }
    public static var fontSub1: UIColor { UIColor.designSystemColor(name: "FontSub1") }
    public static var fontSub2: UIColor { UIColor.designSystemColor(name: "FontSub2") }
    public static var fontWhite: UIColor { UIColor.designSystemColor(name: "FontWhite") }
    public static var fontWhiteDisabled: UIColor {
        UIColor.designSystemColor(name: "FontWhiteDisabled")
    }

    public static var fontWhiteUnselected: UIColor {
        UIColor.designSystemColor(name: "FontWhiteUnselected")
    }

    // MARK: - Shadow Color

    public static var shadow15: UIColor { UIColor.designSystemColor(name: "Shadow15") }
    public static var shadow25: UIColor { UIColor.designSystemColor(name: "Shadow25") }

    // MARK: - Status Color

    public static var statusGreen: UIColor { UIColor.designSystemColor(name: "StatusGreen") }
    public static var statusRed: UIColor { UIColor.designSystemColor(name: "StatusRed") }
    public static var statusYellow: UIColor { UIColor.designSystemColor(name: "StatusYellow") }

    // MARK: - Static Functions

    // MARK: - System Color

    /// 숫자가 낮을수록 연하다.
    /// `.Black-<ramp>`로 직접 확인 가능.
    /// - Parameter ramp: 원하는 레벨의 진한 정도를 선택. 최대 900, 최소 50
    /// - Returns: UIColor 값 반환.
    public static func systemGray(_ ramp: SystemColorRamps) -> UIColor? {
        UIColor.designSystemColor(name: "Black-\(ramp.rawValue)")
    }
}
