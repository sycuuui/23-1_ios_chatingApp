//
//  SginUpViewController.swift
//  myProject
//
//  Created by 이서연 on 2023/06/15.
//

import UIKit
import FirebaseFirestore
import Toast_Swift

class SginUpViewController: UIViewController {
    let db = Firestore.firestore()
    override func viewDidLoad() {
        super.viewDidLoad()
        //텍스트 필드 데베에 저장
        //버튼 누르면 Main으로 이동
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var signupTextField: UITextField!
    @IBOutlet weak var PWsignupTextField: UITextField!
    
    @IBAction func signupBtnToBack(_ sender: UIButton) {
        guard let id = signupTextField.text, let pw = PWsignupTextField.text else {
            // ID 또는 PW 필드가 비어있는 경우
            return
        }
        
        let docRef = db.collection("userInfo").document(id)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.view.makeToast("id 중복, 회원가입 실패",duration: 1.0, position: .bottom, title: "sign up message")
            } else {
                docRef.setData([
                    "id": id,
                    "pw": pw
                ]) { error in
                    if let error = error {
                        print("Error creating user: \(error)")
                        self.view.makeToast("회원가입 실패",duration: 1.0, position: .bottom, title: "sign up message")
                    } else {
                        self.view.makeToast("회원가입 성공",duration: 1.0, position: .bottom, title: "sign up message")
                    }
                }
            }
        }
    }
}
