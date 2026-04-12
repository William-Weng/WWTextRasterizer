//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/4/11.
//

import UIKit
import WWTextRasterizer

final class ViewController: UIViewController {
    
    @IBOutlet weak var ledImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLED()
    }
    
    func displayLED() {
        
        let config = WWTextRasterizer.Configuration(
            font: .systemFont(ofSize: 24),
            targetHeight: 64,
            threshold: 110,
            horizontalPadding: 5,
            trimHorizontalEmptySpace: true,
            characterGap: 2
        )
        
        let rasterizer = WWTextRasterizer(config: config)
        let text = "Hello !!!"
        let result = rasterizer.convert(text)
        
        ledImageView.image = result.matrix.toLEDImage()
    }
}
