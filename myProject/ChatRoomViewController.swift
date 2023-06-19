//
//  ChatRoomViewController.swift
//  myProject
//
//  Created by 이서연 on 2023/06/19.
//

import UIKit

class ChatRoomViewController: UIViewController {
    var friendID: String?
    var id: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        print("friendID: "+friendID!)
        print("id: "+id!)
        
        // Do any additional setup after loading the view.
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
