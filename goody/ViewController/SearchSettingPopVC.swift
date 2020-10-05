//
//  SearchSettingPopVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/03.
//

import UIKit

protocol SearchSettingPopDelegate: class {
    func optionPicker(picker: SearchSettingPopVC, shopOption: Int, sortOption: Int)
}

class SearchSettingPopVC: BottomPopupViewController {
    
    weak var delegate: SearchSettingPopDelegate?
    
    var height: CGFloat?
    var topCornerRadius: CGFloat?
    var presentDuration: Double?
    var dismissDuration: Double?
    var shouldDismissInteractivelty: Bool?
    var selectIndexPath: IndexPath!
    
    var impactFeedBack: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator()
    let selectFeedBack: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
    
    let shopCount: Int = 13
    //let shopList: [String] = ["","다나와","쿠팡","스타일쉐어","29cm","g마켓","옥션","11번가","위메프","이마트몰","티몬","인터파크"]
    //["랭킹순", "최신순", "낮은 가격순", "높은 가격순"]
    let sortOption: [String] = ["sim", "date", "asc", "dsc"]
    
    var selectSort: Int = 0
    var selectShop: Int = 0
    
    @IBOutlet weak var sortSegmentedControl: UISegmentedControl!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet var parentView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        shadowView.layer.applySketchShadow(
            color: UIColor(named: "ShadowColor")!,
            alpha: 1.0,
            x: 0,
            y: -10,
            blur: 12,
            spread: 0)
        let path = UIBezierPath(roundedRect: self.view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 38.0, height: 0))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.contentView.bounds
        maskLayer.path = path.cgPath
        self.contentView.layer.mask = maskLayer
        self.sortSegmentedControl.selectedSegmentIndex = self.selectSort
        self.collectionView.reloadData()
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            shadowView.layer.applySketchShadow(
                color: UIColor(named: "ShadowColor")!,
                alpha: 1.0,
                x: 0,
                y: -10,
                blur: 12,
                spread: 0)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate?.optionPicker(picker: self, shopOption: self.selectShop, sortOption: self.sortSegmentedControl.selectedSegmentIndex)
    }
    
    @IBAction func dismissButtonAction(_ sender: UIButton) {
        self.impactFeedBack.prepare()
        self.impactFeedBack = UIImpactFeedbackGenerator(style: .light)
        self.impactFeedBack.impactOccurred()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sortSegmentedValueChanged(_ sender: UISegmentedControl) {
        self.selectFeedBack.prepare()
        self.selectFeedBack.selectionChanged()
    }

    // Bottom popup attribute variables
    // You can override the desired variable to change appearance
    
    override var popupHeight: CGFloat { return height ?? CGFloat(300) }
    
    override var popupTopCornerRadius: CGFloat { return topCornerRadius ?? CGFloat(10) }
    
    override var popupPresentDuration: Double { return presentDuration ?? 1.0 }
    
    override var popupDismissDuration: Double { return dismissDuration ?? 1.0 }
    
    override var popupShouldDismissInteractivelty: Bool { return shouldDismissInteractivelty ?? true }
    
    override var popupDimmingViewAlpha: CGFloat { return BottomPopupConstants.kDimmingViewDefaultAlphaValue }
}


extension SearchSettingPopVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectFeedBack.prepare()
        self.selectFeedBack.selectionChanged()
        self.selectShop = indexPath.row
        self.collectionView.reloadData()
    }  
}

extension SearchSettingPopVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shopCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let shopLogoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "shopLogoCell", for: indexPath) as! ShopLogoCell
        if indexPath.row == selectShop {
            shopLogoCell.contentView.layer.opacity = 1.0
            shopLogoCell.shadowView.layer.opacity = 1.0
        } else {
            shopLogoCell.contentView.layer.opacity = 0.22
            shopLogoCell.shadowView.layer.opacity = 0.0
        }
        
        if let imageView = shopLogoCell.logoImageView {
            imageView.image = UIImage(named: "logo\(indexPath.row)")
        }
        
        return shopLogoCell
    }
    
    
}
