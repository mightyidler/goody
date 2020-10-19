//
//  ProfileCell.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit

class ProfileCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var ImageChangeButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        profileImage.layer.cornerRadius = 19
        profileImage.layer.borderWidth = 1
        profileImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        // Configure the view for the selected state
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            profileImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        }
    }
    
    
}
