//
//  Extension.swift
//  WWTextRasterizer
//
//  Created by William.Weng on 2026/4/11.
//

import UIKit

// MARK: - Character
extension Character {
    
    /// 單字字元光柵化
    /// - Parameter config: Configuration
    /// - Returns: BitMatrix
    func toBitMatrix(config: WWTextRasterizer.Configuration) -> WWTextRasterizer.BitMatrix {
        
        let text = String(self)
        let line = text.toCTLine(font: config.font)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds, .useOpticalBounds])

        let rawWidth = max(Int(ceil(bounds.width)), 1)
        let rawHeight = max(Int(ceil(bounds.height)), 1)
        
        let scale = max(CGFloat(config.targetHeight) / CGFloat(rawHeight), 1)
        let bitmapWidth = max(Int(CGFloat(rawWidth) * scale) + config.horizontalPadding * 2, 1)
        let bitmapHeight = config.targetHeight
        
        guard let context = CGContext.buildGrayContext(width: bitmapWidth, height: bitmapHeight) else {
            return .empty(height: bitmapHeight)
        }
        
        context.drawText(text, font: config.font, width: bitmapWidth, height: bitmapHeight, scale: scale, padding: config.horizontalPadding)
        
        return context.toBitMatrix(width: bitmapWidth, height: bitmapHeight, threshold: config.threshold)
    }
}

// MARK: - String
extension String {
    
    /// String => CTLine
    /// - Parameters:
    ///   - font: UIFont
    /// - Returns: CTLine
    func toCTLine(font: UIFont) -> CTLine {
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        
        let attributedString = NSAttributedString(
            string: self,
            attributes: attributes
        )
        
        return CTLineCreateWithAttributedString(attributedString)
    }
}

// MARK: - CGContext
extension CGContext {
    
    /// 建立一個純點陣圖的灰階畫布
    /// - Parameters:
    ///   - width: Int
    ///   - height: Int
    /// - Returns: CGContext?
    static func buildGrayContext(width: Int, height: Int) -> CGContext? {
        return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    }
}

// MARK: - CGContext
extension CGContext {
    
