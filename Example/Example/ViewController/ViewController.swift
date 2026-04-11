//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/4/11.
//

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
