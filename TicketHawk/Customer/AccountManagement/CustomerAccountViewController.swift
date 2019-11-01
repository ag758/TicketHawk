//
//  CustomerAccountViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 8/3/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FirebaseAuth

class CustomerAccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    

    
    @IBOutlet weak var settingsTableView: UITableView!
    
    let settingsArray = ["Community", "Account Info", "Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Do any additional setup after loading the view.
        
        self.navigationController!.navigationBar.barTintColor = UIColor.black
        
        let logo = UIImage(named: "thawk_transparent.png")
        let imageView = UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.reloadData()
        settingsTableView.layer.cornerRadius = 20
        settingsTableView.backgroundColor = Constants.almostBlack
        settingsTableView.separatorColor = UIColor.black
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = settingsArray[indexPath.row]
        cell.textLabel?.textColor = UIColor.white
        cell.backgroundColor = Constants.almostBlack
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            let next = self.storyboard!.instantiateViewController(withIdentifier: "communityEditViewController") as! CommunityEditViewController
            self.navigationController!.pushViewController(next, animated: true)
            break
        case 1:
            let next = self.storyboard!.instantiateViewController(withIdentifier: "accountEditViewController") as! AccountEditViewController
            self.navigationController!.pushViewController(next, animated: true)
            break
        case 2:
            //
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                
                if let storyboard = self.storyboard {
                    let vc = storyboard.instantiateViewController(withIdentifier: "splitViewController") as! SplitViewController
                    self.present(vc, animated: true, completion: nil)
                }
                
                
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            //
            break
        default:
            break
        }
        
        
    }

}
