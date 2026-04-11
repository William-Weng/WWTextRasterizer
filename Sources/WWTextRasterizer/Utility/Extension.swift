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
}
