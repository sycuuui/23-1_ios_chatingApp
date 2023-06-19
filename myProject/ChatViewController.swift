//
//  ChatViewController.swift
//  myProject
//
//  Created by 이서연 on 2023/06/15.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore

class ChatViewController: UIViewController, UISearchBarDelegate {
    var searchBar: UISearchBar?
    var searchResults: [String] = []
    var modalViewController: UIViewController?
    var modalTableView: UITableView?
    var id: String?
    var friendID: String?
    

    @IBAction func searchBtn(_ sender: UIButton) {
        print("click")
        showSearchModal()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad(): "+self.id!)
    }
    
    func setID(_ id:String){
        self.id=id;
    }

    func showSearchModal() {
        print("make modal start")
        let modalViewController = UIViewController()
        modalViewController.modalPresentationStyle = .overCurrentContext
        modalViewController.view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        modalViewController.view.frame = view.bounds

        let searchView = UIView(frame: CGRect(x: 50, y: 100, width: view.bounds.width - 100, height: view.bounds.height - 200))
        searchView.backgroundColor = .white
        searchView.layer.cornerRadius = 10
        modalViewController.view.addSubview(searchView)

        searchBar = UISearchBar(frame: CGRect(x: 10, y: 10, width: searchView.bounds.width - 20, height: 44))
        searchBar?.autocapitalizationType = .none
        searchBar?.delegate = self
        searchView.addSubview(searchBar!)

        let tableView = UITableView(frame: CGRect(x: 10, y: 118, width: searchView.bounds.width - 20, height: searchView.bounds.height - 128))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchResultCell") // 셀 등록
        searchView.addSubview(tableView)

        self.modalViewController = modalViewController
        self.modalTableView = tableView

        present(modalViewController, animated: true, completion: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSearchModal))
                tapGesture.cancelsTouchesInView = false
                modalViewController.view.addGestureRecognizer(tapGesture)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchBar.text else {
            return
        }
        searchUsers(with: searchTerm)
        print(searchTerm)
        searchBar.resignFirstResponder() // 검색 후 키보드 닫기
    }

    func searchUsers(with searchTerm: String) {
        print("start search")
        let db = Firestore.firestore()
        let usersCollection = db.collection("userInfo")

        usersCollection.whereField("id", isEqualTo: searchTerm)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    print("검색 결과 가져오기 오류: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("검색 결과 없음")
                    return
                }

                self.searchResults = []

                let lowercasedSearchTerm = searchTerm.lowercased()

                for document in documents {
                    if let id = document.data()["id"] as? String {
                        let lowercasedID = id.lowercased()
                        if lowercasedID.contains(lowercasedSearchTerm) {
                            print("id: " + id)
                            self.searchResults.append(id)
                        }
                    }
                }


                // 검색 결과 사용
                print(self.searchResults)

                // 검색 결과를 tableView에 업데이트
                DispatchQueue.main.async {
                    self.modalTableView?.reloadData()
                }
            }
    }

    @objc func dismissSearchModal() {
        self.modalViewController?.dismiss(animated: true, completion: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismissSearchModal()
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // searchResults 배열의 아이템 수를 반환합니다.
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)
        let searchResult = searchResults[indexPath.row]
        cell.textLabel?.text = searchResult
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedResult = searchResults[indexPath.row]
        showChatViewController(with: selectedResult)
        
//        let chatData: [String: Any] = [
//            "message": "Hello", "sender": id!, "timestamp": Date()
//        ]
//
//        let db = Firestore.firestore()
//        let chatCollection = db.collection("chat")
//        let documentRef = chatCollection.document(id).collection(friendID).document()
//        documentRef.setData(chatData) { error in
//            if let error = error {
//                print("채팅 데이터 저장 실패: \(error.localizedDescription)")
//            } else {
//                print("채팅 데이터 저장 성공")
//            }
//        }
    }

    func showChatViewController(with friendID: String) {
        // 채팅할 수 있는 뷰 컨트롤러를 초기화하고, friendID를 전달합니다.
        let chatVC = ChatRoomViewController()
        chatVC.friendID = friendID
        chatVC.id = self.id

        navigationController?.pushViewController(chatVC, animated: true)
    }

}




