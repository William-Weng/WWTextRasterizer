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
    func _toBitMatrix(config: WWTextRasterizer.Configuration) -> WWTextRasterizer.BitMatrix {
        
        let text = String(self)
        let line = text._toCTLine(font: config.font)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds, .useOpticalBounds])

        let rawWidth = max(Int(ceil(bounds.width)), 1)
        let rawHeight = max(Int(ceil(bounds.height)), 1)
        
        let scale = max(CGFloat(config.targetHeight) / CGFloat(rawHeight), 1)
        let bitmapWidth = max(Int(CGFloat(rawWidth) * scale) + config.horizontalPadding * 2, 1)
        let bitmapHeight = config.targetHeight
        
        guard let context = CGContext._buildGrayContext(width: bitmapWidth, height: bitmapHeight) else {
            return .empty(height: bitmapHeight)
        }
        
        context._drawText(text, font: config.font, width: bitmapWidth, height: bitmapHeight, scale: scale, padding: config.horizontalPadding)
        
        return context._toBitMatrix(width: bitmapWidth, height: bitmapHeight, threshold: config.threshold)
    }
}

// MARK: - String
private extension String {
    
    /// String => CTLine
    /// - Parameters:
    ///   - font: UIFont
    /// - Returns: CTLine
    func _toCTLine(font: UIFont) -> CTLine {
        
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

// MARK: - UIGraphicsImageRenderer
extension UIGraphicsImageRenderer {
    
    /// 建立並配置 UIGraphicsImageRenderer 實例
    /// - Parameters:
    ///   - size: 畫布的邏輯尺寸（Points）。
    ///   - scale: 縮放倍率。此處會將邏輯尺寸乘以 scale 來決定最終輸出的像素尺寸。
    ///   - opaque: 是否為不透明。若為 true，則不支援透明度，渲染效能通常較佳。
    /// - Returns: 配置完成的 `UIGraphicsImageRenderer` 物件。
    static func _build(size: CGSize, scale: CGFloat, opaque: Bool) -> UIGraphicsImageRenderer {
        
        let outputSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        
        format.scale = 1
        format.opaque = opaque
        
        return UIGraphicsImageRenderer(size: outputSize, format: format)
    }
}

// MARK: - CGContext
private extension CGContext {
    
    /// 建立一個純點陣圖的灰階畫布
    /// - Parameters:
    ///   - width: Int
    ///   - height: Int
    /// - Returns: CGContext?
    static func _buildGrayContext(width: Int, height: Int) -> CGContext? {
        return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    }
}

// MARK: - CGContext
extension CGContext {
        
    /// 在指定位置繪製 LED 點陣 (將給定的 `BitMatrix` 轉換為 LED 顯示效果，包含亮點、暗點、光暈等完整視覺效果)
    /// - Parameters:
    ///   - bitMatrix: 點陣資料，`true` 代表該點應亮起，`false` 代表暗點
    ///   - x: 點陣在畫布上的水平起始位置（邏輯像素單位）
    ///   - y: 點陣在畫布上的垂直起始位置（邏輯像素單位）
    ///   - ledColor: LED顏色設定值 (亮點 / 暗點 / 背景)
    ///   - dot: LED點設定值 (大小 / 間距 / 樣式)
    ///   - glow: 光暈設定值 (透明度 / 擴張比例 / 偏移量)
    func _drawLED(by bitMatrix: WWTextRasterizer.BitMatrix, x: Int, y: Int, dot: WWTextRasterizer.DotSetting, ledColor: WWTextRasterizer.LEDColorSetting, glow: WWTextRasterizer.GlowSetting) {
        
        let pitch = dot.size + dot.spacing
        let size: CGSize = .init(width: dot.size, height: dot.size)
        let origin: CGPoint = .init(x: CGFloat(x) * pitch, y: CGFloat(y) * pitch)
        let rect: CGRect = .init(origin: origin, size: size)
        
        let isOn = bitMatrix[x, y]
        let baseColor = isOn ? ledColor.on : ledColor.off
        
        setAllowsAntialiasing(true)
        setShouldAntialias(true)
        
        // 1. 光暈層（Glow）
        if (isOn) {
            _safeGraphicsState {

                let blur = max(1, dot.size * glow.insetRatio)
                let glowColor = ledColor.on.withAlphaComponent(glow.opacity).cgColor
                
                setShadow(offset: glow.offset, blur: blur, color: glowColor)
                setFillColor(ledColor.on.cgColor)
                
                _drawLedDot(in: rect, roundDotType: dot.type)
            }
        }
        
        // 2. 主體層（Base LED）
        setFillColor(baseColor.cgColor)
        _drawLedDot(in: rect, roundDotType: dot.type)
        
        // 3. 高光層（Highlight）
        if (isOn) {
            _safeGraphicsState {
                
                let highlightInset = dot.size * 0.28
                let highlightRect = rect.insetBy(dx: highlightInset, dy: highlightInset).offsetBy(dx: -dot.size * 0.10, dy: -dot.size * 0.10)
                
                setFillColor(UIColor.white.withAlphaComponent(0.18).cgColor)
                _drawLedDot(in: highlightRect, roundDotType: dot.type, isHighlight: true)
            }
        }
    }
    
    /// 繪製單顆 LED 點。
    /// - Parameters:
    ///   - rect: LED 點的繪製區域
    ///   - roundDotType: 圓角類型 (正方形 / 圓形)
    func _drawLedDot(in rect: CGRect, roundDotType: WWTextRasterizer.RoundDotType, isHighlight: Bool = false) {
        
        switch roundDotType {
        case .circle:
            fillEllipse(in: rect)
        case .square(let ratio):
            let newRatio = (!isHighlight) ? ratio : ratio * 0.3
            let path = CGPath(roundedRect: rect, cornerWidth: rect.width * newRatio, cornerHeight: rect.height * newRatio, transform: nil)
            addPath(path)
            fillPath()
        }
    }
}

// MARK: - CGContext
private extension CGContext {
    
    /// 在安全的圖形狀態下執行繪圖區塊 (自動管理 `saveGState()` / `restoreGState()`，確保繪圖完成後狀態完全還原)
    /// - Parameter closure: 要執行的繪圖閉包，在此閉包內可以安全地修改圖形狀態（如顏色、變換、混合模式等）
    func _safeGraphicsState(closure: () -> Void) {
        saveGState()
        closure()
        restoreGState()
    }
    
    /// 轉換成BitMatrix (灰階到布林)
    /// - Parameters:
    ///   - width: Int
    ///   - height: Int
    ///   - threshold: 決定亮暗的臨界值
    /// - Returns: WWTextRasterizer.BitMatrix
    func _toBitMatrix(width: Int, height: Int, threshold: UInt8) -> WWTextRasterizer.BitMatrix {
        
        guard let data = data else { return .empty(height: height) }
        
        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height)
        var pixels = Array(repeating: false, count: width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let srcIndex = y * width + x
                let value = pointer[srcIndex]
                let flippedY = (height - 1) - y
                let dstIndex = flippedY * width + x
                pixels[dstIndex] = (value >= threshold)
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
    func _drawText(_ text: String, font: UIFont, width: Int, height: Int, scale: CGFloat, padding: Int) {
        
        setFillColor(UIColor.black.cgColor)
        fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        setShouldAntialias(true)
        interpolationQuality = .high
        textMatrix = .identity
        translateBy(x: 0, y: CGFloat(height))
        scaleBy(x: 1, y: -1)
        
        let scaledFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize * scale, nil)
        let line = text._toCTLine(font: scaledFont)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds, .useOpticalBounds])
        
        let drawX = CGFloat(padding)
        let drawY = max((CGFloat(height) - bounds.height) / 2 - bounds.minY, 0)
        
        textPosition = CGPoint(x: drawX, y: drawY)
        CTLineDraw(line, self)
    }
}
