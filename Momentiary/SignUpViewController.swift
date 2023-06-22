//
//  SignUpViewController.swift
//  Momentiary
//
//  Created by 0000 on 2023/06/19.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailWarningLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordCheckTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var okButton: UIButton!
    
    var reference: CollectionReference = Firestore.firestore().collection("users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        okButton.isEnabled = false // Disable sign up button by default

    }
    @objc private func goToLogin() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.leftBarButtonItem = nil
    }
    
    
    @IBAction func emailTextFieldChange(_ sender: UITextField) {
        // Enable or disable sign up button based on email format validity
        if let email = sender.text {
            let isValidateEmail = validateEmail(email: email)
            okButton.isEnabled = isValidateEmail
            emailWarningLabel.isHidden = isValidateEmail
        } else {
            okButton.isEnabled = false
            emailWarningLabel.isHidden = true
        }
    }
    
    private func validateEmail(email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    @IBAction func signUpComplete(_ sender: Any) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              let confirmPassword = passwordCheckTextField.text,
              let nickname = nicknameTextField.text else {
            return
        }
        
        if password != confirmPassword {
            // 비밀번호가 일치하지 않는 경우 알림을 표시합니다.
            showAlert(message: "비밀번호가 일치하지 않습니다.")
            return
        }
        
        // Firebase Auth를 사용하여 사용자를 생성합니다.
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                // 회원가입 실패
                print("회원가입 실패")
                
                // 중복된 회원이 있는 경우
                if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                                  // 중복된 회원이 있는 경우
                    self.showAlert(message: "중복된 이메일이 있습니다.")
                } else {
                    self.showAlert(message: "회원가입 실패!")
                }
            } else {
                // 회원가입 성공
                print("회원가입 성공")
                
                // 회원가입에 성공했음을 알림으로 표시합니다.
                self.showAlert(message: "회원가입 성공!")
                
                // users Collection에 회원 정보(json) 저장
                let uid = authResult?.user.uid
                var dict : [String: Any?] = [:]
                dict["nickname"] = nickname
                dict["email"] = email
                
                self.reference.document(uid!).setData(dict as [String : Any])
                
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

}
