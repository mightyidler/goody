//
//  ResultCell.swift
//  goody
//
//  Created by mightyidler on 2020/09/30.
//

import UIKit

class ResultCell: UITableViewCell {

    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var productTitle: UILabel!
    @IBOutlet weak var mallName: UILabel!
    @IBOutlet weak var price: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        productImage.layer.cornerRadius = 19
        productImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        productImage.layer.borderWidth = 0.5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            productImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        }
    }
}
