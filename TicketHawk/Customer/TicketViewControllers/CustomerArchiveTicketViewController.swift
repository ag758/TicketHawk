//
//  CustomerArchiveTicketViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 9/9/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class CustomerArchiveTicketViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
    @IBOutlet weak var archivedTicketsTableView: UITableView!
    
    var tickets: [Ticket] = []
    
    var ref: DatabaseReference?

    override func viewDidLoad() {
        print("debug_view_did_load")
        
        self.navigationItem.title = "Archive";
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        super.viewDidLoad()
        
        SplitViewController.ticketsArchiveVC = self
        
        self.ref = Constants.ref
        
        loadTickets()
        
        archivedTicketsTableView.dataSource = self
        archivedTicketsTableView.delegate = self
        
        archivedTicketsTableView.layer.cornerRadius = 10
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row < tickets.count){
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "archiveCell")
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            cell.textLabel?.text = tickets[indexPath.row].eventTitle
            cell.detailTextLabel?.text = tickets[indexPath.row].ticketType + " | " + tickets[indexPath.row].dateAndTime
            return cell
        } else {
            return UITableViewCell()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let alert = UIAlertController(title: "", message: self.tickets[indexPath.row].eventTitle, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Un-archive", comment: ""), style: .default, handler: { _ in
            
            //Add node to activeTickets
            
            let ticket = self.tickets[indexPath.row]
            
            let post = ["userName": ticket.userName,
                        "title": ticket.eventTitle,
                        "dateAndTime": ticket.dateAndTime,
                        "location": ticket.location,
                        "ticketType": ticket.ticketType,
                        "key": ticket.key
                ] as [String : Any]
            
            let update1 = ["/customers/\(Auth.auth().currentUser?.uid ?? "")/activeTickets/\(ticket.key)": post]
            self.ref?.updateChildValues(update1)
            
            //Remove node from archivedTickets
            
            self.ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").child("archivedTickets").child(ticket.key).removeValue()
            
            //SplitViewController.ticketsVC?.loadTickets()
            //SplitViewController.ticketsArchiveVC?.loadTickets()
            
            
            
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Default action"), style: .default, handler: { _ in
            
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        /**
        let unarchive = UITableViewRowAction(style: .normal, title: "Unarchive") { action, index in
            
            //Add node to activeTickets
            
            let ticket = self.tickets[indexPath.row]
            
            let post = ["userName": ticket.userName,
                        "title": ticket.eventTitle,
                        "dateAndTime": ticket.dateAndTime,
                        "location": ticket.location,
                        "ticketType": ticket.ticketType,
                        "key": ticket.key
                ] as [String : Any]
            
            let update1 = ["/customers/\(Auth.auth().currentUser?.uid ?? "")/activeTickets/\(ticket.key)": post]
            self.ref?.updateChildValues(update1)
            
            //Remove node from archivedTickets
            
        self.ref?.child("customers").child(Auth.auth().currentUser?.uid ?? "").child("archivedTickets").child(ticket.key).removeValue()
            
            //SplitViewController.ticketsVC?.loadTickets()
            //SplitViewController.ticketsArchiveVC?.loadTickets()
            
            
            
            
        }
        unarchive.backgroundColor = SplitViewController.greenColor
        
 
        return [unarchive]
 
 **/
        return []
    }
    
    func loadTickets(){
        
        tickets = []
        
        let query = ref?.child("customers").child(Auth.auth().currentUser!.uid).child("archivedTickets")
        
        query?.removeAllObservers()
        query?.observe(.childAdded, with: { (snapshot) in
            
            print("debug_child_added" + String(self.tickets.count))
            
            let ticket = snapshot.value as? NSDictionary
            
            let key = ticket!["key"] as! String
            let eventTitle = ticket!["title"] as? String ?? ""
            let dateAndTime = ticket!["dateAndTime"] as? String ?? "No Date Found"
            let ticketType = ticket!["ticketType"] as? String ?? ""
            let userName = ticket!["userName"] as? String ?? ""
            let location = ticket!["location"] as? String ?? ""
            
            
            let ticketInstance = Ticket(key: key, eventTitle: eventTitle, ticketType: ticketType, userName: userName, dateAndTime: dateAndTime, location: location)
            //self.tickets.append(ticketInstance)
            //DispatchQueue.global(qos: .background).async {
                //print("This is run on the background queue")
                
                //self.tickets = self.sortTableViewByTime(tickets: self.tickets)
                self.appendAfterDate(ticket: ticketInstance)
                
                //DispatchQueue.main.async {
                    //print("This is run on the main queue, after the previous code in outer block")
                    
                    self.archivedTicketsTableView.reloadData()
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
            
             self.archivedTicketsTableView.reloadData()
            
           
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

}
