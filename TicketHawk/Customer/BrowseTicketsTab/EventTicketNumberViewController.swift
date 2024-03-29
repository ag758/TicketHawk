//
//  EventTicketNumberViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 8/21/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import Firebase
import FirebaseUI
import Stripe

internal class TicketTypeTableViewCell: UITableViewCell{
    
    var ticketType: TicketType! = TicketType(name : "", price: 0)
    
    @IBOutlet weak var ticketTitle: UITextView!
    @IBOutlet weak var ticketPrice: UITextView!
    @IBOutlet weak var quantity: CustomUITextField!
}

class EventTicketNumberViewController: UIViewController
, UITableViewDelegate, UITableViewDataSource{
    
   
    
    
    var eventID: String?
    var vendorID: String?
    
    var ref: DatabaseReference?
    
    var ticketTypes: [TicketType] = []
    
    var fees: Int?
    var paymentTotalInt: Int?
    var paymentTotalWithoutTaxInt: Int?
    
    var purchaseQuantity: Int = 0
    
    //TicketMap to be Added
    var map = [TicketType: Int]()

    @IBOutlet weak var quantityTableView: UITableView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var feeTextView: UITextView!
    @IBOutlet weak var subtotalTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Constants.ref
        
        self.quantityTableView.delegate = self
        self.quantityTableView.dataSource = self
        
        self.quantityTableView.rowHeight = 100
        
        self.quantityTableView.layer.cornerRadius = 15
        
        confirmButton.backgroundColor = .clear
        confirmButton.layer.cornerRadius = 25
        confirmButton.layer.borderWidth = 2
        confirmButton.layer.borderColor = UIColor.white.cgColor
        
        confirmButton.setTitleColor(UIColor.white, for: .normal)
        
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        confirmButton.setTitle("Confirm Purchase", for: .normal)

        // Do any additional setup after loading the view.
        
        loadTicketTypes()
    }
    
    func loadTicketTypes(){
        self.ref?.child("vendors").child(vendorID ?? "").child("events").child(eventID ?? "").observeSingleEvent(of: .value, with: {(snapshot) in
            
            let event = snapshot.value as? NSDictionary ?? [:]
            
            let tickets = event["ticketTypes"] as? Dictionary ?? [:]
            
            for (ticketname, ticketprice) in tickets {
                self.ticketTypes.append(TicketType(name: ticketname as? String ?? "", price: ticketprice as? Int ?? 0))
                self.quantityTableView.reloadData()
            }
        })
        
        self.ref?.child("vendors").child(vendorID ?? "").child("events").child(eventID ?? "").child("ticketTypes").observe(.childRemoved, with: {(snapshot) in
            
            let ticket = snapshot.value as? NSDictionary ?? [:]
            
            for (ticketname, _) in ticket {
                for t in self.ticketTypes {
                    if t.name == (ticketname as? String ?? "") {
                        let index = self.ticketTypes.index(of: t)
                        self.ticketTypes.remove(at: index ?? 0)
                    }
                }
            }
            
        })
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ticketTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! TicketTypeTableViewCell
        
        cell.ticketType = ticketTypes[indexPath.row]
        
        cell.ticketTitle.text = ticketTypes[indexPath.row].name
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if let number = formatter.string(from:  NSNumber(value: Float(ticketTypes[indexPath.row].price) / 100)) {
            cell.ticketPrice.text = number
        }
        
        cell.quantity.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateTotalPrice()
    }
    
    func updateTotalPrice(){
        calculateItemTotal()
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        self.feeTextView.text = "Processing Fee: " + (formatter.string(from: (NSNumber(value: Double(self.fees ?? 0) / 100))) ?? "")
        self.subtotalTextView.text = "Total: " + (formatter.string(from: (NSNumber(value: Double(self.paymentTotalInt ?? 0) / 100))) ?? "")
        
        
    }
    
    func calculateItemTotal(){
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        var total = 0
        self.purchaseQuantity = 0
        for cell in self.quantityTableView.visibleCells {
            let c = cell as! TicketTypeTableViewCell
            
            let q = Int(c.quantity.text ?? "0")
            let p = c.ticketType.price
            
            map[c.ticketType] = q
            
            
            self.purchaseQuantity = (self.purchaseQuantity ) + (q ?? 0)
            
            total = total + (p ) * (q ?? 0)
        }
        
        self.paymentTotalWithoutTaxInt = total
        
        //Total = subtotal of items before tax and before TicketHawk Fees
        if (total > 0){
            
            self.fees = Int(ceil((Double(total) * 0.15) + 70 ))
            
            self.paymentTotalInt = (self.fees ?? 0) + total
        } else {
            self.fees = 0
            self.paymentTotalInt = 0
        }
    }
    
    @IBAction func confirmPressed(_ sender: Any) {
        
        calculateItemTotal()
        print(self.paymentTotalInt)
        
        
        
        
        // 1
        guard self.paymentTotalInt ?? 0 > 0 else {
            let alertController = UIAlertController(title: "No Items",
                                                    message: "You haven't selected any tickets.",
                                                    preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(alertAction)
            present(alertController, animated: true)
            return
        }
        
        self.ref?.child("vendors").child(vendorID ?? "").child("events").child(eventID ?? "").observeSingleEvent(of: .value, with: {(snapshot) in
            
            let event = snapshot.value as? NSDictionary
            
            let maxIndivCapacity = event?["maxTickets"] as? Int ?? Int.max
            let going = event?["going"] as? Int ?? 0
            let maxTotalCapacity = event?["totalVenueCapacity"] as? Int ?? Int.max
            
            print("CONDITION")
            print(self.purchaseQuantity)
            print(maxIndivCapacity)
            print(self.purchaseQuantity > maxIndivCapacity)
            if (self.purchaseQuantity > maxIndivCapacity) {
                let alertController = UIAlertController(title: "Exceeds Individual Order Amount",
                                                        message: "The vendor has set a limit of " + String(maxIndivCapacity) + " tickets.",
                                                        preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(alertAction)
                self.present(alertController, animated: true)
                return
            } else {
                //Send price to square
                let theme = STPTheme()
                
                theme.accentColor = Constants.greenColor
                let addCardViewController = STPAddCardViewController(configuration: STPPaymentConfiguration.shared(), theme: theme)
                addCardViewController.delegate = self
                addCardViewController.title = "Enter Card Information"
                self.navigationController?.pushViewController(addCardViewController, animated: true)
            }
            
        })
        
        
        //Upon success:
        //add quantity to going
        //add total sales price to total sales
        //add tickets to customer's tickets
        //copy tickets to vendor's tickets
        
    }
    

}

extension EventTicketNumberViewController: STPAddCardViewControllerDelegate {
    
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        navigationController?.popViewController(animated: true)
    }
    
    func addCardViewController(_ addCardViewController: STPAddCardViewController,
                               didCreateToken token: STPToken,
                               completion: @escaping STPErrorBlock) {
        
        print("token execute")
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        //
        
        self.ref?.child("vendors").child(vendorID ?? "").child("events").child(eventID ?? "").observeSingleEvent(of: .value, with: {(snapshot) in
            
            let event = snapshot.value as? NSDictionary
            
            let maxIndivCapacity = event?["maxTickets"] as? Int ?? Int.max
            let going = event?["going"] as? Int ?? 0
            let maxTotalCapacity = event?["totalVenueCapacity"] as? Int ?? Int.max
            
            if (self.purchaseQuantity + going > maxTotalCapacity){
                let alertController = UIAlertController(title: "Capacity Error",
                                                        message: "There are " + String(maxTotalCapacity - going) + " tickets available for purchase remaining. Please change your order and try again.",
                                                        preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK",
                                                style: UIAlertAction.Style.default,
                                                handler: {(alert: UIAlertAction!) in self.navigationController?.popViewController(animated: true)})
                alertController.addAction(alertAction)
                self.present(alertController, animated: true)
                return
            } else {
                
                
                self.ref?.child("vendors").child(self.vendorID ?? "").observeSingleEvent(of: .value, with: {(snapshot) in
                    
                    let account = snapshot.value as? NSDictionary
                    
                    let accountID = account?["stripeAcctID"] as? String ?? ""
                    
                    StripeClient.shared.completeCharge(with: token, amount: self.paymentTotalInt ?? 0, accountID: accountID, feeAmount: self.fees ?? 0) { result in
                        switch result {
                        // 1
                        case .success:
                            completion(nil)
                            
                            //Update Going and Total Sales using Transactions
                            
                            let goingRef = self.ref?.child("vendors").child(self.vendorID ?? "").child("events").child(self.eventID ?? "").child("going")
                            let grossSalesRef = self.ref?.child("vendors").child(self.vendorID ?? "").child("events").child(self.eventID ?? "").child("grossSales")
                            let netSalesRef = self.ref?.child("vendors").child(self.vendorID ?? "").child("events").child(self.eventID ?? "").child("netSales")
                            
                            goingRef?.runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                                var value = currentData.value as? Int
                                if value == nil {
                                    value = 0
                                }
                                currentData.value = (value ?? 0) + (self.purchaseQuantity )
                                return TransactionResult.success(withValue: currentData)
                            }
                            
                            grossSalesRef?.runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                                
                                let value = currentData.value as? Int ?? 0
                                print("pT" + String(self.paymentTotalWithoutTaxInt ?? 0))
                                currentData.value = value + (Int(self.paymentTotalInt ?? 0 ) )
                                return TransactionResult.success(withValue: currentData)
                            }
                            netSalesRef?.runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                                
                                let value = currentData.value as? Int ?? 0
                                print("pT" + String(self.paymentTotalWithoutTaxInt ?? 0))
                                currentData.value = value + (Int(self.paymentTotalWithoutTaxInt ?? 0 ) )
                                return TransactionResult.success(withValue: currentData)
                            }
                            
                            //Generate Tickets
                            
                            DispatchQueue.global(qos: .background).async {
                                self.generateTickets()
                            }
                            
                            
                            
                            
                            
                            /**
                            //Transition to Ticket Generation
                            let next = self.storyboard!.instantiateViewController(withIdentifier: "customerTicketGenerationViewController") as! CustomerTicketGenerationViewController
                            
                            next.map = self.map
                            next.vendorID = self.vendorID
                            next.eventID = self.eventID
                            
                            
                            self.navigationController!.pushViewController(next, animated: true)
                            **/
                        // 2
                        case .failure(let error):
                            completion(error)
                            
                            DispatchQueue.main.async {
                                UIApplication.shared.endIgnoringInteractionEvents()
                            }
                        }
                    }

                    
                })
            }
            
        })
        
        //
        
        
    }
    
    func generateTickets(){
        
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
        
        /**
        
        self.ref?.child("vendors").child(self.vendorID ?? "").child("closedEvents").child(self.eventID ?? "").observeSingleEvent(of: .value, with:
        {(snapshot) in
            
            if snapshot.value != nil {
                self.ref?.child("vendors").child(self.vendorID ?? "").child("events").child(self.eventID ?? "").removeValue()
            }
            
        })
 
            **/
        
       
        
        if quantity == totalQuantity * 2 {
            
            
            //Check if the event has been closed already
            
            self.ref?.child("vendors").child(self.vendorID ?? "").child("closedEvents").child(self.eventID ?? "").child("eventTitle").observeSingleEvent(of: .value, with:
                
            {(snapshot) in
                
                if !snapshot.exists(){
                    
                    let alert = UIAlertController(title: "Your Purchase was Successful!", message: "View your new tickets in the 'My Tickets' tab.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                        
                        //Update Ticket VC and Archive VC
                        //SplitViewController.ticketsVC?.loadTickets()
                        //SplitViewController.ticketsArchiveVC?.loadTickets()
                        
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    self.present(alert, animated: true, completion: nil)
                    
                    //DispatchQueue.main.async {
                        UIApplication.shared.endIgnoringInteractionEvents()
                    //}
                    
                    
                } else {
                    
                    // Already been closed, remediate through deleting
                    
                    self.ref?.child("vendors").child(self.vendorID ?? "").child("events").child(self.eventID ?? "").removeValue()
                    
                    let alert = UIAlertController(title: "Your Purchase was Unsuccessful!", message: "Contact customer support for information on the refund process.", preferredStyle: UIAlertController.Style.alert)
                                       alert.addAction(UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                                           
                                           //Update Ticket VC and Archive VC
                                           //SplitViewController.ticketsVC?.loadTickets()
                                           //SplitViewController.ticketsArchiveVC?.loadTickets()
                                           
                                           self.navigationController?.popToRootViewController(animated: true)
                                       })
                   self.present(alert, animated: true, completion: nil)
                   
                   //DispatchQueue.main.async {
                       UIApplication.shared.endIgnoringInteractionEvents()
                   //}
                    
                    
                }
                
            })
            
            
            
            
            
        }
    }
    
}







