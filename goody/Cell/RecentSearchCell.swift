//
//  RecentSearchCell.swift
//  goody
//
//  Created by mightyidler on 2020/09/30.
//

import UIKit

class RecentSearchCell: UITableViewCell {

    @IBOutlet weak var recentText: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
