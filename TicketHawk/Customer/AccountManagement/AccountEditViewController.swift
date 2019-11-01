//
//  AccountEditViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 9/13/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class AccountEditViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    var ref: DatabaseReference?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        saveButton.backgroundColor = .clear
        saveButton.layer.cornerRadius = 25
        saveButton.layer.borderWidth = 2
        saveButton.layer.borderColor = UIColor.white.cgColor
        
        saveButton.setTitleColor(UIColor.white, for: .normal)
        
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        saveButton.setTitle("Save", for: .normal)
        
        ref = Constants.ref
        
        ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").observeSingleEvent(of: .value, with: {(snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            self.nameField.text = value?["contactName"] as? String ?? ""
            self.emailField.text = value?["contactEmail"] as? String ?? ""
            
        })
    }
    
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if (self.nameField.text != "" && self.emailField.text != ""){
            let uid = Auth.auth().currentUser?.uid
            
            
            ref?.child("customers/\(uid ?? "")").observeSingleEvent(of: .value, with: {(dataSnapshot) in
                
                let value = dataSnapshot.value as? NSDictionary ?? [:]
                
                if value != [:] {
                    self.ref?.child("customers/\(uid ?? "")/contactEmail").setValue(self.emailField.text)
                    self.ref?.child("customers/\(uid ?? "")/contactName").setValue(self.nameField.text)
                }
            })
           
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}
