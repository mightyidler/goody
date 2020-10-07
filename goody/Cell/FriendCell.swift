//
//  FriendCell.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit

class FriendCell: UICollectionViewCell {
//    @IBOutlet weak var friendImage: UIImageView!
//    @IBOutlet weak var friendName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileLabel: UILabel!
    @IBOutlet weak var profileMaskView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        profileImage.layer.cornerRadius = profileImage.frame.height / 2
        profileMaskView.layer.cornerRadius = profileMaskView.frame.height / 2
        
        profileMaskView.layer.borderWidth = 2
        //profileMaskView.layer.borderColor = UIColor(named: "ShadowColor2")?.cgColor
        profileMaskView.layer.borderColor = UIColor.systemIndigo.cgColor
        
        
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            //profileMaskView.layer.borderColor = UIColor(named: "ShadowColor2")?.cgColor
            profileMaskView.layer.borderColor = UIColor.systemIndigo.cgColor
        }
    }
}
