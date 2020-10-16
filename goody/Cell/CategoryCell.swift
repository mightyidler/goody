//
//  CategoryCell.swift
//  goody
//
//  Created by mightyidler on 2020/10/13.
//

import UIKit

class CategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var categoryImageView: UIImageView!
    @IBOutlet weak var categoryShadowView: UIView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categoryMaskView: UIView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.categoryMaskView.layer.cornerRadius = 19
        
        
        self.contentView.layer.cornerRadius = 19
        self.contentView.layer.applySketchShadow(
            //color: UIColor.black,
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
            self.contentView.layer.applySketchShadow(
                color: UIColor(named: "ShadowColor2")!,
                alpha: 1.0,
                x: 0,
                y: 0,
                blur: 8,
                spread: 0)
        }
    }
}