    /// 轉換成BitMatrix (灰階到布林)
    /// - Parameters:
    ///   - width: Int
    ///   - height: Int
    ///   - threshold: 決定亮暗的臨界值
    /// - Returns: WWTextRasterizer.BitMatrix
    func toBitMatrix(width: Int, height: Int, threshold: UInt8) -> WWTextRasterizer.BitMatrix {
        
        guard let data = data else { return .empty(height: height) }
        
        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height)
        var pixels = Array(repeating: false, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let srcIndex = y * width + x
                let value = pointer[srcIndex]
                let flippedY = (height - 1) - y
                let dstIndex = flippedY * width + x
                pixels[dstIndex] = value >= threshold
            }
        }
        
        return .init(width: width, height: height, pixels: pixels)
    }
    
    /// 繪出等比大小的文字
    /// - Parameters:
    ///   - text: String
    ///   - font: UIFont
    ///   - width: Int
    ///   - height: Int
    ///   - scale: CGFloat
    ///   - padding: Int
    func drawText(_ text: String, font: UIFont, width: Int, height: Int, scale: CGFloat, padding: Int) {
        
        setFillColor(UIColor.black.cgColor)
        fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        setShouldAntialias(true)
        interpolationQuality = .high
        textMatrix = .identity
        translateBy(x: 0, y: CGFloat(height))
        scaleBy(x: 1, y: -1)
        
        let scaledFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize * scale, nil)
        let line = text.toCTLine(font: scaledFont)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds, .useOpticalBounds])

        let drawX = CGFloat(padding)
        let drawY = max((CGFloat(height) - bounds.height) / 2 - bounds.minY, 0)

        textPosition = CGPoint(x: drawX, y: drawY)
        CTLineDraw(line, self)
    }
    
    /// 在指定位置繪製 LED 點陣 (將給定的 `BitMatrix` 轉換為 LED 顯示效果，包含亮點、暗點、光暈等完整視覺效果)
    /// - Parameters:
    ///   - bitMatrix: 點陣資料，`true` 代表該點應亮起，`false` 代表暗點
    ///   - x: 點陣在畫布上的水平起始位置（邏輯像素單位）
    ///   - y: 點陣在畫布上的垂直起始位置（邏輯像素單位）
    ///   - dotSize: 每個 LED 點的大小（邏輯像素）
    ///   - dotSpacing: LED 點之間的間距（邏輯像素）
    ///   - ledOnColor: 亮點的主要顏色
    ///   - ledOffColor: 暗點的背景顏色
    ///   - glowOpacity: 亮點光暈的透明度，範圍 `0.0 ~ 1.0`，值越小越透明
    ///   - glowBlurRatio: 光暈相對於點大小的擴張比例，範圍 `0.0 ~ 1.0`
    ///   - glowOffset: 光暈相對於亮點的偏移量，預設為零
    ///   - cornerRadiusRatio: 亮點圓角比例，相對於 `dotSize`，範圍 `0.0 ~ 0.5`
    ///   - glowCornerRadiusRatio: 光暈圓角比例，相對於擴張後尺寸，範圍 `0.0 ~ 0.5`
    ///   - useRoundDots: 是否使用圓形 LED 點，`false` 時使用圓角矩形
    func drawLED(by bitMatrix: WWTextRasterizer.BitMatrix, x: Int, y: Int, dotSize: CGFloat = 4, dotSpacing: CGFloat = 3, ledOnColor: UIColor, ledOffColor: UIColor, glowOpacity: CGFloat = 0.22, glowBlurRatio: CGFloat = 0.9, glowOffset: CGSize = .zero, cornerRadiusRatio: CGFloat = 0.2, glowCornerRadiusRatio: CGFloat = 0.3, useRoundDots: Bool) {
        
        let pitch = dotSize + dotSpacing
        let rect = CGRect(x: CGFloat(x) * pitch, y: CGFloat(y) * pitch, width: dotSize, height: dotSize)
        let isOn = bitMatrix[x, y]
        let baseColor = isOn ? ledOnColor : ledOffColor
        var cornerRadius = dotSize * cornerRadiusRatio

        setAllowsAntialiasing(true)
        setShouldAntialias(true)
        
        // 1. 光暈層（Glow）
        if (isOn) {
            safeGraphicsState {

                let blur = max(1, dotSize * glowBlurRatio)
                let glowColor = ledOnColor.withAlphaComponent(glowOpacity).cgColor
                
                setShadow(offset: glowOffset, blur: blur, color: glowColor)
                setFillColor(ledOnColor.cgColor)
                
                drawLedDot(in: rect, radius: cornerRadius, useRoundDots: useRoundDots)
            }
        }
        
        // 2. 主體層（Base LED）
        setFillColor(baseColor.cgColor)
        drawLedDot(in: rect, radius: cornerRadius, useRoundDots: useRoundDots)
        
        // 3. 高光層（Highlight）
        if (isOn) {
            safeGraphicsState {
                
                let highlightInset = dotSize * 0.28
                let highlightRect = rect.insetBy(dx: highlightInset, dy: highlightInset)
                    .offsetBy(dx: -dotSize * 0.10, dy: -dotSize * 0.10)
                
                cornerRadius = dotSize * glowCornerRadiusRatio * 0.5
                setFillColor(UIColor.white.withAlphaComponent(0.18).cgColor)
                drawLedDot(in: highlightRect, radius: cornerRadius, useRoundDots: useRoundDots)
            }
        }
    }
    
    /// 在安全的圖形狀態下執行繪圖區塊 (自動管理 `saveGState()` / `restoreGState()`，確保繪圖完成後狀態完全還原)
    /// - Parameter course: 要執行的繪圖閉包，在此閉包內可以安全地修改圖形狀態（如顏色、變換、混合模式等）
    func safeGraphicsState(course: () -> Void) {
        saveGState()
        course()
        restoreGState()
    }
    
    /// 繪製單顆 LED 點。
    /// - Parameters:
    ///   - rect: LED 點的繪製區域
    ///   - radius: 圓角半徑；僅在 `useRoundDots == false` 時生效
    ///   - useRoundDots: 是否使用圓形 LED；`true` 為圓形，`false` 為圓角矩形
    func drawLedDot(in rect: CGRect, radius: CGFloat, useRoundDots: Bool) {
        
        if (useRoundDots) { fillEllipse(in: rect); return }
        
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        addPath(path)
        fillPath()
    }
}
