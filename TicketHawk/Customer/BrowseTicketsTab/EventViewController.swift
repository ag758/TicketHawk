//
//  EventViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 8/4/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import Firebase

class EventViewController: UIViewController {
    
    var eventID: String?
    var vendorID: String?
    
    var ref: DatabaseReference?

    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UITextView!
    @IBOutlet weak var vendorImageView: UIImageView!
    @IBOutlet weak var vendorName: UITextView!
    @IBOutlet weak var dateAndTime: UITextView!
    
    @IBOutlet weak var going: UITextView!
    @IBOutlet weak var location: UITextView!
    @IBOutlet weak var dressCode: UITextView!
    @IBOutlet weak var descriptionView: UITextView!
    
    @IBOutlet weak var purchaseTickets: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = Constants.ref
        loadEventDetails()
        
        eventImageView.layer.cornerRadius = 5
        vendorImageView.layer.cornerRadius = 20
        
        purchaseTickets.backgroundColor = .clear
        purchaseTickets.layer.cornerRadius = 25
        purchaseTickets.layer.borderWidth = 2
        purchaseTickets.layer.borderColor = UIColor.white.cgColor
        
        purchaseTickets.setTitleColor(UIColor.white, for: .normal)
        
        purchaseTickets.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        purchaseTickets.setTitle("Purchase Tickets", for: .normal)
        
        //Back bar title = ""
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
    }
    
    func loadEventDetails(){
        
            ref?.child("vendors").child(self.vendorID!).observeSingleEvent(of: .value, with: {(snapshot) in
                
                let value = snapshot.value as? NSDictionary
                
                self.vendorName.text = value?["organizationName"] as? String ?? ""
                
                self.downloadImage(from: URL(string : value?["organizationProfileImage"] as? String ?? "") ?? URL(string: "www.apple.com")!, iv: self.vendorImageView)
                
            })
        ref?.child("vendors").child(self.vendorID!).child("events").child(self.eventID!).observeSingleEvent(of: .value, with:
            {(snapshot) in
                
                let value = snapshot.value as? NSDictionary
                
                self.downloadImage(from: URL(string: value?["pictureURL"] as? String ?? "") ?? URL(string: "www.apple.com")!, iv: self.eventImageView)
                self.eventTitle.text = value?["eventTitle"] as? String ?? ""
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                let d1: Date = dateFormatter.date(from: value?["startDateAndTime"] as? String ?? "") ?? Date()
                let d2: Date = dateFormatter.date(from: value?["endDateAndTime"] as? String ?? "") ?? Date()
                
                let dateFormatter2 = DateFormatter()
                dateFormatter2.amSymbol = "AM"
                dateFormatter2.pmSymbol = "PM"
                dateFormatter2.dateFormat = "MMM d, h:mm a"
                
                self.dateAndTime.text = "🕑 " + dateFormatter2.string(from: d1) + " to " + dateFormatter2.string(from: d2)
                self.location.text = "🗺 " + (value?["location"] as? String ?? "")
                
                var dressCodeString = (value?["dressCode"] as? String ?? "No Dress Code")
                if dressCodeString == "" {
                    dressCodeString = "No Dress Code"
                }
                self.dressCode.text = "🎩 " + dressCodeString
                
                if let i = value?["going"] as? Int {
                    self.going.text = "😌 " + String(i) + " going"
                } else {
                    self.going.text = ""
                    
                    
                }
                self.descriptionView.text = value?["description"] as? String ?? "No Description"
            }
        
        )
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL, iv: UIImageView) {
        print("Download Started")
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.getData(from: url) { data, response, error in
                guard let data = data, error == nil else { return }
                print(response?.suggestedFilename ?? url.lastPathComponent)
                print("Download Finished")
                
                
                DispatchQueue.main.async() {
                    iv.image = UIImage(data: data)
                }
            }
        }
        
    }
    
    
    @IBAction func purchaseTicketsPressed(_ sender: Any) {
        
        let next = self.storyboard!.instantiateViewController(withIdentifier: "eventTicketNumberViewController") as! EventTicketNumberViewController
        
        next.eventID = self.eventID
        next.vendorID = self.vendorID
        
    self.navigationController!.pushViewController(next, animated: true)
        
    }
    
    
}
