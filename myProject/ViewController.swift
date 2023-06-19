//
//  ViewController.swift
//  myProject
//
//  Created by 이서연 on 2023/06/15.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


class ViewController: UIViewController {
    
    @IBOutlet weak var IDTextField: UITextField!
    @IBOutlet weak var PWTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginBtn(_ sender: UIButton) {
        guard let id = IDTextField.text, let pw = PWTextField.text else {
            // 이메일과 패스워드 필드가 비어있는 경우
            return
        }
        
        let db = Firestore.firestore()
        let userData = db.collection("userInfo").document(id)
        
        userData.getDocument { (document, error) in
            if let document = document, document.exists {
                // 데이터베이스에서 조회한 이메일과 비밀번호
                let dbId = document.get("id") as? String ?? ""
                let dbPw = document.get("pw") as? String ?? ""
                
                if id == dbId && pw == dbPw {
                    // 로그인 성공
                    print("로그인 성공")
                    self.view.makeToast("로그인 성공", duration: 1.0, position: .bottom, title: "sign in message")
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    
                    
                    // Tab Bar Controller의 인스턴스 생성
                    let navigationController = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
                    if let chatViewController = navigationController.viewControllers.first as? ChatViewController {
                            chatViewController.setID(id) // id 값을 전달
                        }
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let sceneDelegate = windowScene.delegate as? SceneDelegate {
                        // Navigation Controller를 rootViewController로 설정하여 전체 화면을 변경
                        sceneDelegate.window?.rootViewController = navigationController
                        sceneDelegate.window?.makeKeyAndVisible()
                    }
                    
                } else {
                    // 이메일 또는 비밀번호가 일치하지 않음
                    print("이메일 또는 비밀번호가 일치하지 않습니다.")
                    self.view.makeToast("id 또는 pw가 일치하지 않습니다.", duration: 1.0, position: .bottom, title: "sign in message")
                }
            } else {
                print("문서를 찾을 수 없습니다.")
            }
        }
    }
    
    @IBAction func signup(_ sender: UIButton) {
        self.performSegue(withIdentifier: "signup", sender: self)
    }
    
    @IBAction func unwind(_segue:UIStoryboardSegue){
        // 화면 전환 후 돌아왔을 때 필요한 작업 수행
    }
}

