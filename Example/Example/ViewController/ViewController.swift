//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/4/11.
//

import UIKit
import WWTextRasterizer

final class ViewController: UIViewController {
        
    @IBOutlet weak var containerView: UIImageView!
    
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
