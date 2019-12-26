//
//  CustomerTicketGenerationViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 9/2/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class CustomerTicketGenerationViewController: UIViewController {
    
    var map = [TicketType: Int]()
    
    var ref: DatabaseReference?
    
    var vendorID: String?
    var eventID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        ref = Constants.ref
        
        var addedTickets = 0
        
        ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").observeSingleEvent(of: .value, with: {(snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            let userName = value?["contactName"] ?? ""
            
            self.ref?.child("vendors").child(self.vendorID!).child("events").child(self.eventID!).observeSingleEvent(of: .value, with:
                {(snapshot) in
                    
                    let value = snapshot.value as? NSDictionary ?? [:]
                    
                    let eventTitle = value["eventTitle"] as? String ?? ""
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                    
                    let d1: Date = dateFormatter.date(from: value["startDateAndTime"] as? String ?? "") ?? Date()
                    let dateFormatter2 = DateFormatter()
                    dateFormatter2.amSymbol = "AM"
                    dateFormatter2.pmSymbol = "PM"
                    
                    dateFormatter2.dateFormat =  "MM-dd-yyyy h:mm a"
                    
                    let dateAndTime = dateFormatter2.string(from: d1)
                    let location = (value["location"] as? String ?? "")
                    let dressCodeString = (value["dressCode"] as? String ?? "")
                    
                    if value != [:]{
                        
                        //write tickets to event
                        
                        for (t,i) in self.map {
                            
                            var countdown = i
                            
                            while countdown != 0 {
                                
                                let key = self.ref?.child("vendors").child(self.vendorID ?? "").child("events").child(self.eventID ?? "").child("activeTickets").childByAutoId().key
                                
                                let post = ["userName": userName,
                                            "title": eventTitle,
                                            "dateAndTime": dateAndTime,
                                            "location": location,
                                            "ticketType": t.name,
                                            "key": key
                                    
                                    ] as [String : Any]
                                
                                let update1 = ["/vendors/\(self.vendorID ?? "")/events/\(self.eventID ?? "")/activeTickets/\(key ?? "")": post]
                                self.ref?.updateChildValues(update1, withCompletionBlock: {error, ref in
                                    addedTickets = addedTickets + 1
                                    self.determineIfFinished(quantity: addedTickets)
                                })
                                let update2 = ["/customers/\(Auth.auth().currentUser?.uid ?? "")/activeTickets/\(key ?? "")": post]
                                self.ref?.updateChildValues(update2, withCompletionBlock: {error, ref in
                                    addedTickets = addedTickets + 1
                                    self.determineIfFinished(quantity: addedTickets)
                                })
                                countdown = countdown - 1
                            }
                            
                        }
                    }
                    
                    
            })
            
            //Generate tickets with callbacks to determine finished status
            
            
            
        })
        

        // Do any additional setup after loading the view.
    }
    
    func determineIfFinished(quantity: Int){
        var totalQuantity = 0
        for (_, i) in self.map {
            totalQuantity = totalQuantity + i
        }
        
       
        
        if quantity == totalQuantity * 2 {
            
            
            
            
            let alert = UIAlertController(title: "Your Purchase was Successful!", message: "View your new tickets in the 'My Tickets' tab.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                
                //Update Ticket VC and Archive VC
                //SplitViewController.ticketsVC?.loadTickets()
                //SplitViewController.ticketsArchiveVC?.loadTickets()
                
                self.navigationController?.popToRootViewController(animated: true)
            })
            self.present(alert, animated: true, completion: nil)
            
            DispatchQueue.main.async {
                UIApplication.shared.endIgnoringInteractionEvents()
            }
        }
    }
    

    

}
