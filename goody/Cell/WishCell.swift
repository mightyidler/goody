//
//  WishCell.swift
//  goody
//
//  Created by mightyidler on 2020/09/30.
//

import UIKit

class WishCell: UICollectionViewCell {
    
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var productTitle: UILabel!
    @IBOutlet weak var productPrice: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var productContentView: UIView!
    @IBOutlet weak var productMaskView: UIView!
    @IBOutlet weak var mallNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        deleteButton.layer.cornerRadius = deleteButton.layer.frame.width / 2
        
        productMaskView.layer.cornerRadius = 19
        productContentView.layer.applySketchShadow(
            color: UIColor(named: "ShadowColor")!,
            alpha: 1.0,
            x: 0,
            y: 3,
            blur: 12,
            spread: 0)
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            productContentView.layer.applySketchShadow(
                color: UIColor(named: "ShadowColor")!,
                alpha: 1.0,
                x: 0,
                y: 3,
                blur: 12,
                spread: 0)
        }
    }
    
    func shakeCell() {
        let shakeAnimation = CABasicAnimation(keyPath: "transform.rotation")
        shakeAnimation.duration = 0.05
        shakeAnimation.repeatCount = 2
        shakeAnimation.autoreverses = true
        let startAngle: Float = (-0.5) * 3.14159/180
        let stopAngle = -startAngle
        shakeAnimation.fromValue = NSNumber(value: startAngle as Float)
        shakeAnimation.toValue = NSNumber(value: 3 * stopAngle as Float)
        shakeAnimation.autoreverses = true
        shakeAnimation.duration = 0.12
        shakeAnimation.repeatCount = 10000
        shakeAnimation.timeOffset = 290 * drand48()

        let layer: CALayer = self.layer
        layer.add(shakeAnimation, forKey:"shaking")
    }

    func stopShakeCell() {
        let layer: CALayer = self.layer
        layer.removeAnimation(forKey: "shaking")
    }
}
