//
//  ItemSaveView.swift
//  goody
//
//  Created by mightyidler on 2020/10/03.
//

import UIKit

class ItemSaveView: UIView {
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemStateLabel: UILabel!
    @IBOutlet weak var itemMaskView: UIView!
    @IBOutlet var contentView: ItemSaveView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//        commonInit()
//    }

    private func commonInit() {
        Bundle.main.loadNibNamed("ItemSaveView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}
