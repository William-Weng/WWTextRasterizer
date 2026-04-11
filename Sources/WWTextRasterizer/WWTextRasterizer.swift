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
    
    private let config: WWTextRasterizer.Configuration

    public init(config: WWTextRasterizer.Configuration) {
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
    
    /// 將光柵數據轉換成圖片
    /// - Parameters:
    ///   - lightColor: lightColor
    ///   - darkColor: darkColor
    ///   - scale: CGFloat
    /// - Returns: UIImage
    func toImage(lightColor: UIColor = .white, darkColor: UIColor = .black, scale: CGFloat = 1.0) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: CGFloat(width) * scale, height: CGFloat(height) * scale))
        
        return renderer.image { context in
            
            let cellW = scale
            let cellH = scale
            
            for y in 0..<height {
                for x in 0..<width {
                    let rect = CGRect(x: CGFloat(x) * cellW, y: CGFloat(y) * cellH, width: cellW, height: cellH)
                    let color = self[x, y] ? darkColor : lightColor
                    color.setFill()
                    context.fill(rect)
                }
            }
        }
    }
}
