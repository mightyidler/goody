//
//  SearchVC.swift
//  goody
//
//  Created by mightyidler on 2020/09/30.
//

import UIKit
import CoreData
import Alamofire
import Kingfisher
import SwiftyJSON
import CoreHaptics

struct product {
    var title: String
    var link: String
    var lprice: String
    var mallName: String
    var image: String
}

class SearchVC: UIViewController, BottomPopupDelegate, TabBarReselectHandling {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchTextFieldView: UIView!
    @IBOutlet weak var cancelButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var changeShopView: UIView!
    @IBOutlet weak var changeShopButton: UIButton!
    var impactFeedBack: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator()
    
    private var nowVC: UIViewController!
    var searchResult: [product] = []
    var isTheEnd: Bool = false
    var start: Int = 1
    var tempSearchString: String!
    var apiCalled: Bool = false
    var isSearching: Bool = false
    
    let shopList: [String] = ["","네이버","쿠팡","G마켓","옥션","11번가","무신사","스타일쉐어","29CM","마켓컬리","위메프","이마트몰","티몬","인터파크"]
    //["랭킹순", "최신순", "낮은 가격순", "높은 가격순"]
    let sortList: [String] = ["sim", "date", "asc", "dsc"]
    
    var SelectedSort: Int = 0
    var selectedShop: Int = 0
    
    //recent search list from core data
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    //Header bar seperator
    let border = CALayer()
    
    //table spinner
    let spinner = UIActivityIndicatorView(style: .medium)
    
    //table empty message view
    let emptyMessageView = UIView()
    let emptyMessageLabel = UILabel()

    func handleReselect() {
        self.tableView.setContentOffset(.zero, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        //self.tabBarController?.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.searchTextField.delegate = self
        
        //ui setting
        searchTextFieldView.layer.cornerRadius = 12
        changeShopView.layer.cornerRadius = 22
        changeShopButton.layer.cornerRadius = 18
        if let shadowColor = UIColor(named: "ShadowColor2") {
            changeShopView.layer.applySketchShadow(
                color: shadowColor,
                alpha: 1.0,
                x: 0,
                y: 1,
                blur: 12,
                spread: 0)
        }

        //search bar seperator
        if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.header.frame.size.height - 1, width: self.header.frame.size.width, height: 1)
        self.header.layer.addSublayer(border)
        
        //set table spinner
        spinner.startAnimating()
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(32))
        self.tableView.tableFooterView = UIView()
        
        //empty table message
        emptyMessageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50)
        
        emptyMessageLabel.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 50)
        emptyMessageLabel.text = "검색결과가 없습니다."
        emptyMessageLabel.font = UIFont(name: "NanumSquareOTFR", size: 15)
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.textColor = UIColor(named: "SecondLabelColor")
        emptyMessageView.addSubview(emptyMessageLabel)
        
        self.searchTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        isSearching = true
        self.tableView.reloadData()
        
        if let logo = UIImage(named: "logo\(self.selectedShop)") {
            self.changeShopButton.setImage(logo, for: .normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.changeShopView.layer.opacity = 1.0
        UIView.animate(withDuration: 1,
                delay: 0,
                options: [.autoreverse, .repeat],
                animations: {
                    self.changeShopView.layer.opacity = 0.0
                  },
                completion: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.changeShopView.layer.removeAllAnimations()
        self.view.layer.removeAllAnimations()
        self.view.layoutIfNeeded()
    }
    
    
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
            if let shadowColor = UIColor(named: "ShadowColor2") {
                changeShopView.layer.applySketchShadow(
                    color: shadowColor,
                    alpha: 1.0,
                    x: 0,
                    y: 1,
                    blur: 12,
                    spread: 0)
            }
        }
    }
    
    func searchInit() {
        self.tableView.setContentOffset(CGPoint.zero, animated: false)
        searchResult = []
        isTheEnd = false
        start = 1
        tempSearchString = nil
        apiCalled = false
        isSearching = false
    }
    
    //check text field is empty, then show recent search table
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            if !text.isEmptyOrWhitespace() {
                self.isSearching = true
                self.tableView.tableFooterView = UIView()
                self.tableView.reloadData()
            }
        }
        
        
    }
