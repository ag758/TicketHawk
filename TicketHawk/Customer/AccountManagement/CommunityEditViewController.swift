//
//  CommunityEditViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 9/13/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class CommunityEditViewController: UIViewController ,UITableViewDelegate, UITableViewDataSource {
    
    var ref: DatabaseReference?
    
    @IBOutlet weak var communitiesTableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
    var communities:[String] = []
    
    var intendedCommunity:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Constants.ref

        saveButton.backgroundColor = .clear
        saveButton.layer.cornerRadius = 25
        saveButton.layer.borderWidth = 2
        saveButton.layer.borderColor = UIColor.white.cgColor
        
        saveButton.setTitleColor(UIColor.white, for: .normal)
        
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        saveButton.setTitle("Save", for: .normal)
        
        communitiesTableView.delegate = self
        communitiesTableView.dataSource = self
        
        communitiesTableView.layer.cornerRadius = 25
        
        fetchCommunities()
    }
    
    func fetchCommunities(){
        let query = ref?.child("communities")
        query?.observe(.childAdded, with: { (snapshot) in
            let community = snapshot.value as? NSDictionary ?? [:]
            let name = community["name"] as? String ?? ""
            self.communities.append(name)
            self.communities = self.communities.sorted()
            
            self.communitiesTableView.reloadData()
            
        })
        query?.observe(.childRemoved, with: { (snapshot) in
            let community = snapshot.value as? NSDictionary ?? [:]
            let name = community["name"] as? String ?? ""
            for c in self.communities{
                if c == name{
                    self.communities.remove(at: self.communities.lastIndex(of: c) ?? 0)
                }
            }
            
            self.communitiesTableView.reloadData()
            
            
        })
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

    @IBAction func saveButtonPressed(_ sender: Any) {
        
        if (intendedCommunity != ""){
            let uid = Auth.auth().currentUser?.uid
            
            ref?.child("customers/\(uid ?? "")").observeSingleEvent(of: .value, with: {(dataSnapshot) in
                
                let value = dataSnapshot.value as? NSDictionary ?? [:]
                
                if value != [:] {
                    self.ref?.child("customers/\(uid ?? "")/primaryCommunity").setValue(self.intendedCommunity)
                    
                    SplitViewController.customerMainVC?.loadCommunity()
                }
            })
            
            
            
            self.navigationController?.popViewController(animated: true)
        }
        
    }
}
