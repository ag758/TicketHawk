//
//  ViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 6/23/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import Firebase

class SplitViewController: UIViewController {
    
    static var ref: DatabaseReference?
    
    static var customerMainVC: CustomerMainViewController?
    static var ticketsVC: CustomerTicketViewController?
    static var ticketsArchiveVC: CustomerArchiveTicketViewController?

    @IBOutlet weak var customerButton: UIButton!
    
    static var greenColor: UIColor = UIColor.black
    static var almostBlack: UIColor = UIColor(red:0.13, green:0.13, blue:0.13, alpha:1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        SplitViewController.ref = Database.database().reference()
        
        setCosmetics()
        
        SplitViewController.greenColor = hexStringToUIColor(hex: "#77FF73")
    }
    
    func setCosmetics(){
        view.backgroundColor = UIColor.black
        
        customerButton.backgroundColor = .clear
        customerButton.layer.cornerRadius = 30
        customerButton.layer.borderWidth = 3
        customerButton.layer.borderColor = UIColor.white.cgColor
        
        customerButton.setTitleColor(UIColor.white, for: .normal)
        
        customerButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        customerButton.setTitle("I'm Buying Tickets", for: .normal)
        
    }
    
    @IBAction func customerPressed(_ sender: Any) {
        let next = self.storyboard!.instantiateViewController(withIdentifier: "customerViewController1") as! CustomerViewController1
        self.present(next, animated: true, completion: nil)
    }
    
    @IBAction func tosPressed(_ sender: Any) {
        guard let url = URL(string: Constants.termsOfServiceURL) else {
            return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func privacyPressed(_ sender: Any) {
        guard let url = URL(string: Constants.privacyPolicyURL) else {
            return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

