//
//  WWTextRasterizer.swift
//  WWTextRasterizer
//
//  Created by William.Weng on 2026/4/11.
//

import UIKit
import CoreText

// MARK: - 文字光柵化
public class WWTextRasterizer {
    
    private let config: Configuration

    public init(config: Configuration) {
        self.config = config
    }
}

// MARK: - 公開函式
public extension WWTextRasterizer {
    
    /// 文字轉換成RasterizedText
    /// - Parameter text: String
    /// - Returns: RasterizedText
    func convert(_ text: String) -> RasterizedText {
        
        var combined = BitMatrix.empty(width: 1, height: config.targetHeight)
        if (text.isEmpty) { return .init(matrix: combined, glyphSlices: []) }
        
        let characters = Array(text)
        var slices: [GlyphSlice] = []
        var currentX = 0
        var isFirstGlyph = true

        for (index, char) in characters.enumerated() {
            
            let range: Range<Int>
            var glyphMatrix = char.toBitMatrix(config: config)
            
            if (config.trimHorizontalEmptySpace) { glyphMatrix = glyphMatrix.trimmedHorizontally() }
            
            defer { slices.append(GlyphSlice(characterIndex: index, character: char, columnRange: range)) }
            
            if (!isFirstGlyph) {
                
                let gap = max(config.characterGap, 0)
                let start = currentX + gap
                let end = start + glyphMatrix.width
                
                range = start..<end
                combined = combined.appending(glyphMatrix, gapColumns: gap)
                currentX = end
                continue
            }
            
            range = 0..<glyphMatrix.width
            combined = glyphMatrix
            currentX = glyphMatrix.width
            isFirstGlyph = false
        }
        
        return .init(matrix: combined, glyphSlices: slices)
    }
}

// MARK: - 公開函式
public extension WWTextRasterizer.BitMatrix {
    
    /// 將光柵數據轉換成一般黑白圖片
    /// - Parameters:
    ///   - lightColor: 亮點顏色
    ///   - darkColor: 暗點顏色
    ///   - scale: 每個邏輯像素放大的倍數
    ///   - opaque: 是否產生不透明圖片
    /// - Returns: UIImage
    func toImage(lightColor: UIColor = .white, darkColor: UIColor = .black, scale: CGFloat = 1.0, opaque: Bool = true) -> UIImage {
        
        let outputSize = CGSize(width: CGFloat(width) * scale, height: CGFloat(height) * scale)
        let format = UIGraphicsImageRendererFormat()
        
        format.scale = 1
        format.opaque = opaque
        
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        
        return renderer.image { rendererContext in
            
            let context = rendererContext.cgContext
            
            if (opaque) {
                context.setFillColor(darkColor.cgColor)
                context.fill(CGRect(origin: .zero, size: outputSize))
            }
            
            for y in 0..<height {
                for x in 0..<width {
                    let rect = CGRect(x: CGFloat(x) * scale, y: CGFloat(y) * scale, width: scale, height: scale)
                    let color = self[x, y] ? lightColor : darkColor
                    context.setFillColor(color.cgColor)
                    context.fill(rect)
                }
            }
        }
    }
    
    /// 將光柵數據轉成LED風格圖片
    /// - Parameters:
    ///   - ledOnColor: 亮點顏色
    ///   - ledOffColor: 暗點顏色
    ///   - backgroundColor: 背景顏色
    ///   - dotSize: 點大小
    ///   - dotSpacing: 點間距
    ///   - useRoundDots: 是否使用圓點
    ///   - glowOpacity: 亮點光暈透明度
    ///   - glowInsetRatio: 光暈擴張比例
    ///   - opaque: 是否產生不透明圖片
    /// - Returns: UIImage
    func toLEDImage(ledOnColor: UIColor = .red, ledOffColor: UIColor = UIColor.red.withAlphaComponent(0.12), backgroundColor: UIColor = .black, dotSize: CGFloat = 4, dotSpacing: CGFloat = 3, useRoundDots: Bool = true, glowOpacity: CGFloat = 0.16, glowInsetRatio: CGFloat = 0.18, opaque: Bool = true) -> UIImage {
        
        let pitch = dotSize + dotSpacing
        let outputSize = CGSize(width: CGFloat(width) * pitch - dotSpacing, height: CGFloat(height) * pitch - dotSpacing)
        let format = UIGraphicsImageRendererFormat()
        
        format.scale = 1
        format.opaque = opaque
        
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        
        return renderer.image { rendererContext in
            
            let context = rendererContext.cgContext
            
            if (opaque) {
                context.setFillColor(backgroundColor.cgColor)
                context.fill(CGRect(origin: .zero, size: outputSize))
            }
            
            for y in 0..<height {
                for x in 0..<width {
                    context.drawLED(by: self, x: x, y: y, ledOnColor: ledOnColor, ledOffColor: ledOffColor, useRoundDots: useRoundDots)
                }
            }
        }
    }
}
