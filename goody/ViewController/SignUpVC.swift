//
//  SignUpVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/12.
//

import UIKit
import Firebase
import FirebaseAuth

class SignUpVC: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var profileImage: UIImageView!
    
    var state: Int = 0
    var email: String!
    var password: String!
    var db: Firestore!
    var uid: NSString!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        textField.delegate = self
        nextButton.layer.cornerRadius = 19
        self.profileImage.layer.cornerRadius = 19
    }
    override func viewDidAppear(_ animated: Bool) {
        textField.becomeFirstResponder()
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    @IBAction func tabProfileImage(_ sender: UITapGestureRecognizer) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        self.present(picker, animated: true)
        self.indicator.stopAnimating()
        self.nextButton.isEnabled = true
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        messageLabel.text = ""
        switch state {
        case 0:
            dismiss(animated: true, completion: nil)
            break
        case 1:
            titleLabel.text = "가입하실 이메일주소를 입력하세요"
            textField.placeholder = "이메일주소"
            textField.text = email
            textField.isSecureTextEntry = false
            state = 0
            break
        default:
            break
        }
        
    }
    
    private func checkIfUserIsSignedIn() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                // user is signed in
                if let id = user?.uid {
                    self.uid = id as NSString
                }
                // go to feature controller
            } else {
                 // user is not signed in
                 // go to login controller
            }
        }
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        nextAction()
    }
    
    func nextAction() {
        messageLabel.text = ""
        switch state {
        case 0:
            //check email and ...
            if let text = textField.text, isValidEmail(text) {
                email = text
                titleLabel.text = "가입하실 계정의 비밀번호를 입력하세요"
                textField.placeholder = "비밀번호"
                textField.text = ""
                textField.isSecureTextEntry = true
                state = 1
            } else {
                // email form is wrong
                messageLabel.text = "올바른 이메일 주소가 아닙니다."
                nextButton.shake()
            }

            break
        case 1:
            //sign up process...
            if let text = textField.text, text.count >= 8 {
                password = text
                DispatchQueue.main.async {
                    self.nextButton.isEnabled = false
                    self.indicator.startAnimating()
                    self.view.isUserInteractionEnabled = false
                }
                signUp()
            } else {
                //password shorter than 8
                messageLabel.text = "비밀번호는 8자 이상으로 정해주세요."
                nextButton.shake()
            }
            break
        case 2:
            if let text = textField.text, text.count >= 2 {
                if let id = self.uid {
                    DispatchQueue.main.async {
                        self.indicator.startAnimating()
                        self.nextButton.isEnabled = false
                    }
                    db.collection("users").document("\(id)").setData(["nickname":text]) { err in
                        if let err = err {
                            DispatchQueue.main.async {
                                self.indicator.stopAnimating()
                                self.nextButton.isEnabled = true
                                self.messageLabel.text = err.localizedDescription
                            }
                        } else {
                            print("set nickname")
                            self.state = 3
                            self.titleLabel.text = "프로필 이미지를 선택해주세요."
                            self.textField.resignFirstResponder()
                            self.textField.isHidden = true
                            let picker = UIImagePickerController()
                            picker.allowsEditing = true
                            picker.delegate = self
                            self.present(picker, animated: true)
                            self.indicator.stopAnimating()
                            self.nextButton.isEnabled = true
                            
                        }
                    }
                }
            } else {
                messageLabel.text = "닉네임은 2글자 이상으로 정해주세요."
                nextButton.shake()
            }
            break
            
        case 3:
            //profile iamge uploaded
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let SelectCategoriesVC = storyboard.instantiateViewController(withIdentifier: "SelectCategoriesVC")
                let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
                SelectCategoriesVC.view.addSubview(overlayView)
                self.view.window!.rootViewController = SelectCategoriesVC
                UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                    overlayView.alpha = 0
                }, completion: { finished in
                    overlayView.removeFromSuperview()
                })
            }
            break
        default:
            break
        }
    }
    
    func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if authResult != nil{
                print("success sign up")
                DispatchQueue.main.async {
                    self.nextButton.isEnabled = true
                    self.textField.isSecureTextEntry = false
                    self.backButton.isHidden = true
                    self.indicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    //self.dismiss(animated: true, completion: nil)
                    self.titleLabel.text = "계정의 원하시는 닉네임을 정해주세요."
                    self.textField.placeholder = "닉네임"
                    let idx: String.Index = self.email.firstIndex(of: "@")!
                    self.textField.text = String(String(self.email[...idx]).dropLast())
                    self.state = 2
                    self.checkIfUserIsSignedIn()
                }
            } else {
                print("login fail")
                var errorMsg: String!
                if error != nil {
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .networkError:
                            errorMsg = "네트워크 에러가 발생했습니다."
                            break
                        case .emailAlreadyInUse:
                            errorMsg = "이미 존재하는 계정 정보입니다.."
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
                        case .weakPassword:
                            errorMsg = "안전하지 않은 비밀번호 입니다."
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
                self.present(alert, animated: true, completion: nil)
                let when = DispatchTime.now() + 1
                DispatchQueue.main.asyncAfter(deadline: when){
                  // your code with delay
                  alert.dismiss(animated: true, completion: nil)
                }
                
                DispatchQueue.main.async {
                    self.nextButton.isEnabled = true
                    self.indicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    self.nextButton.shake()
                }
            }
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let id = self.uid {
            guard let im: UIImage = info[.editedImage] as? UIImage else { return }
            guard let d: Data = im.jpegData(compressionQuality: 0.5) else { return }
            self.profileImage.isHidden = false
            self.profileImage.image = im
            let md = StorageMetadata()
            md.contentType = "image/png"
            
            let ref = Storage.storage().reference().child("profileImage/\(id).jpg")
            
            ref.putData(d, metadata: md) { (metadata, error) in
                if error == nil {
                    ref.downloadURL(completion: { (url, error) in
                        print("Done, url is \(String(describing: url))")
                    })
                }else{
                    print("error \(String(describing: error))")
                }
            }
            dismiss(animated: true)
        }
    }
}

extension SignUpVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nextAction()
        return true
    }
}
