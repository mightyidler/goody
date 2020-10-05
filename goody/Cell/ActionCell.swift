//
//  ActionCell.swift
//  goody
//
//  Created by mightyidler on 2020/10/03.
//

import UIKit

class ActionCell: UITableViewCell {
    @IBOutlet weak var actionImage: UIImageView!
    @IBOutlet weak var actionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
