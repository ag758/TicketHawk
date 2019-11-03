//
//  CustomerVendorListViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 9/4/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FirebaseDatabase

internal class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UITextView!
    @IBOutlet weak var dateView: UITextView!
    @IBOutlet weak var priceView: UITextView!
    
    
    @IBOutlet weak var bottomRound: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        eventImageView.af_cancelImageRequest() // NOTE: - Using AlamofireImage
        eventImageView.image = nil
    }
}

class CustomerVendorListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    

    @IBOutlet weak var vendorImageView: UIImageView!
    @IBOutlet weak var vendorNameView: UIButton!
    
    @IBOutlet weak var vendorTableView: UITableView!
    
    @IBOutlet weak var phoneNumber: UIButton!
    
    @IBOutlet weak var email: UIButton!
    
    @IBOutlet weak var reportBottom: UIButton!
    
    
    var vendorID: String?
    
    var ref: DatabaseReference?
    
    var events: [Event] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Constants.ref
        
        vendorTableView.dataSource = self
        vendorTableView.delegate = self
        vendorTableView.rowHeight = vendorTableView.frame.height / 2
        //vendorTableView.layer.cornerRadius = 15
        vendorTableView.backgroundColor = UIColor.clear
        
        reportBottom.backgroundColor = .clear
        reportBottom.layer.cornerRadius = 15
        reportBottom.layer.borderWidth = 1
        reportBottom.layer.borderColor = UIColor.lightGray.cgColor

        reportBottom.setTitleColor(UIColor.lightGray, for: .normal)
        
        reportBottom.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        
        // Do any additional setup after loading the view.
    ref?.child("vendors").child(self.vendorID!).observeSingleEvent(of: .value, with: {(snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
        self.vendorNameView.setTitle(value?["organizationName"] as? String ?? "", for: UIControl.State.normal)
            
            self.alamofireLoad(from: URL(string : value?["organizationProfileImage"] as? String ?? "") ?? URL(string: "www.apple.com")!, iv: self.vendorImageView)
        
        self.phoneNumber.setTitle("📞 " + (value?["custSuppPhoneNumber"] as? String ?? ""), for: .normal)
        self.email.setTitle("✉️ " + (value?["custSupportEmail"] as? String ?? ""), for: .normal)
        })
        
        
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        loadEvents()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventTableViewCell", for: indexPath) as! EventTableViewCell
         cell.backgroundColor = Constants.almostBlack
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        cell.dateView.text = events[indexPath.row].dateAndTime
        cell.eventTitle.text = events[indexPath.row].title
        cell.priceView.text = events[indexPath.row].lowestPrice
        
        cell.bottomRound.backgroundColor = Constants.almostBlack
        //cell.eventImageView.layer.cornerRadius = 5
        cell.bottomRound.layer.cornerRadius = 5
        cell.layer.cornerRadius = 5
        
        let url = URL(string: events[indexPath.row].imageURL!) ?? URL(string: "www.apple.com")!
        
        alamofireLoad(from: url, iv: cell.eventImageView)
        
        cell.dateView.textContainer.maximumNumberOfLines = 1
        cell.dateView.textContainer.lineBreakMode = .byTruncatingTail
        
        cell.eventTitle.textContainer.maximumNumberOfLines = 1
        cell.eventTitle.textContainer.lineBreakMode = .byTruncatingTail
        
        cell.priceView.textContainer.maximumNumberOfLines = 1
        cell.priceView.textContainer.lineBreakMode = .byTruncatingTail
        
        
        for view in cell.subviews {
            view.isUserInteractionEnabled = false
        }
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let next = self.storyboard!.instantiateViewController(withIdentifier: "eventViewController") as! EventViewController
        
        next.vendorID = self.events[indexPath.row].creatorId
        next.eventID = self.events[indexPath.row].id
        self.navigationController!.pushViewController(next, animated: true)
    }
    
    func loadEvents(){
        let query = ref?.child("vendors").child(vendorID ?? "")
        
        query?.observeSingleEvent(of: .value, with: {(snapshot) in
            
            let ownName = (snapshot.value as? NSDictionary ?? [:] )["organizationName"] as? String ?? ""
            
            let eventsSnapshot = snapshot.childSnapshot(forPath: "events").value as? NSDictionary ?? [:]
            let allKeys = eventsSnapshot.allKeys
            
            for k in allKeys{
                
                let event = snapshot.childSnapshot(forPath: "events").childSnapshot(forPath: k as? String ?? "").value as? NSDictionary ?? [:]
                
                let title = event["eventTitle"] as! String
                var startDateAndTime = event["startDateAndTime"] as? String ?? "No Date Found"
                let pictureURL = event["pictureURL"] as? String ?? ""
                let tickets = event["ticketTypes"] as? Dictionary ?? [:]
                let id = event["key"] as? String ?? ""
                
                let unformatted = startDateAndTime
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                let d1: Date = dateFormatter.date(from: startDateAndTime)!
                
                let dateFormatter2 = DateFormatter()
                dateFormatter2.amSymbol = "AM"
                dateFormatter2.pmSymbol = "PM"
                dateFormatter2.dateFormat = "MMMM dd h:mm a"
                
                startDateAndTime = dateFormatter2.string(from: d1)
                
                var minimumprice: Double = Double.greatestFiniteMagnitude
                for (_, ticketprice) in tickets {
                    if ((ticketprice as? Double ?? 0) / 100 < minimumprice){
                        minimumprice = (ticketprice as? Double  ?? 0) / 100
                    }
                }
                
                
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                
                if let number = formatter.string(from: NSNumber(value: minimumprice)) {
                    print(number)
                    
                        let eventInstance = Event(title: title, dateAndTime: startDateAndTime, lowestPrice: number, imageURL: pictureURL, id: id, creatorId: self.vendorID ?? "",
                                                  creatorName: ownName, unformatted: unformatted
                        )
                        
                        //only if the date is greater than current
                        if (d1 > Date()){
                            
                            self.events.append(eventInstance)
                            self.events = self.sortTableViewByTime(events: self.events)
                            
                            self.vendorTableView.reloadData()
                        }
                        
                    
                    
                }
                
                
            }
            
        })
    }
    
    func sortTableViewByTime(events: [Event]) -> [Event] {
        var eventsMut = events
        var x = 0
        while (x < events.count-1) {
            var closestInt = x
            for y in x+1...events.count-1 {
                if compareDates(date1: events[x].unformattedDateAndTime!, date2: events[y].unformattedDateAndTime!) == true{
                    closestInt = y
                }
            }
            //swap shortest and x
            eventsMut.swapAt(x, closestInt)
            x = x+1
        }
        
        return eventsMut
    }
    
    func compareDates (date1: String, date2: String) -> Bool {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let d1: Date = dateFormatter.date(from: date1)!
        let d2: Date = dateFormatter.date(from: date2)!
        
        if (d1 > d2){
            return true
        }
        return false
    }
    
    
    @IBAction func reportVendor(_ sender: Any) {
        guard let url = URL(string: Constants.howToReportURL) else {
            return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
        
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func alamofireLoad (from url: URL, iv: UIImageView){
        iv.af_setImage(withURL: url)
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

}
