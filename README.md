# WWTextRasterizer
[![Swift-5.7](https://img.shields.io/badge/Swift-5.7-orange.svg?style=flat)](https://developer.apple.com/swift/) [![iOS-16.0](https://img.shields.io/badge/iOS-16.0-pink.svg?style=flat)](https://developer.apple.com/swift/) ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWTextRasterizer) [![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) [![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

### [Introduction](https://swiftpackageindex.com/William-Weng)
- A lightweight Swift tool that converts text into a bitmap (BitMatrix) on iOS, suitable for use cases such as LED displays, small screens, font rasterization, custom font rendering, and dot-matrix type layouts.
- 一個幫你在 iOS 上把文字轉成「點陣圖」（BitMatrix）的 Swift 小工具，適合用在LED、小型顯示器、字型光柵化、自訂字型渲染、點陣字之類的場景。

### [Installation with Swift Package Manager](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)

```bash
dependencies: [
    .package(url: "https://github.com/William-Weng/WWTextRasterizer.git", .upToNextMajor(from: "1.0.0"))
]
```

### [Function](https://peterpanswift.github.io/iphone-bezels/)
|函式|功能|
|-|-|
|convert(_:)|文字轉換成RasterizedText|
|toImage(lightColor:darkColor:scale:)|將數據轉成圖片|

### Example
```swift
import UIKit
import WWTextRasterizer

final class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func display(_ sender: UIBarButtonItem) {
        
        let config = WWTextRasterizer.Configuration(
            font: UIFont.systemFont(ofSize: 24),
            targetHeight: 40,
            threshold: 110,
            horizontalPadding: 5,
            trimHorizontalEmptySpace: true,
            characterGap: 2
        )
        
        let rasterizer = WWTextRasterizer(config: config)
        let text = textField.text ?? ""
        let result = rasterizer.convert(text)
        
        let image = result.matrix.toImage(scale: 4)
        imageView.image = image
    }
}
```
