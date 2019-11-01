//
//  CustomerViewController2.swift
//  TicketHawk
//
//  Created by Austin Gao on 7/6/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import Firebase
import FirebaseUI

class CustomerViewController2: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    var ref:DatabaseReference?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var communitiesTableView: UITableView!
    
    var intendedCommunity:String = ""
    
    var communities:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Constants.ref
        

        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.black
        
        communitiesTableView.delegate = self
        communitiesTableView.dataSource = self
        communitiesTableView.reloadData()
        
        fetchCommunities()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.communities.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //variable type is inferred
        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL")
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "CELL")
        }
        
        cell!.textLabel?.text = communities[indexPath.row]
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        intendedCommunity = communities[indexPath.row]
    }
    
    
    
    func fetchCommunities(){
        let query = ref?.child("communities")
        query?.observe(.childAdded, with: { (snapshot) in
            let community = snapshot.value as? NSDictionary
            let name = community!["name"] as! String
            self.communities.append(name)
            self.communities = self.communities.sorted()
            
            self.communitiesTableView.reloadData()
            
        })
        query?.observe(.childRemoved, with: { (snapshot) in
            let community = snapshot.value as? NSDictionary
            let name = community!["name"] as! String
            for c in self.communities{
                if c == name{
                    self.communities.remove(at: self.communities.lastIndex(of: c)!)
                }
            }
            
            self.communitiesTableView.reloadData()
            
            
        })
    }
    

    @IBAction func nextPressed(_ sender: Any) {
        
        let user = Auth.auth().currentUser
        
        let userID: String = (user?.uid)!
        
        //Check valid inputs
        if (nameTextField.text?.isEmpty == false && emailTextField.text?.isEmpty == false
            && intendedCommunity != ""){
            
            ref?.child("customers/\(userID)/contactName").setValue(nameTextField.text)
            ref?.child("customers/\(userID)/contactEmail").setValue(emailTextField.text)
            
            //set flag did finish setting up
            ref?.child("customers/\(userID)/didFinishSigningUp").setValue(true)
            
            //set banned to false
            ref?.child("customers/\(userID)/banned").setValue(false)
            
            
            ref?.child("customers/\(userID)/primaryCommunity").setValue(intendedCommunity)
            
            //allow, transition to main vendor activity
            
            let next = self.storyboard!.instantiateViewController(withIdentifier: "customerTabController") as! UITabBarController
            self.present(next, animated: true, completion: nil)
            
            
            
        } else {
            
        }
        
    }
}
