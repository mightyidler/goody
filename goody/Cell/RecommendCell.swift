//
//  RecommendCell.swift
//  goody
//
//  Created by mightyidler on 2020/10/14.
//

import UIKit

class RecommendCell: UITableViewCell {

    @IBOutlet weak var recommendImage: UIImageView!
    @IBOutlet weak var recommendTitle: UILabel!
    @IBOutlet weak var recommendMallName: UILabel!
    @IBOutlet weak var recommendPrice: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        recommendImage.layer.cornerRadius = 19
        recommendImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        recommendImage.layer.borderWidth = 0.5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            recommendImage.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        }
    }
}
