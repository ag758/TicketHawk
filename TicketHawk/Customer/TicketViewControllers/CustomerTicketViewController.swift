//
//  CustomerTicketViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 7/28/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

internal class TicketCustomClass: UITableViewCell {
    
    @IBOutlet weak var qrCodeView: UIImageView!
    @IBOutlet weak var eventTitle: UITextView!
    @IBOutlet weak var ticketType: UITextView!
    @IBOutlet weak var userName: UITextView!
    @IBOutlet weak var dateAndTime: UITextView!
    @IBOutlet weak var location: UITextView!
    
    @IBOutlet weak var bottomRounded: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
}

extension NSLayoutConstraint {
    
    override open var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)" //you may print whatever you want here
    }
}

class CustomerTicketViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
  

    @IBOutlet weak var ticketsMasterTableView: UITableView!
    
    @IBOutlet var parentView: UIView!
    
    var tickets: [Ticket] = []
    
    var ref: DatabaseReference?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SplitViewController.ticketsVC = self

        // Do any additional setup after loading the view.
        
        self.navigationController!.navigationBar.barTintColor = UIColor.black
        
        let logo = UIImage(named: "thawk_transparent.png")
        let imageView = UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        
        ref = Constants.ref
        
        self.ticketsMasterTableView.rowHeight = ticketsMasterTableView.bounds.height
        self.ticketsMasterTableView.backgroundColor = UIColor.clear
        
        self.ticketsMasterTableView.dataSource = self
        self.ticketsMasterTableView.delegate = self
        
        loadTickets()
        
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func loadTickets(){
        
        tickets = []
        
        let query = ref?.child("customers").child(Auth.auth().currentUser!.uid).child("activeTickets")
        
        query?.removeAllObservers()
        query?.observe(.childAdded, with: { (snapshot) in
            
            let ticket = snapshot.value as? NSDictionary
            
            let key = ticket!["key"] as! String
            let eventTitle = ticket!["title"] as? String ?? ""
            let dateAndTime = ticket!["dateAndTime"] as? String ?? "No Date Found"
            let ticketType = ticket!["ticketType"] as? String ?? ""
            let userName = ticket!["userName"] as? String ?? ""
            let location = ticket!["location"] as? String ?? ""
            
            print("ticket_date_debug" + dateAndTime)
            
            
            let ticketInstance = Ticket(key: key, eventTitle: eventTitle, ticketType: ticketType, userName: userName, dateAndTime: dateAndTime, location: location)
            //self.tickets.append(ticketInstance)
            //DispatchQueue.global(qos: .background).async {
                //print("This is run on the background queue")
                
                //self.tickets = self.sortTableViewByTime(tickets: self.tickets)
                self.appendAfterDate(ticket: ticketInstance)
                
                //DispatchQueue.main.async {
                    //print("This is run on the main queue, after the previous code in outer block")
                    
                    self.ticketsMasterTableView.reloadData()
                //}
            //}
                 
            
        })
        query?.observe(.childRemoved, with: { (snapshot) in
            let ticket = snapshot.value as? NSDictionary
            let key = ticket!["key"] as! String
            
            var index = 0
            for t in self.tickets{
                if t.key == key{
                    index = self.tickets.index(of: t) ?? 0
                    self.tickets.remove(at: index)
                    
                }
            }
            
            self.ticketsMasterTableView.reloadData()
            
            
        })
 
    }
    
    func appendAfterDate(ticket: Ticket){
        var index = 0;
        while (index < tickets.count){
            if compareDates(date1: self.tickets[index].dateAndTime, date2: ticket.dateAndTime) == false{
                index+=1
            } else {
                break
            }
        }
        self.tickets.insert(ticket, at: index)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath.row < self.tickets.count){
            let cell = tableView.dequeueReusableCell(withIdentifier: "ticketCustomClass", for: indexPath) as! TicketCustomClass
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            cell.layer.cornerRadius = 20
            
            cell.bottomRounded.layer.cornerRadius = 20
            
            encodeKeyAsQRCode(imageView: cell.qrCodeView, key: tickets[indexPath.row].key)
            
            cell.dateAndTime.text = tickets[indexPath.row].dateAndTime
            cell.eventTitle.text = tickets[indexPath.row].eventTitle
            cell.location.text = tickets[indexPath.row].location
            cell.ticketType.text = tickets[indexPath.row].ticketType
            cell.userName.text = tickets[indexPath.row].userName
            
            for view in cell.subviews{
                view.isUserInteractionEnabled = false
            }
            
            
            return cell
        } else {
            return UITableViewCell()
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
            return self.ticketsMasterTableView.bounds.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "", message: self.tickets[indexPath.row].eventTitle, preferredStyle: .actionSheet)
       
        alert.addAction(UIAlertAction(title: NSLocalizedString("Archive", comment: ""), style: .default, handler: { _ in
            
            //Add node to archivedTickets
            
            let ticketKey = self.tickets[indexPath.row].key
            
            //
            
            self.ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").child("activeTickets").child(ticketKey).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let ticket = snapshot.value
                
                self.ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").child("archivedTickets").child(ticketKey).setValue(ticket){ (error, ref) -> Void in
                    
                    self.ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").child("activeTickets").child(ticketKey).removeValue() { (error, ref) -> Void in
                        
                        //Completed Succesfully
                    }
                }
                
            })
            
            //
            
            /**
            
            let ticket = self.tickets[indexPath.row]
            
            let post = ["userName": ticket.userName,
                        "title": ticket.eventTitle,
                        "dateAndTime": ticket.dateAndTime,
                        "location": ticket.location,
                        "ticketType": ticket.ticketType,
                        "key": ticket.key
                ] as [String : Any]
            
            let update1 = ["/customers/\(Auth.auth().currentUser?.uid ?? "")/archivedTickets/\(ticket.key)": post]
            self.ref?.updateChildValues(update1)
            
            //Remove node from activeTickets
            
            self.ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").child("activeTickets").child(ticket.key).removeValue()
            
            //SplitViewController.ticketsVC?.loadTickets()
            //SplitViewController.ticketsArchiveVC?.loadTickets()
 
            **/
            
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Default action"), style: .default, handler: { _ in
            
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
            /**
            let archive = UITableViewRowAction(style: .normal, title: "Archive") { action, index in
                
                //Add node to archivedTickets
                
                let ticket = self.tickets[indexPath.row]
                
                let post = ["userName": ticket.userName,
                            "title": ticket.eventTitle,
                            "dateAndTime": ticket.dateAndTime,
                            "location": ticket.location,
                            "ticketType": ticket.ticketType,
                            "key": ticket.key
                    ] as [String : Any]
                
                let update1 = ["/customers/\(Auth.auth().currentUser?.uid ?? "")/archivedTickets/\(ticket.key)": post]
                self.ref?.updateChildValues(update1)
                
                //Remove node from activeTickets
                
                self.ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").child("activeTickets").child(ticket.key).removeValue()
                
                //SplitViewController.ticketsVC?.loadTickets()
                //SplitViewController.ticketsArchiveVC?.loadTickets()
                
                
                
                
            }
        
            archive.backgroundColor = UIColor.black
            
            
            return [archive]
 
 **/
        return []
        
        
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        //ticketsMasterTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        //ticketsMasterTableView.reloadData()
    }
    
    func encodeKeyAsQRCode(imageView: UIImageView, key: String){
        
        DispatchQueue.global(qos: .background).async {
            print("This is run on the background queue")
            
            // import UIKit
            // Get define string to encode
            let myString = key
            // Get data from the string
            let data = myString.data(using: String.Encoding.ascii)
            // Get a QR CIFilter
            guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return }
            // Input the data
            qrFilter.setValue(data, forKey: "inputMessage")
            // Get the output image
            guard let qrImage = qrFilter.outputImage else { return }
            // Scale the image
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQrImage = qrImage.transformed(by: transform)
            // Do some processing to get the UIImage
            let context = CIContext()
            guard let cgImage = context.createCGImage(scaledQrImage, from: scaledQrImage.extent) else { return }
            let processedImage = UIImage(cgImage: cgImage)
            
            DispatchQueue.main.async {
                print("This is run on the main queue, after the previous code in outer block")
                imageView.image = processedImage
            }
            
            
        }
    
       
        
     
    }
    
    func sortTableViewByTime(tickets: [Ticket]) -> [Ticket] {
        var ticketsMut = tickets
        var x = 0
        while (x < ticketsMut.count-1) {
            var closestInt = x
            for y in x+1...ticketsMut.count-1 {
                if compareDates(date1: tickets[x].dateAndTime, date2: tickets[y].dateAndTime) == true{
                    closestInt = y
                }
            }
            //swap shortest and x
            ticketsMut.swapAt(x, closestInt)
            x = x+1
        }
        
        return ticketsMut
    }
    
    func compareDates (date1: String, date2: String) -> Bool {
        
        print("d1" + date1)
        print("d2" + date2)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy h:mm a"
        
        let d1: Date = dateFormatter.date(from: date1)!
        let d2: Date = dateFormatter.date(from: date2)!
        
        if (d1 > d2){
            return true
        }
        return false
    }
    
    
    @IBAction func goToArchiveViewController(_ sender: Any) {
        
        //SplitViewController.customerMainVC?.loadCommunity()
        
        
        
        let next = self.storyboard!.instantiateViewController(withIdentifier: "customerArchiveTicketViewController") as! CustomerArchiveTicketViewController
        
        self.navigationController!.pushViewController(next, animated: true)
        
    }
    

}
