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
    
    /// 產生LED點陣背景影像，可用於模擬電子看板的底層效果
    /// - Parameters:
    ///   - columns: LED 點的列數 (水平數)，需大於 0。
    ///   - rows: LED 點的行數 (垂直數)，需大於 0。
    ///   - ledColor: LED 顏色設定
    ///   - backgroundColor: 底板背景顏色設定
    ///   - dot: LED 點的尺寸、間距與形狀設定。
    ///   - scale: 輸出影像的縮放比例，通常維持 1。
    ///   - opaque: 指定影像是否不透明；若為 `true` 則繪製背景色。
    /// - Returns: 一個包含 LED 點陣背景的 `UIImage`。
    static func renderLEDMatrixBase(columns: Int, rows: Int, ledColor: UIColor = .red.withAlphaComponent(0.12), backgroundColor: UIColor = .black, dot: DotSetting = (size: 4, spacing: 3, type: .square(0.22)), scale: CGFloat = 1.0, opaque: Bool = true) -> UIImage {
        
        precondition(columns > 0 && rows > 0)
        
        let pitch = dot.size + dot.spacing
        let outputSize = CGSize(width: CGFloat(columns) * pitch - dot.spacing, height: CGFloat(rows) * pitch - dot.spacing)
        let renderer = UIGraphicsImageRenderer._build(size: outputSize, scale: scale, opaque: opaque)

        return renderer.image { rendererContext in
            
            let context = rendererContext.cgContext

            if (opaque) {
                context.setFillColor(backgroundColor.cgColor)
                context.fill(CGRect(origin: .zero, size: outputSize))
            }
            
            context.setFillColor(ledColor.cgColor)
            
            for y in 0..<rows {
                for x in 0..<columns {
                    
                    let size = CGSize(width: dot.size, height: dot.size)
                    let origin = CGPoint(x: CGFloat(x) * pitch, y: CGFloat(y) * pitch)
                    let rect = CGRect(origin: origin, size: size)
                    
                    context._drawLedDot(in: rect, roundDotType: dot.type)
                }
            }
        }
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
            var glyphMatrix = char._toBitMatrix(config: config)
            
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
    ///   - useRoundDots: 是否使用圓形 LED
    /// - Returns: UIImage
    func toImage(lightColor: UIColor = .white, darkColor: UIColor = .black, scale: CGFloat = 1.0, opaque: Bool = true, useRoundDots: Bool = false) -> UIImage {
        
        let outputSize = CGSize(width: CGFloat(width) * scale, height: CGFloat(height) * scale)
        let renderer = UIGraphicsImageRenderer._build(size: outputSize, scale: 1, opaque: opaque)

        return renderer.image { rendererContext in
            
            let context = rendererContext.cgContext
            let size: CGSize = .init(width: scale, height: scale)
            if (opaque) {
                context.setFillColor(darkColor.cgColor)
                context.fill(CGRect(origin: .zero, size: outputSize))
            }
            
            for y in 0..<height {
                for x in 0..<width {
                    
                    let origin: CGPoint = .init(x: CGFloat(x) * scale, y: CGFloat(y) * scale)
                    let rect: CGRect = .init(origin: origin, size: size)
                    let color = self[x, y] ? lightColor : darkColor
                    
                    context.setFillColor(color.cgColor)
                    (useRoundDots) ? context.fillEllipse(in: rect) : context.fill(rect)
                }
            }
        }
    }
    
    /// 將光柵數據轉成LED風格圖片
    /// - Parameters:
    ///   - ledColor: LED顏色設定值 (亮點 / 暗點 / 背景)
    ///   - dot: LED點設定值 (大小 / 間距 / 樣式)
    ///   - glow: 光暈設定值 (透明度 / 擴張比例 / 偏移量)
    ///   - opaque: 是否產生不透明圖片
    /// - Returns: UIImage
    func toLEDImage(ledColor: WWTextRasterizer.LEDColorSetting = (on: .red, off: .red.withAlphaComponent(0.12), background: .black), dot: WWTextRasterizer.DotSetting = (size: 4, spacing: 3, type: .circle), glow: WWTextRasterizer.GlowSetting = (opacity: 0.16, insetRatio: 0.18, offset: .zero), opaque: Bool = true) -> UIImage {
        
        let pitch = dot.size + dot.spacing
        let outputSize: CGSize = .init(width: CGFloat(width) * pitch - dot.spacing, height: CGFloat(height) * pitch - dot.spacing)
        let renderer = UIGraphicsImageRenderer._build(size: outputSize, scale: 1, opaque: opaque)
        
        return renderer.image { rendererContext in
            
            let context = rendererContext.cgContext
            
            if (opaque) {
                context.setFillColor(ledColor.background.cgColor)
                context.fill(CGRect(origin: .zero, size: outputSize))
            }
            
            for y in 0..<height {
                for x in 0..<width {
                    context._drawLED(by: self, x: x, y: y, dot: dot, ledColor: ledColor, glow: glow)
                }
            }
        }
    }
    
    /// 在LED點陣面板上渲染文字，產生電子看板效果 (根據內部點陣資料 (`self[sourceX, sourceY]`) 在指定的 LED 面板上點亮對應的 LED 點，支援水平/垂直位移、發光效果，並可控制輸出解析度。)
    /// - Parameters:
    ///   - columns: LED 面板的列數（水平 LED 點數）。
    ///   - rows: LED 面板的行數（垂直 LED 點數）。
    ///   - offsetX: 水平位移量，正值向右移，負值向左移。
    ///   - offsetY: 垂直位移量，正值向下移，負值向上移（預設 0）。
    ///   - ledColor: LED 點亮時的顏色（預設紅色）。
    ///   - dot: LED 點的尺寸、間距與形狀設定。
    ///   - glow: 發光效果設定，包括透明度、內縮比例與偏移。
    ///   - scale: 輸出影像的像素縮放倍率（1.0 = 原始像素大小）。
    /// - Returns: 包含 LED 文字效果的 `UIImage`。
    func renderLEDMatrixText(columns: Int, rows: Int, offsetX: Int, offsetY: Int = 0, ledColor: UIColor = .red, dot: WWTextRasterizer.DotSetting = (size: 4, spacing: 3, type: .square(0.22)), glow: WWTextRasterizer.GlowSetting = (opacity: 0.16, insetRatio: 0.18, offset: .zero), scale: CGFloat = 1.0) -> UIImage {
        
        precondition(columns > 0 && rows > 0)

        let pitch = dot.size + dot.spacing
        let outputSize = CGSize(width: CGFloat(columns) * pitch - dot.spacing, height: CGFloat(rows) * pitch - dot.spacing)
        
        let renderer = UIGraphicsImageRenderer._build(size: outputSize, scale: scale, opaque: false)
        
        return renderer.image { rendererContext in
            
            let context = rendererContext.cgContext
            
            context.setFillColor(ledColor.cgColor)
            
            for panelY in 0..<rows {
                for panelX in 0..<columns {
                    
                    let sourceX = panelX - offsetX
                    let sourceY = panelY - offsetY

                    guard sourceX >= 0, sourceY >= 0 else { continue }
                    guard sourceX < width, sourceY < height else { continue }
                    guard self[sourceX, sourceY] else { continue }

                    let rect = CGRect(x: CGFloat(panelX) * pitch, y: CGFloat(panelY) * pitch, width: dot.size, height: dot.size)

                    context._drawLedDot(in: rect, roundDotType: dot.type)
                    
                    if (glow.opacity) > 0 {
                        let glowRect = rect.insetBy(dx: rect.width * glow.insetRatio, dy: rect.height * glow.insetRatio)
                        context._drawLedDot(in: glowRect, roundDotType: dot.type)
                    }
                }
            }
        }
    }
}
