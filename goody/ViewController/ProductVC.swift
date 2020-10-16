//
//  ProductVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/09.
//

import UIKit
import Kingfisher
import Alamofire
import SwiftyJSON

class ProductVC: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    let imageView = UIImageView()
    var item: product!
    var recomendItems: [product] = []
    var start: Int = 1
    var searchContext: String!
    let screenWidth = UIScreen.main.bounds.size.width
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        backButton.layer.cornerRadius = backButton.frame.height / 2
        tableView.contentInset = UIEdgeInsets(top: screenWidth, left: 0, bottom: 0, right: 0)
        
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: screenWidth)
        productImageLoad(imageView: imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.insertSubview(imageView, belowSubview: backButton)

        searchContext = "\(item.category2) \(item.category3)"
        self.fetchNaverAPI(text: searchContext)
    }
    
    func productImageLoad(imageView: UIImageView) {
        if let url = URL(string: item.image) {
            print(item.link)
            let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                |> ResizingImageProcessor(referenceSize: CGSize(width: imageView.frame.width, height: imageView.frame.height), mode: .aspectFill)
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(
                with: url,
                options: [
                    .processor(processor),
                    .transition(.fade(0.1)),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheMemoryOnly
                ]
            )
        }
        
    }

    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func gotoDetailPage(_ sender: UIButton) {
        guard let productDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "ProductDetailVC") as? ProductDetailVC else {
            return
        }
        productDetailVC.product = self.item
        present(productDetailVC, animated: true, completion: nil)
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
    
    func fetchNaverAPI(text : String) {
        if let str = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            let headers: HTTPHeaders = [
                "X-Naver-Client-Id": "ntvxCZLKZOsFEP1la0sf",
                "X-Naver-Client-Secret": "lld52ajljo"
            ]
            AF.request("https://openapi.naver.com/v1/search/shop.json?query=\(str)&start=\(start)&display=30", headers: headers).responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    print(json)
                    
                    
                    if let display = json["display"].int {
                        self.start += display
                        if display < 1 && self.start == 1 {
                            self.fetchNaverAPI(text: self.item.category2)
                        }
                    }

                    if let items = json["items"].array {
                        for item in items {
                            print(item)
                            if let link = item["link"].string,
                               let lprice = item["lprice"].string,
                               let title = item["title"].string,
                               let mallName = item["mallName"].string,
                               let image = item["image"].string,
                                let category1 = item["category1"].string,
                                let category2 = item["category2"].string,
                                let category3 = item["category3"].string {
                                let title = self.makeNakeString(string: title)
                                let result = product.init(title: title, link: link, lprice: lprice, mallName: mallName, image: image, category1: category1, category2: category2, category3: category3 )
                                
                                self.recomendItems.append(result)
                                
                                
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    break
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    break
                }
            }
            
        }
    }
}


extension ProductVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 16))
        headerView.backgroundColor = UIColor(named: "SectionSeperatorColor")
        return headerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return self.recomendItems.count
        }
        
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "productDetailCell", for: indexPath) as! ProductDetailCell

            switch indexPath.row {
            case 0:
                cell.titleLabel.text = item.title
                cell.mallNameLabel.text = item.mallName
                cell.priceLabel.text = item.lprice.wonRepresentation
                
                if let button = cell.detailButton {
                    button.addTarget(self, action: #selector(gotoDetailPage(_:)), for: .touchUpInside)
                }
                break
            default:
                break
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "recommendCell", for: indexPath) as! RecommendCell
            
            let item = recomendItems[indexPath.row]
            
            if let title = cell.recommendTitle,
               let price = cell.recommendPrice,
               let imageView = cell.recommendImage,
               let mallLabel = cell.recommendMallName {
                title.text = item.title
                price.text = item.lprice.wonRepresentation
                mallLabel.text = item.mallName
                
                let url = URL(string: item.image)
                let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                    |> ResizingImageProcessor(referenceSize: CGSize(width: 140.0, height: 140), mode: .aspectFill)
                imageView.kf.indicatorType = .activity
                imageView.kf.setImage(
                    with: url,
                    options: [
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(0.1)),
                        .cacheMemoryOnly
                    ]
                )
                
            }
            
            return cell
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select")
        if indexPath.section == 1 {
            guard let productDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "ProductDetailVC") as? ProductDetailVC else {
                return
            }
            productDetailVC.product = self.recomendItems[indexPath.row]
            present(productDetailVC, animated: true, completion: nil)
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
     let y = screenWidth - (scrollView.contentOffset.y + screenWidth)
        let height = min(max(y, 0), UIScreen.main.bounds.size.height)
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: height)
    }
    //highlight table row
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if let cell = tableView.cellForRow(at: indexPath) {
                UIView.animate(withDuration: 0.2) {
                    cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
            }
        }
        
    }
    
    //unhighlight table row
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if let cell = tableView.cellForRow(at: indexPath) {
                UIView.animate(withDuration: 0.2) {
                    cell.transform = .identity
                }
            }
        }
        
    }
}
