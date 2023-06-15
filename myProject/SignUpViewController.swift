//
//  SginUpViewController.swift
//  myProject
//
//  Created by 이서연 on 2023/06/15.
//

import UIKit
import FirebaseFirestore

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
        db.collection("userInfo").document("userInfo").setData(["id" :signupTextField.text!,"pw":PWsignupTextField.text! ])
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
