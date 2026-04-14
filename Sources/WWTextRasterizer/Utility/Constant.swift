//
//  Constant.swift
//  WWTextRasterizer
//
//  Created by William.Weng on 2026/4/11.
//

import UIKit

// MARK: - typealias
public extension WWTextRasterizer {
    
    typealias LEDColorSetting = (on: UIColor, off: UIColor, background: UIColor)    // LED顏色 - 亮點 / 暗點 / 背景色
    typealias DotSetting = (size: CGFloat, spacing: CGFloat, type: RoundDotType)    // LED點 - 大小 / 間距 / 樣式
    typealias GlowSetting = (opacity: CGFloat, insetRatio: CGFloat, offset: CGSize) // 亮點光暈 - 透明度 / 擴張比例 / 偏移量
}


// MARK: - typealias
extension WWTextRasterizer {
    
    typealias Boundary = (left: Int, right: Int)    // 左右邊界
}

// MARK: - enum
public extension WWTextRasterizer {
    
    /// LED圓角類型
    enum RoundDotType {
        case circle                                 // 圓形
        case square(_ radiusRatio: CGFloat = 0.22)  // 圓角矩形 (圓角比例)
    }
}
