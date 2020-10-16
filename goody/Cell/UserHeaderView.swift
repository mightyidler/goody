//
//  UserHeader.swift
//  goody
//
//  Created by mightyidler on 2020/10/16.
//

import UIKit

class UserHeaderView: UICollectionReusableView {
        
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profileImage.layer.cornerRadius = 19
        profileImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        profileImage.layer.borderWidth = 0.5
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            profileImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        }
    }
}
