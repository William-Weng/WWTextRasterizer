# WWTextRasterizer
[![Swift-5.7](https://img.shields.io/badge/Swift-5.7-orange.svg?style=flat)](https://developer.apple.com/swift/) [![iOS-16.0](https://img.shields.io/badge/iOS-16.0-pink.svg?style=flat)](https://developer.apple.com/swift/) ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWTextRasterizer) [![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) [![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

### [Introduction](https://swiftpackageindex.com/William-Weng)
- A lightweight Swift tool that converts text into a bitmap (BitMatrix) on iOS, suitable for use cases such as LED displays, small screens, font rasterization, custom font rendering, and dot-matrix type layouts.
- 一個幫你在 iOS 上把文字轉成「點陣圖」（BitMatrix）的 Swift 小工具，適合用在LED、小型顯示器、字型光柵化、自訂字型渲染、點陣字之類的場景。

![](https://github.com/user-attachments/assets/623c42fc-a9f2-47b7-81ce-d76501c6548d)

### [Installation with Swift Package Manager](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)

```bash
dependencies: [
    .package(url: "https://github.com/William-Weng/WWTextRasterizer.git", .upToNextMajor(from: "1.1.0"))
]
```

### [Function](https://peterpanswift.github.io/iphone-bezels/)
|函式|功能|
|-|-|
|convert(_:)|文字轉換成RasterizedText|
|toImage(lightColor:darkColor:scale:)|將數據轉成圖片|
|toLEDImage(ledOnColor:ledOffColor:backgroundColor:dotSize:dotSpacing:useRoundDots:glowOpacity:glowInsetRatio:opaque:)|將光柵數據轉成LED風格圖片|

### Example
```swift
import UIKit
import WWTextRasterizer

final class ViewController: UIViewController {
    
    @IBOutlet weak var ledImageView: UIImageView!
    
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let step = 3.0
    
    private var marqueeFPS = 60
    private var offsetX = 0.0
    private var displayLink: CADisplayLink?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLED()
    }
}

private extension ViewController {
    
    func displayLED() {
        
        let text = "Hello, こんにちは, 안녕하세요, 哈囉"
        
        let config = WWTextRasterizer.Configuration(
            font: .systemFont(ofSize: 48),
            targetHeight: 48,
            threshold: 110,
            horizontalPadding: 5,
            trimHorizontalEmptySpace: true,
            characterGap: 2
        )
        
        let rasterizer = WWTextRasterizer(config: config)
        let result = rasterizer.convert(text)
        let image = result.matrix.toLEDImage()
        
        containerView.frame = view.bounds
        containerView.backgroundColor = .black
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        imageView.image = image
        imageView.frame = CGRect(origin: .zero, size: image.size)
        
        offsetX = floor(containerView.bounds.width)
        imageView.frame.origin.x = offsetX
        imageView.frame.origin.y = floor((containerView.bounds.height - image.size.height) * 0.5)
        
        containerView.addSubview(imageView)
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.preferredFramesPerSecond = marqueeFPS
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func update() {
        
        offsetX -= step
        offsetX = floor(offsetX)
        
        imageView.frame.origin.x = offsetX
        
        guard let image = imageView.image else { return }
        if (offsetX <= -image.size.width) { offsetX = floor(containerView.bounds.width) }
    }
}
```