//    @objc func segconChanged(segcon: UISegmentedControl) {
//        self.SelectedSort = segcon.selectedSegmentIndex
//
//        self.searchTextField.resignFirstResponder()
//        if let text = self.searchTextField.text {
//            if !(text == "") {
//                self.searchInit()
//                self.tempSearchString = text
//                self.tableView.tableFooterView = spinner
//                self.appendRecentSearch(text: text)
//                DispatchQueue.global(qos: .userInitiated).async{
//                    self.fetchNaverAPI(text: text)
//                }
//            }
//
//        }
//
//    }
    @IBAction func cancelButtonAction(_ sender: UIButton) {
        self.searchTextField.resignFirstResponder()
        self.searchTextField.text = ""
        self.isSearching = true
        self.tableView.reloadData()
        self.tableView.tableFooterView = UIView()
        cancleButtonInAndOut(show: false)
    }
    
    @IBAction func changeShopButtonAction(_ sender: UIButton) {
        guard let popVC = self.storyboard?.instantiateViewController(withIdentifier: "SearchSettingPopVC") as? SearchSettingPopVC else {
            return
        }
        self.impactFeedBack.prepare()
        self.impactFeedBack = UIImpactFeedbackGenerator(style: .medium)
        self.impactFeedBack.impactOccurred()
        popVC.delegate = self
        popVC.selectShop = self.selectedShop
        popVC.selectSort = self.SelectedSort
        popVC.height = 300
        popVC.topCornerRadius = 0
        popVC.presentDuration = 0.3
        popVC.dismissDuration = 0.3
        popVC.shouldDismissInteractivelty = true
        popVC.popupDelegate = self
        present(popVC, animated: true, completion: nil)
    }
}

//extension SearchVC: UITabBarControllerDelegate {
//    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
//        let tabBarIndex = tabBarController.selectedIndex
//        print(tabBarIndex)
//        if tabBarIndex == 1 {
//            self.tableView.setContentOffset(CGPoint.zero, animated: true)
//        }
//        self.nowVC = viewController
//    }
//}

extension SearchVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if(searchTextField.isEqual(self.searchTextField)){
            self.searchTextField.resignFirstResponder()
            if let text = self.searchTextField.text {
                if !text.isEmptyOrWhitespace() {
                    self.searchInit()
                    self.tempSearchString = text
                    self.tableView.tableFooterView = spinner
                    self.appendRecentSearch(text: text)
                    DispatchQueue.global(qos: .userInitiated).async{
                        self.fetchNaverAPI(text: text)
                    }
                }
                
            }
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        cancleButtonInAndOut(show: true)
    }
    
    func cancleButtonInAndOut(show: Bool) {
        if show {
            self.cancelButtonTrailing.constant = 10
        } else {
            self.cancelButtonTrailing.constant = -44
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.view.layoutIfNeeded()
        }
    }
}

//function for Core Data
extension SearchVC {
    //fetch list from core data
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RecentSearch")
        let result = try! context.fetch(fetchRequest)
        return result
    }
    
    //delete selected object from core data
    func delete(object: NSManagedObject) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        context.delete(object)
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    //append searched item to core data
    func appendRecentSearch(text: String) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: "RecentSearch", into: context)
        object.setValue(text, forKey: "text")
        
        //check and remove duplicate object
        for (index, recrd) in self.list.enumerated() {
            let listText = recrd.value(forKey: "text") as? String
            if text == listText {
                let record = self.list[index]
                context.delete(record)
            }
        }
        //append object
        do {
            try context.save()
            self.list.append(object)
            list = { return self.fetch() }()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    //remove selected recent search item
    @objc func removeRecentSearch(_ sender: UIButton) {
        let record = self.list[self.list.count - sender.tag - 1]
        if self.delete(object: record) {
            self.list.remove(at: sender.tag)
            list = { return self.fetch() }()
            self.tableView.reloadData()
        }
    }
    
    //remove all
    @objc func removeAllRecentSearch(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "RecentSearch")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            list = { return self.fetch() }()
            self.tableView.reloadData()
        } catch {
            context.rollback()
        }
    }
}

