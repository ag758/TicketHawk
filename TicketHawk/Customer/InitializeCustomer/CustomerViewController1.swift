//
//  CustomerViewController1.swift
//  TicketHawk
//
//  Created by Austin Gao on 7/4/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import Firebase
import FirebaseUI

class CustomerViewController1: UIViewController {

    var ref: DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        ref = Constants.ref
        view.backgroundColor = UIColor.black
        setCosmetics()
        
        //logOut()
        checkLoggedIn()
    }
    
    func setCosmetics(){
    }
    
    @IBAction func backPressed(_ sender: Any) {
         dismiss(animated: true, completion: nil)
    }
    
    func logOut(){
        do {
            try Auth.auth().signOut()
        } catch {
            
        }
    }
    
    func checkLoggedIn(){
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                self.customerLogin()
            } else {
                self.attemptLogin()
            }
        }
    }
    
    func attemptLogin(){
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self as? FUIAuthDelegate
        
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(),
            FUIFacebookAuth(),
        ]
        authUI?.providers = providers
        let authViewController = authUI?.authViewController()
        
        authViewController?.navigationBar.topItem!.title = "TicketHawk"
        
        self.present(authViewController!, animated: true, completion: nil)
    }
    
    func customerLogin(){
        ref = Database.database().reference()
        let user = Auth.auth().currentUser
        
        let userID: String = (user?.uid)!
        let userName: String = (user?.displayName)!
        
        //Values that will not change
        
        
        
        let customerRef : DatabaseReference? = ref?.child("customers").child(userID)
        
        // Attach a listener to read the data at our posts reference
        customerRef?.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            
            ///If no value exists -- means false
            let didFinishProfile = value?["didFinishSigningUp"] as? Bool ?? false
            
            if (!didFinishProfile){
                //Either they did not finish making their profile or this is their first time creating their profile
                self.ref?.child("customers/\(userID)/didFinishSigningUp").setValue(false)
                
                self.ref?.child("customers/\(userID)/contactName").setValue(userName)
                self.ref?.child("customers/\(userID)/contactEmail").setValue(user?.email)
                
                
                //Continue editing their profile...
                
                let next = self.storyboard!.instantiateViewController(withIdentifier: "customerViewController2") as! CustomerViewController2
                self.present(next, animated: true, completion: nil)
                
                
            } else {
                
                //If they did finish making their profile
                //Check if banned
                let isBanned = value?["banned"] as? Bool ?? false
                if (isBanned){
                    //don't allow
                    
                    let alert = UIAlertController(title: "Your account is under review.", message: "If you believe this is a mistake, please contact TicketHawk support.", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    self.present(alert, animated: true)
                    
                } else {
                    //allow, transition to main vendor activity
                    
                    let next = self.storyboard!.instantiateViewController(withIdentifier: "customerTabController") as! UITabBarController
                    self.present(next, animated: true, completion: nil)
                }
                
            }
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
        
        
        
    }
    
}

