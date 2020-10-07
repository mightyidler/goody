//
//  FriendWishCell.swift
//  goody
//
//  Created by mightyidler on 2020/10/07.
//

import UIKit

class FriendWishCell: UICollectionViewCell {
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemMallNameLabel: UILabel!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemMaskView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        itemMaskView.layer.cornerRadius = 19
        itemMaskView.layer.applySketchShadow(
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
            itemMaskView.layer.applySketchShadow(
                color: UIColor(named: "ShadowColor")!,
                alpha: 1.0,
                x: 0,
                y: 3,
                blur: 12,
                spread: 0)
        }
    }
    
}
