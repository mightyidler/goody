//
//  FriendCell.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit

class FriendCell: UITableViewCell {
    @IBOutlet weak var friendImage: UIImageView!
    @IBOutlet weak var friendName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        friendImage.layer.cornerRadius = 19
        friendImage.layer.borderWidth = 1
        friendImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            friendImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