extension SearchVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //if recent search state: select row for search
        guard !isSearching else {
            self.searchTextField.resignFirstResponder()
            let text = self.list[self.list.count - indexPath.row - 1].value(forKey: "text") as? String
            if let text = text {
                self.searchTextField.text = text
                self.searchInit()
                self.tempSearchString = text
                self.appendRecentSearch(text: text)
                self.fetchNaverAPI(text: text)
            }
            cancleButtonInAndOut(show: true)
            return
        }
        
        guard let productDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "ProductDetailVC") as? ProductDetailVC else {
            return
        }
        productDetailVC.product = self.searchResult[indexPath.row]
        show(productDetailVC, sender: indexPath)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.tableView {
            searchBarCheck(contentOffset: scrollView.contentOffset.y)
        }
        
        guard !self.isSearching else {
            return
        }
        let height: CGFloat = scrollView.frame.size.height
        let contentYOffset: CGFloat = scrollView.contentOffset.y
        let scrollViewHeight: CGFloat = scrollView.contentSize.height
        let distanceFromBottom: CGFloat = scrollViewHeight - contentYOffset
        
        if distanceFromBottom < height {
            if !apiCalled && self.searchResult.count != 0 && !self.isTheEnd {
                DispatchQueue.global(qos: .userInitiated).async{
                    self.fetchNaverAPI(text: self.tempSearchString)
                }
            }
        }
    }
    //highlight table row
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }
    }
    
    //unhighlight table row
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height:CGFloat = CGFloat()
        
        if !isSearching {
            height = 160
        } else {
            height = 44
        }
        
        return height
    }
}

extension SearchVC: UITableViewDataSource {
    //set section header height
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //serch state
        if isSearching {
            return 50
        }
        
        //result state
        //return 39
        return 0
    }
    
    //set section header
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        //search state
        if isSearching {
            //header
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
            headerView.backgroundColor = UIColor(named: "BackgroundColor")
            //header label
            let label = UILabel()
            label.textAlignment = .left
            label.frame = CGRect.init(x: 20, y: 5, width: 100, height: headerView.frame.height-10)
            label.text = "최근 검색어"
            label.font = UIFont(name: "NanumSquareOTFEB", size: 20)
            label.textColor = UIColor(named: "FirstLabelColor")
            
            //header button for remove all recent search list
            let button = UIButton()
            button.contentHorizontalAlignment = .left
            button.contentVerticalAlignment = .center
            button.frame = CGRect.init(x: headerView.frame.width - 84 , y: 0, width: 80, height: 50)
            button.setTitle("모두 제거", for: .normal)
            button.contentHorizontalAlignment = .left
            button.titleLabel?.font = UIFont(name: "NanumSquareOTFB", size: 15)
            button.setTitleColor(UIColor(named: "ThirdLabelColor"), for: .normal)
            button.addTarget(self, action: #selector(removeAllRecentSearch(_:)), for: .touchUpInside)
            
            headerView.addSubview(label)
            headerView.addSubview(button)
            return headerView
        }
//        else {
            //header
//            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 39))
//            headerView.backgroundColor = UIColor(named: "BackgroundColor")
//
//            let segmentControl = UISegmentedControl(items: self.segmentItems)
//            segmentControl.frame = CGRect.init(x: 20, y: 0, width: tableView.frame.width - 40, height: 31)
//            segmentControl.addTarget(self, action: #selector(segconChanged(segcon:)), for: .valueChanged)
//            segmentControl.selectedSegmentIndex = self.SelectedSort
//            headerView.addSubview(segmentControl)
//            return headerView
//        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return self.list.count
        } else {
            return self.searchResult.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //search state:
        if isSearching {
            let recentSearchCell = tableView.dequeueReusableCell(withIdentifier: "recentSearchCell", for: indexPath) as! RecentSearchCell
            
            if let text = recentSearchCell.recentText {
                text.text = self.list[self.list.count - indexPath.row - 1].value(forKey: "text") as? String
                
                //hide seperator
                recentSearchCell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                recentSearchCell.directionalLayoutMargins = .zero
            }
            
            if let button = recentSearchCell.removeButton {
                button.tag = indexPath.row
                button.addTarget(self, action: #selector(removeRecentSearch(_:)), for: .touchUpInside)
            }
            return recentSearchCell
        } else {
            let resultCell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as! ResultCell
            
            if self.searchResult.indices.contains(indexPath.row) {
                let item = self.searchResult[indexPath.row]
                
                if let cellImage = resultCell.productImage {
                    let url = URL(string: item.image)
                    let processor = DownsamplingImageProcessor(size: cellImage.bounds.size)
                        |> ResizingImageProcessor(referenceSize: CGSize(width: 140.0, height: 140), mode: .aspectFill)
                    cellImage.kf.indicatorType = .activity
                    cellImage.kf.setImage(
                        with: url,
                        options: [
                            .processor(processor),
                            .scaleFactor(UIScreen.main.scale),
                            .transition(.fade(0.1)),
                            .cacheMemoryOnly
                        ]
                    )
                }
                
                if let cellTitle = resultCell.productTitle {
                    cellTitle.text = item.title.stringByDecodingHTMLEntities
                }
                if let cellMallName = resultCell.mallName {
                    cellMallName.text = item.mallName
                }
                if let cellPrice = resultCell.price {
                    cellPrice.text = item.lprice.wonRepresentation
                }
            }
            return resultCell
        }
    }
    
    func makeNakeString(string : String) -> String {
        do {
            let regex =  "<[^>]+>"
            let expr = try NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive)
            let replacement = expr.stringByReplacingMatches(in: string, options: [], range: NSMakeRange(0, string.count), withTemplate: "")
            return replacement
        } catch {
            return ""
        }
    }
    
    func addTargetShopText(text: String) -> String {
        guard self.selectedShop != 0 else {
            return text
        }
        return "\(self.shopList[self.selectedShop]) \(text)"
    }
    
    func fetchNaverAPI(text : String) {
        self.apiCalled = true
        let addedText = self.addTargetShopText(text: text)
        print(addedText)
        print(self.sortList[self.SelectedSort])
        
        if let str = addedText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            let headers: HTTPHeaders = [
                "X-Naver-Client-Id": "ntvxCZLKZOsFEP1la0sf",
                "X-Naver-Client-Secret": "lld52ajljo"
            ]
            AF.request("https://openapi.naver.com/v1/search/shop.json?query=\(str)&start=\(start)&display=20&sort=\(self.sortList[self.SelectedSort])", headers: headers).responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    print(json)
                    if !(json["display"].exists()) {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.apiCalled = false
                            self.emptyMessageLabel.text = "검색결과가 없습니다."
                            self.tableView.tableFooterView = self.emptyMessageView
                        }
                    }
                    
                    if let display = json["display"].int {
                        self.start += display
                    }

                    if let total = json["total"].int {
                        if self.start > total {
                            self.isTheEnd = true
                            
                            guard total != 0  else {
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    self.apiCalled = false
                                    self.emptyMessageLabel.text = "검색결과가 없습니다."
                                    self.tableView.tableFooterView = self.emptyMessageView
                                }
                                return
                            }
                            
                            DispatchQueue.main.async {
                                self.tableView.tableFooterView = UIView()
                            }
                        }
                    }

                    if let items = json["items"].array {
                        for item in items {
                            if let link = item["link"].string,
                               let lprice = item["lprice"].string,
                               let title = item["title"].string,
                               let mallName = item["mallName"].string,
                               let image = item["image"].string {
                                let title = self.makeNakeString(string: title)
                                let result = product.init(title: title, link: link, lprice: lprice, mallName: mallName, image: image)
                                
                                if mallName == self.shopList[self.selectedShop] || self.selectedShop == 0 {
                                    self.searchResult.append(result)
                                }
                                
                                
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.apiCalled = false
//                        if let total = json["total"].int {
//                            print(total)
//                            if self.searchResult.count < total {
//                                self.apiCalled = true
//                                self.fetchNaverAPI(text: text)
//                            }
//                        }
                        
                    }
                    break
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.apiCalled = false
                        self.emptyMessageLabel.text = "데이터를 찾을 수 없습니다."
                        self.tableView.tableFooterView = self.emptyMessageView
                    }
                    break
                }
            }
            
        }
    }
    
}

