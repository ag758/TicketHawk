//
//  CustomerMainViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 7/6/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import Firebase
import FirebaseUI
import Alamofire
import AlamofireImage

internal class VendorTableViewCell: UITableViewCell {
    
    @IBOutlet weak var vendorProfileImageView: UIImageView!
    @IBOutlet weak var vendorTitleView: UITextView!
    @IBOutlet weak var vendorCategoryView: UITextView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        vendorProfileImageView.af_cancelImageRequest() // NOTE: - Using AlamofireImage
        vendorProfileImageView.image = nil
    }
}



internal class FeaturedEventCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitleView: UITextView!
    @IBOutlet weak var sellerView: UITextView!
    @IBOutlet weak var dateView: UITextView!
    @IBOutlet weak var priceView: UITextView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
       eventImageView.af_cancelImageRequest() // NOTE: - Using AlamofireImage
        eventImageView.image = nil
    }
    
}

class CustomerMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
UICollectionViewDelegate, UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    
    var communityKey: String?
    
    var ref: DatabaseReference?
    
    var vendors: [Vendor] = []
    
    var loadedEvents: [Event] = []
    
    var loadedEventsStringIDs: [String] = []
    
    var filteredVendors: [Vendor] = []
    
    @IBOutlet var parentView: UIView!
    
    @IBOutlet weak var vendorsSearchBar: UISearchBar!
    
    @IBOutlet weak var eventsCollectionView: UICollectionView!
    
    @IBOutlet weak var vendorsTableView: UITableView!
    
    @IBOutlet weak var communityTitle: UIButton!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Constants.ref
        
        let currentUser = Auth.auth().currentUser
        
        if currentUser == nil{
            let next = self.storyboard!.instantiateViewController(withIdentifier: "splitViewController") as! SplitViewController
            self.present(next, animated: false, completion: nil)
            return
        }
        
        let userID = Auth.auth().currentUser?.uid ?? ""
        
        let custRef : DatabaseReference? = ref?.child("customers").child(userID)
        
        self.onCreateRegardless()
        
        // Attach a listener to read the data at our posts reference
        custRef?.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            
            ///If no value exists -- means false
            let didFinishProfile = value?["didFinishSigningUp"] as? Bool ?? false
            
            
            if didFinishProfile == false {
                do {try Auth.auth().signOut()}
                catch {
                    
                }
                let next = self.storyboard!.instantiateViewController(withIdentifier: "splitViewController") as! SplitViewController
                self.present(next, animated: false, completion: nil)
                return
            } else {
                self.onCreateContinue()
            }
        })
        
    }
    
    func onCreateRegardless(){
        
        
        SplitViewController.customerMainVC = self
        
        self.navigationController!.navigationBar.barTintColor = UIColor.black
        
        let logo = UIImage(named: "thawk_transparent.png")
        let imageView = UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        
        self.navigationItem.title = ""
        
        // Do any additional setup after loading the view.
        
        print("2")
        
        
        vendorsTableView.delegate = self
        vendorsTableView.dataSource = self
        vendorsTableView.reloadData()
        vendorsTableView.rowHeight = 70
        
        vendorsTableView.layer.cornerRadius = 5
        
        eventsCollectionView.delegate = self
        eventsCollectionView.dataSource = self
        eventsCollectionView.reloadData()
        
        vendorsSearchBar.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
        
        //Change height of content view
        
        self.heightConstraint.constant = self.parentView.bounds.height * 1.15
        
        //Transparent Navigation Controller
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
    }
    
    func onCreateContinue(){
        
        loadCommunity()
        
        print("3")
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.vendorsSearchBar.endEditing(true)
    }
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        filteredVendors = searchText.isEmpty ? vendors : vendors.filter({(v: Vendor) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return ((v.name ?? "").range(of: searchText, options: .caseInsensitive) != nil || (v.ticketCategory ?? "").range(of: searchText, options: .caseInsensitive) != nil )
        })
        
        vendorsTableView.reloadData()
        
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        self.vendorsSearchBar.endEditing(true)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredVendors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath.row < filteredVendors.count){
            let cell = self.vendorsTableView
                .dequeueReusableCell(withIdentifier: "vendorCell") as! VendorTableViewCell
            
            cell.tag = indexPath.row
            
            cell.backgroundColor = Constants.almostBlack
            //cell.layer.cornerRadius = 5
            cell.vendorProfileImageView.layer.cornerRadius = 5
            
            cell.vendorTitleView.text = filteredVendors[indexPath.row].name
            cell.vendorCategoryView.text = filteredVendors[indexPath.row].ticketCategory
            
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            
            let url = URL(string: filteredVendors[indexPath.row].pictureURL ?? "") ?? URL(string: "www.apple.com")!
            
            cell.vendorProfileImageView.image = nil
            
            if cell.tag == indexPath.row{
                alamofireLoad(from: url, iv: cell.vendorProfileImageView)
            }
            
            
            for view in cell.subviews {
                view.isUserInteractionEnabled = false
            }
            
            
            
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
    // In this function is the code you must implement to your code project if you want to change size of Collection view
        
        return CGSize(width: eventsCollectionView.bounds.width * 5/6, height: eventsCollectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedEvents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if (indexPath.row < loadedEvents.count){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventCollectionCell", for: indexPath) as! FeaturedEventCollectionViewCell
            
            //tagged
            
            cell.tag = indexPath.row
            
            cell.backgroundColor = Constants.almostBlack
            cell.layer.cornerRadius = 5
            //cell.eventImageView.layer.cornerRadius = 5
            
            cell.eventTitleView.text = loadedEvents[indexPath.row].title
            cell.dateView.text = loadedEvents[indexPath.row].dateAndTime
            cell.priceView.text = loadedEvents[indexPath.row].lowestPrice
            cell.sellerView.text = loadedEvents[indexPath.row].creatorName
            
            cell.eventTitleView.textContainer.maximumNumberOfLines = 1
            cell.eventTitleView.textContainer.lineBreakMode = .byTruncatingTail
            
            cell.dateView.textContainer.maximumNumberOfLines = 1
            cell.dateView.textContainer.lineBreakMode = .byTruncatingTail
            
            cell.priceView.textContainer.maximumNumberOfLines = 1
            cell.priceView.textContainer.lineBreakMode = .byTruncatingTail
            
            cell.sellerView.textContainer.maximumNumberOfLines = 1
            cell.sellerView.textContainer.lineBreakMode = .byTruncatingTail
            
            let url = URL(string: loadedEvents[indexPath.row].imageURL ?? "www.apple.com") ?? URL(string: "www.apple.com")!
            
            cell.eventImageView.image = nil
            
            if cell.tag == indexPath.row {
                 alamofireLoad(from: url, iv: cell.eventImageView)
            }
           
            
            for view in cell.subviews {
                view.isUserInteractionEnabled = false
            }
            
           
            
            
            return cell
        } else {
            return UICollectionViewCell()
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let next = self.storyboard!.instantiateViewController(withIdentifier: "eventViewController") as! EventViewController
        
        next.vendorID = self.loadedEvents[indexPath.row].creatorId
        next.eventID = self.loadedEvents[indexPath.row].id
        self.navigationController!.pushViewController(next, animated: true)
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Transition to Ticket Generation
        let next = self.storyboard!.instantiateViewController(withIdentifier: "customerVendorListViewController") as! CustomerVendorListViewController
        
        next.vendorID = self.filteredVendors[indexPath.row].id
        self.navigationController!.pushViewController(next, animated: true)
    }
    
    func loadCommunity(){
        
        print("communityloaded")
        
        
        //Reset State
        self.vendors = []
        self.loadedEvents = []
        self.loadedEventsStringIDs = []
        self.filteredVendors = []
        
        //Reset Table Views
        self.vendorsTableView.reloadData()
        self.eventsCollectionView.reloadData()
        
        let userID = Auth.auth().currentUser?.uid
        ref?.child("customers").child(userID ?? "").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary ?? [:]
            let cKey = value["primaryCommunity"] as? String ?? ""
            self.communityKey = cKey
            
            self.communityTitle.setTitle(self.communityKey ?? "", for: UIControl.State.normal)
            
            
            //Load Events and vendors things using Community Key
            //print(self.communityKey!)
            self.loadCommunityVendorIDS()
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    func loadEvent(vendorID: String, eventID: String){
        
        ref?.child("vendors").child(vendorID).observeSingleEvent(of: .value, with: {(snapshot) in
            
            let value = snapshot.value as? NSDictionary ?? [:]
            let vendorName = value["organizationName"] as? String ?? ""
            
            let eventSnapshot = snapshot.childSnapshot(forPath: "events").childSnapshot(forPath: eventID)
                
            let event = eventSnapshot.value as? NSDictionary ?? [:]
                
            let title = event["eventTitle"] as? String ?? ""
            var startDateAndTime = event["startDateAndTime"] as? String ?? "No Date Found"
            let pictureURL = event["pictureURL"] as? String ?? ""
            let tickets = event["ticketTypes"] as? Dictionary ?? [:]
            let id = event["key"] as? String ?? ""
            
            let unformatted = startDateAndTime
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                let d1: Date = dateFormatter.date(from: startDateAndTime) ?? Date()
                
                let dateFormatter2 = DateFormatter()
                dateFormatter2.amSymbol = "AM"
                dateFormatter2.pmSymbol = "PM"
                dateFormatter2.dateFormat = "MMM d, h:mm a"
                
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
                    
                    let eventInstance = Event(title: title, dateAndTime: startDateAndTime, lowestPrice: number, imageURL: pictureURL, id: id, creatorId: vendorID, creatorName: vendorName, unformatted: unformatted)
                    
                    //only if date is after
                    
                    let endDate = dateFormatter.date(from: event["endDateAndTime"] as? String ?? "")
                    
                    if endDate ?? Date() > Date(){
                        print("jellyfish")
                    }
                    
                    //self.loadedEvents.append(eventInstance)
                    self.loadedEvents = self.randomAppend(array: self.loadedEvents, object: eventInstance) as? [Event] ?? []
                    
                    DispatchQueue.global(qos: .background).async {
                        print("This is run on the background queue")
                        
                        //self.loadedEvents.shuffle()
                        print(self.loadedEvents.count)
                        
                        DispatchQueue.main.async {
                            print("This is run on the main queue, after the previous code in outer block")
                            self.eventsCollectionView.reloadData()
                        }
                        
                        
                    }
                    
                    
                    
                    
                    
                    
                }
                
            
        })
        
    }
    
    func chooseEventFromVendor(vid: String){
        self.ref?.child("vendors").child(vid).child("events").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            let keys = value?.allKeys
            
            let range = (0..<(keys?.count ?? 0))
            if !range.isEmpty{
                let eventIndex = Int.random(in: range)
                
                let eventId = keys?[eventIndex] as? String ?? ""
                
                var isAlreadyAdded = false
                
                for e in self.loadedEventsStringIDs {
                    if e == eventId{
                        isAlreadyAdded = true
                    }
                }
                    
                    if !isAlreadyAdded {
                        self.loadedEventsStringIDs.append(eventId)
                        self.loadEvent(vendorID: vid, eventID: eventId)
                    }
            }
        })
    }
    
    
    
    
    func loadCommunityVendorIDS(){
        let query = ref?.child("communities").child(communityKey ?? "").child("vendors")
        
        query?.observeSingleEvent(of: .value, with: {(snapshot) in
            
            let keydict = snapshot.value as? NSDictionary ?? [:]
            let keys = keydict.allKeys
            
            for k in keys {
                
                DispatchQueue.global(qos: .background).async {
                    self.chooseEventFromVendor(vid: k as? String ?? "")
                }
                
                DispatchQueue.global(qos: .background).async {
                    self.loadCommunityVendorDetails(vendorid: k as? String ?? "")
                }
                
                
               
            }
            
            
            
        })
        query?.observe(.childRemoved, with: { (snapshot) in
            let vendor = snapshot.value as? NSDictionary ?? [:]
            let i = vendor["id"] as? String ?? ""
            
            for v in self.vendors {
                if v.id == i {
                    self.vendors.remove(at: self.vendors.index(of: v)!)
                    self.vendorsTableView.reloadData()
                }
            }
            
        })
    }
    
    func loadCommunityVendorDetails(vendorid: String){
        
        ref?.child("vendors").child(vendorid).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            
            ///If no value exists -- means false
            let orgName = value?["organizationName"] as? String ?? ""
            let pictureURL = value?["organizationProfileImage"] as? String ?? ""
            let ticketCategory = value?["ticketCategory"] as? String ?? ""
            let vendorToBeAdded = Vendor(id: vendorid, name: orgName, pictureURL: pictureURL, ticketCategory: ticketCategory)
            
            self.vendors = self.randomAppend(array: self.vendors, object: vendorToBeAdded) as? [Vendor] ?? []
        
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async {
                    self.filteredVendors = self.vendors
                    
                    self.vendorsTableView.reloadData()
                }
            }
            })
        
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func randomAppend(array: [NSObject], object: NSObject) -> [NSObject]{
        var returnedArray = array
        returnedArray.insert(object, at: Int.random(in: 0 ... returnedArray.count))
        return returnedArray
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
    
    func alamofireLoad (from url: URL, iv: UIImageView){
        iv.af_setImage(withURL: url)
    }
    
    @IBAction func communityButtonIsPressed(_ sender: Any) {
        let next = self.storyboard!.instantiateViewController(withIdentifier: "communityEditViewController") as! CommunityEditViewController
        self.navigationController!.pushViewController(next, animated: true)
    }
    
    

}
