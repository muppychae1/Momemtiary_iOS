//
//  SignInViewController.swift
//  Momentiary
//
//  Created by 0000 on 2023/06/19.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class SignInViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    var nickname = "test"
    var reference: CollectionReference? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backBarButtonItem = UIBarButtonItem(title: "Login", style: .plain, target: self, action: nil)

        self.navigationItem.backBarButtonItem = backBarButtonItem
        
        // 'users' Collection
        reference = Firestore.firestore().collection("users")
    }
    
    // 로그인 버튼 눌렀을 때
    @IBAction func login(_ sender: UIButton) {
        let email: String = emailTextField.text?.description ?? ""
        let password: String = passwordTextField.text?.description ?? ""
        
        // 회원 인증
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            
            guard let self = self else {return}
            
            if let error = error {
                print("로그인 실패")
            } else {
                print("로그인 성공")
                
                // users Collection에서 로그인한 회원 email 찾기
                let query = reference!.whereField("email", isEqualTo: email)

                query.getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error getting documents: \(error)")
                        return
                    }
                    
                    guard let document = querySnapshot?.documents.first else {
                        print("No matching document found")
                        return
                    }

                    // 로그인한 회원의 nickname
                    let nickname = document.data()["nickname"] as? String

                    if let nickname = nickname {
                        print("Found nickname: \(nickname)")
                        self.nickname = nickname
                        self.performSegue(withIdentifier: "showHome", sender: self)
                    } else {
                        print("Nickname not found")
                    }
                }
                
                
            }
            
        }
    }
    
    // 회원가입 버튼 눌렀을 때
    @IBAction func signUp(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showSignUp", sender: self)
    }
    
    // Plan Group View Controller에 로그인한 회원 정보 (nickname) 전달
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHome" {
            let vc = segue.destination as! PlanGroupViewController
            vc.nickname = nickname
        }
    }
    
}