extension SearchVC {
    //check is bar at the top
    func searchBarCheck(contentOffset: CGFloat) {
        if contentOffset < 10.0 {
            //is top
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.border.opacity = 0.0
            })
        } else {
            //is not top
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.border.opacity = 1.0
            })
        }
    }
}



extension SearchVC: SearchSettingPopDelegate {
    func changeLogo(picker: SearchSettingPopVC, shopOption: Int) {
        if let logo = UIImage(named: "logo\(shopOption)") {
            self.changeShopButton.setImage(logo, for: .normal)
        }
    }
    func optionPicker(picker: SearchSettingPopVC, shopOption: Int, sortOption: Int) {
        print(shopOption)
        print(sortOption)
        if let logo = UIImage(named: "logo\(shopOption)") {
            self.changeShopButton.setImage(logo, for: .normal)
        }
        if self.selectedShop != shopOption || self.SelectedSort != sortOption {
            self.SelectedSort = sortOption
            self.selectedShop = shopOption
            if let text = searchTextField.text {
                if !text.isEmptyOrWhitespace() {
                    self.searchInit()
                    self.tempSearchString = text
                    self.tableView.tableFooterView = spinner
                    self.appendRecentSearch(text: text)
                    DispatchQueue.global(qos: .userInitiated).async{
                        self.fetchNaverAPI(text: text)
                    }
                }
            }
            
        }
    }

}
