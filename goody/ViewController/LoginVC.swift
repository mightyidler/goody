//
//  LoginVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit
import CoreData
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class LoginVC: UIViewController {

    @IBOutlet weak var loginActivityView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailWarningLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordWarningLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginIndicator: UIActivityIndicatorView!
    @IBOutlet var mainView: UIView!
    
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    var db: Firestore!
    var uid: NSString!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        loginButton.layer.cornerRadius = 19
        self.loginIndicator.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
    }
    
    @IBAction func loginButtonAction(_ sender: UIButton) {
        checkTextFieldProcess()
    }
    
    @IBAction func policyButtonAction(_ sender: UIButton) {
    }
    

    @IBAction func signinButtonAction(_ sender: UIButton) {
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func checkTextFieldProcess() {
        if let text = self.emailTextField.text {
            if isValidEmail(text) {
                self.emailWarningLabel.text = ""
                if self.passwordTextField.text == "" {
                    self.passwordWarningLabel.text  = "비밀번호를 입력해주세요."
                } else {
                    // login
                    DispatchQueue.main.async {
                        self.loginIndicator.isHidden = false
                        self.emailWarningLabel.text = ""
                        self.passwordWarningLabel.text = ""
                        self.view.endEditing(true)
                        self.view.isUserInteractionEnabled = false
                        self.loginButton.isEnabled = false
                        
                    }
                    self.loginProcess()
                }
            } else {
                self.emailWarningLabel.text = "올바른 이메일 주소가 아닙니다."
                if self.passwordTextField.text == "" {
                    self.passwordWarningLabel.text  = "비밀번호를 입력해주세요."
                }
            }
        }
    }
    
    func loginProcess() {
        guard let email = self.emailTextField.text, let password = self.passwordTextField.text else {
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard self != nil else { return }
            if authResult != nil{
                print("login success")
                
                //load date from firebase and append core data...
                
                self?.checkUser()
                
                
                
            }
            else{
                print("login fail")
                var errorMsg: String!
                if error != nil {
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .networkError:
                            errorMsg = "네트워크 에러가 발생했습니다."
                            break
                        case .userNotFound:
                            errorMsg = "존재하지 않은 계정입니다."
                            break
                        case .tooManyRequests:
                            errorMsg = "비정상적인 횟수의 요청으로 차단되었습니다. 잠시 후에 다시 시도하세요"
                            break
                        case .appNotAuthorized:
                            errorMsg = "인증되지 않은 애플리케이션입니다."
                            break
                        case .keychainError:
                            errorMsg = "키체인 접근 중 오류가 발생했습니다."
                            break
                        case .invalidEmail:
                            errorMsg = "유효하지 않은 이메일 주소입니다."
                            break
                        case .operationNotAllowed:
                            errorMsg = "게정의 사용설정이 되어있지 않습니다."
                            break
                        case .userDisabled:
                            errorMsg = "게정의 사용 중지 상태입니다."
                            break
                        case .wrongPassword:
                            errorMsg = "유효하지 않은 비밀번호 입니다."
                            break
                        default:
                            errorMsg = "알수없는 에러 \(error)"
                            break
                        }
                    }
                }
                
                
                let alert = UIAlertController(title: "로그인 실패", message: errorMsg, preferredStyle: UIAlertController.Style.alert)
                self?.present(alert, animated: true, completion: nil)
                let when = DispatchTime.now() + 1
                DispatchQueue.main.asyncAfter(deadline: when){
                  // your code with delay
                  alert.dismiss(animated: true, completion: nil)
                }
                
                DispatchQueue.main.async {
                    self?.loginIndicator.isHidden = true
                    self?.view.isUserInteractionEnabled = true
                    self?.loginButton.isEnabled = true
                    self?.loginButton.shake()
                }
            }
        }
        
    }
    
    private func checkUser() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                // user is signed in
                if let id = user?.uid {
                    self.uid = id as NSString
                    self.loadUsersData()
                }
                // go to feature controller
            } else {
                 // user is not signed in
                 // go to login controller
            }
        }
    }
    
    func loadUsersData() {
        if let id = uid {
            self.removeAll()
            
            db.collection("users").document("\(id)").collection("wishList").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let dict = document.data()
                        if let link = dict["link"] as? String,
                           let image = dict["image"] as? String,
                           let mallName = dict["mallName"] as? String,
                           let price = dict["price"] as? String,
                           let title = dict["title"] as? String,
                           let category1 = (dict["category1"] ?? "") as? String,
                           let category2 = (dict["category2"] ?? "") as? String,
                           let category3 = (dict["category2"] ?? "") as? String {
                            let item = product.init(title: title, link: link, lprice: price, mallName: mallName, image: image, category1: category1, category2: category2, category3: category3)
                            print("product item: \(item)")
                            self.appendProduct(product: item)
                        }
                    }
                    DispatchQueue.main.async {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let tabBarVC = storyboard.instantiateViewController(withIdentifier: "TabBarVC") as? TabBarVC {
                            let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
                            tabBarVC.view.addSubview(overlayView)
                            if let window = self.view.window {
                                window.rootViewController = tabBarVC
                                UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                                    overlayView.alpha = 0
                                }, completion: { finished in
                                    overlayView.removeFromSuperview()
                                })
                            }
                            
                        }
                       
                        
                        
                        
                        
                        
                    }
                }
                
            }
        }
    }
    
    
}


extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //return when text field on email field
        if (textField.isEqual(self.emailTextField)) {
            if textField.text != "" {
                if let text = textField.text {
                    if isValidEmail(text) {
                        self.passwordTextField.becomeFirstResponder()
                        self.emailWarningLabel.text = ""
                    } else {
                        self.emailWarningLabel.text = "올바른 이메일 주소가 아닙니다."
                    }
                }
            } else {
                self.emailWarningLabel.text = "이메일 주소를 입력해주세요."
            }
        }
        else if (textField.isEqual(self.passwordTextField)) {
            if self.emailTextField.text == "" {
                self.emailWarningLabel.text = "이메일 주소를 입력해주세요."
                if self.passwordTextField.text == "" {
                    self.passwordWarningLabel.text  = "비밀번호를 입력해주세요."
                }
            } else {
                checkTextFieldProcess()
            }
        }
        
        
        return true
    }
}

extension LoginVC {
    //fetch list from core data
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SavedItem")
        let result = try! context.fetch(fetchRequest)
        return result
    }
    
    func removeAll() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
            list = { return self.fetch() }()
        } catch {
            context.rollback()
        }
    }
    
    func appendAllProduct() -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            do {
                for index in 0...list.count - 1 {
                    let object = NSEntityDescription.insertNewObject(forEntityName: "SavedItem", into: context)
                    object.setValue(list[index].value(forKey: "title"), forKey: "title")
                    object.setValue(list[index].value(forKey: "image"), forKey: "image")
                    object.setValue(list[index].value(forKey: "url"), forKey: "url")
                    object.setValue(list[index].value(forKey: "price"), forKey: "price")
                    object.setValue(list[index].value(forKey: "mallName"), forKey: "mallName")
                    object.setValue(list[index].value(forKey: "category1"), forKey: "category1")
                    object.setValue(list[index].value(forKey: "category2"), forKey: "category2")
                    object.setValue(list[index].value(forKey: "category3"), forKey: "category3")
                    try context.save()
                }
                try context.save()
                return true
            } catch {
                return false
            }
        } catch {
            context.rollback()
            return false
        }
        
    }
    
    //append searched item to core data
    func appendProduct(product: product) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: "SavedItem", into: context)
        
        // url price title image
        object.setValue(product.title, forKey: "title")
        object.setValue(product.link, forKey: "url")
        object.setValue(product.image, forKey: "image")
        object.setValue(product.lprice, forKey: "price")
        object.setValue(product.mallName, forKey: "mallName")
        object.setValue(product.category1, forKey: "category1")
        object.setValue(product.category2, forKey: "category2")
        object.setValue(product.category3, forKey: "category3")

        //append object core base
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
}
