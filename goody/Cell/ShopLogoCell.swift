//
//  ShopLogoCell.swift
//  goody
//
//  Created by mightyidler on 2020/10/04.
//

import UIKit

class ShopLogoCell: UICollectionViewCell {
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.shadowView.layer.cornerRadius = self.shadowView.bounds.height / 2
        self.logoImageView.layer.cornerRadius = self.logoImageView.frame.height / 2
        shadowView.layer.applySketchShadow(
            //color: UIColor.black,
            color: UIColor(named: "ShadowColor2")!,
            alpha: 1.0,
            x: 0,
            y: 0,
            blur: 8,
            spread: 0)
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            shadowView.layer.applySketchShadow(
                color: UIColor(named: "ShadowColor2")!,
                alpha: 1.0,
                x: 0,
                y: 0,
                blur: 8,
                spread: 0)
        }
    }
}
