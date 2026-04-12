//
//  Model.swift
//  WWTextRasterizer
//
//  Created by William.Weng on 2026/4/11.
//

import UIKit

// MARK: - 模型
public extension WWTextRasterizer {
    
    /// 記錄句子總切片訊息
    struct RasterizedText: Equatable {
        
        public let matrix: BitMatrix
        public let glyphSlices: [GlyphSlice]
        
        public init(matrix: BitMatrix, glyphSlices: [GlyphSlice]) {
            self.matrix = matrix
            self.glyphSlices = glyphSlices
        }
    }
    
    /// 相關設定值
    struct Configuration {
        
        var font: UIFont
        var targetHeight: Int
        var threshold: UInt8
        var horizontalPadding: Int
        var trimHorizontalEmptySpace: Bool
        var characterGap: Int
        
        /// 初始化
        /// - Parameters:
        ///   - font: 字型
        ///   - targetHeight: 高度
        ///   - threshold: 取樣臨界值
        ///   - horizontalPadding: 水平間隔
        ///   - trimHorizontalEmptySpace: 去除空白
        ///   - characterGap: 字元間距
        public init(font: UIFont, targetHeight: Int, threshold: UInt8, horizontalPadding: Int, trimHorizontalEmptySpace: Bool, characterGap: Int) {
            self.font = font
            self.targetHeight = targetHeight
            self.threshold = threshold
            self.horizontalPadding = horizontalPadding
            self.trimHorizontalEmptySpace = trimHorizontalEmptySpace
            self.characterGap = characterGap
        }
    }
    
    /// 句子整體被畫出來之後的黑白畫素圖 (亮 / 暗)
    struct BitMatrix: Equatable {
        
        public let width: Int
        public let height: Int
        public var pixels: [Bool] { storage }
        
        private let storage: [Bool]
        
        public init(width: Int, height: Int, pixels: [Bool]) {
            precondition(width > 0 && height > 0)
            precondition(pixels.count == width * height)
            self.width = width
            self.height = height
            self.storage = pixels
        }
        
        public subscript(x: Int, y: Int) -> Bool {
            guard checkRange(x: x, y: y) else { return false }
            return storage[y * width + x]
        }
    }
    
    /// 記錄單字切片訊息 => "歡" (45..<67)
    struct GlyphSlice: Equatable {
        
        public let characterIndex: Int
        public let character: Character
        public let columnRange: Range<Int>
    }
}

// MARK: - 公用函數 for BitMatrix
extension WWTextRasterizer.BitMatrix {
    
    /// 用來產生一個指定大小但全空白的BitMatrix
    /// - Parameters:
    ///   - width: Int
    ///   - height: Int
    /// - Returns: BitMatrix
    static func empty(width: Int = 1, height: Int) -> Self {
        Self(width: max(width, 1), height: max(height, 1), pixels: Array(repeating: false, count: max(width, 1) * max(height, 1)))
    }
}

// MARK: - 公用函數 for BitMatrix
extension WWTextRasterizer.BitMatrix {
    
    /// 取出整行畫素
    /// - Parameter x: Int
    /// - Returns: [Bool]
    func column(at x: Int) -> [Bool] {
        return !checkColumn(at: x) ? Array(repeating: false, count: height) : (0..<height).map { self[x, $0] }
    }
    
    /// 水平方向裁白邊 (為了做連續排版，而去除多餘空白 / 找左右邊界)
    /// - Returns: BitMatrix
    func trimmedHorizontally() -> Self {
        
        var (left, right) = fitBoundary(width: width, height: height)
        
        if (left > right) { return Self(width: 1, height: height, pixels: Array(repeating: false, count: height)) }
        
        let newWidth = right - left + 1
        var newPixels = newHorizontalPixels(from: left, width: newWidth, height: height)
        
        return Self(width: newWidth, height: height, pixels: newPixels)
    }
    
    /// 水平串接下一個BitMatrix
    /// - Parameters:
    ///   - other: BitMatrix
    ///   - gapColumns: 間隔
    /// - Returns: BitMatrix
    func appending(_ other: Self, gapColumns: Int = 0) -> Self {
        precondition(height == other.height, "Matrix heights must match")
        let gap = max(gapColumns, 0)
        let newWidth = width + gap + other.width
        var newPixels = Array(repeating: false, count: newWidth * height)

        for y in 0..<height {
            for x in 0..<width { newPixels[y * newWidth + x] = self[x, y] }
            for x in 0..<other.width { newPixels[y * newWidth + (width + gap + x)] = other[x, y] }
        }
        
        return Self(width: newWidth, height: height, pixels: newPixels)
    }
}

// MARK: - 小工具 for BitMatrix
private extension WWTextRasterizer.BitMatrix {
    
    /// 檢查座標 (x, y) 是否在矩陣內部
    /// - Parameters:
    ///   - x: Int
    ///   - y: Int
    /// - Returns: Bool
    func checkRange(x: Int, y: Int) -> Bool {
        guard x >= 0, x < width, y >= 0, y < height else { return false }
        return true
    }
    
    /// 檢查座標 x 是否在範圍內 (0 <= x < width)
    /// - Parameters:
    ///   - x: Int
    func checkColumn(at x: Int) -> Bool {
        if (x < 0) { return false }
        if (x >= width) { return false }
        return true
    }
    
    /// 尋找適合的左右邊界 (沒有多餘空白)
    /// - Parameters:
    ///   - width: Int
    ///   - height: Int
    /// - Returns: WWTextRasterizer.Boundary
    func fitBoundary(width: Int, height: Int) -> WWTextRasterizer.Boundary {
        
        var left = 0
        var right = width - 1
        
        while (left < width) && !(0..<height).contains(where: { self[left, $0] }) { left += 1 }
        while (right >= left) && !(0..<height).contains(where: { self[right, $0] }) { right -= 1 }
        
        return (left: left, right: right)
    }
    
    /// 重新產生新的水平畫素值 (一個一個填回去)
    /// - Parameters:
    ///   - left: Int
    ///   - width: Int
    ///   - height: Int
    /// - Returns: [Bool]
    func newHorizontalPixels(from left: Int, width: Int, height: Int) -> [Bool] {
        
        var newPixels = Array(repeating: false, count: width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                newPixels[y * width + x] = self[left + x, y]
            }
        }
        
        return newPixels
    }
}

