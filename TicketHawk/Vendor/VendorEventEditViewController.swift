//
//  VendorEventEditViewController.swift
//  TicketHawk
//
//  Created by Austin Gao on 9/22/19.
//  Copyright © 2019 Austin Gao. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class VendorEventEditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var dateAndTimePicker: UIDatePicker?
    private var dateAndTimePicker2: UIDatePicker?
    
    var ref: DatabaseReference?
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var startDateAndTimeField: CustomUITextField!
    @IBOutlet weak var endDateAndTimeField: CustomUITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var imageURLTextField: UITextField!
    @IBOutlet weak var imageURLImageView: UIImageView!
    @IBOutlet weak var maxTickets: CustomUITextField!
    @IBOutlet weak var dressCodeTextField: UITextField!
    @IBOutlet weak var maxVenueCapacity: CustomUITextField!
    @IBOutlet weak var eventDescription: UITextField!
    
    
    @IBOutlet weak var ticketTypeName: UITextField!
    @IBOutlet weak var ticketTypeCost: CustomUITextField!
    
    @IBOutlet weak var ticketTypeTableView: UITableView!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    var eventID: String?
    
    
    var ticketTypes: [TicketType] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        
        ref = SplitViewController.ref
        
        dateAndTimePicker = UIDatePicker()
        dateAndTimePicker?.datePickerMode = .dateAndTime
        dateAndTimePicker?.addTarget(self, action: #selector(dateChanged(dateAndTimePicker:)), for: .valueChanged)
        startDateAndTimeField.inputView = dateAndTimePicker
        
        dateAndTimePicker2 = UIDatePicker()
        dateAndTimePicker2?.datePickerMode = .dateAndTime
        dateAndTimePicker2?.addTarget(self, action: #selector(dateChanged2(dateAndTimePicker2:)), for: .valueChanged)
        endDateAndTimeField.inputView = dateAndTimePicker2
        
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        imageURLTextField.addTarget(self, action: #selector(CreateEventViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        ticketTypeTableView.delegate = self
        ticketTypeTableView.dataSource = self
        ticketTypeTableView.reloadData()
        
        cancelButton.backgroundColor = .clear
        cancelButton.layer.cornerRadius = 17.5
        cancelButton.layer.borderWidth = 2
        cancelButton.layer.borderColor = UIColor.white.cgColor
        
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        cancelButton.setTitle("Cancel Change", for: .normal)
        
        confirmButton.backgroundColor = .clear
        confirmButton.layer.cornerRadius = 17.5
        confirmButton.layer.borderWidth = 2
        confirmButton.layer.borderColor = SplitViewController.greenColor.cgColor
        confirmButton.setTitleColor(SplitViewController.greenColor, for: .normal)
        
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        confirmButton.setTitle("Confirm Change", for: .normal)
        
        fetchDefaults()
        
    }
    
    func fetchDefaults(){
        self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(self.eventID ?? "").observeSingleEvent(of: .value, with: {(snapshot) in
            let value = snapshot.value as? NSDictionary ?? [:]
            
            self.titleTextField.text = value["eventTitle"] as? String ?? ""
            self.startDateAndTimeField.text = value["startDateAndTime"] as? String ?? ""
            self.endDateAndTimeField.text = value["endDateAndTime"] as? String ?? ""
            self.addressField.text = value["location"] as? String ?? ""
            self.imageURLTextField.text = value["pictureURL"] as? String ?? ""
            
            if (self.imageURLTextField.text?.isEmpty == false){
                let url = URL(string: self.imageURLTextField.text!) ?? URL(string: "www.apple.com")!
                self.downloadImage(from: url)
            }
        
            self.maxTickets.text = value["maxTickets"] as? String ?? ""
            self.dressCodeTextField.text = value["dressCode"] as? String ?? ""
            self.maxVenueCapacity.text = value["totalVenueCapacity"] as? String ?? ""
            self.eventDescription.text = value["description"] as? String ?? ""
            
            
            
            let ticketTypes = value["ticketTypes"] as? NSDictionary ?? [:]
            
            for k in ticketTypes {
                self.ticketTypes.append(TicketType(name: k.key as? String ?? "", price: k.value as? Int ?? 0))
                self.ticketTypeTableView.reloadData()
            }
            })
    }
    
    @IBAction func addTicketTypePressed(_ sender: Any) {
        
        if (ticketTypeName.text?.isEmpty == false && ticketTypeCost.text?.isEmpty == false){
            
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .currency
            // localize to your grouping and decimal separator
            currencyFormatter.locale = Locale.current
            //currencyFormatter.maximumFractionDigits = 2
            
            // We'll force unwrap with the !, if you've got defined data you may need more error checking
            
            if let double = Double(ticketTypeCost.text!) {
                print("double" + String(double))
                if (double >= 1){
                    ticketTypeCost.layer.borderWidth = 0
                    let priceString = currencyFormatter.string(from: double as NSNumber)!
                    
                    print("priceString" + priceString)
                    
                    if let number = currencyFormatter.number(from: priceString) {
                        //add the type to the tableview
                        
                        
                        
                        let f = Double(truncating: number) * 100
                        
                        let newTicketType = TicketType(name: ticketTypeName.text!, price: Int(exactly: f.rounded()) ?? 0)
                        ticketTypes.append(newTicketType)
                        
                        ticketTypeName.text = ""
                        ticketTypeCost.text = ""
                        
                        ticketTypeTableView.reloadData()
                    }
                } else {
                    ticketTypeCost.layer.borderWidth = 1
                    ticketTypeCost.layer.borderColor = UIColor.red.cgColor
                }
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ticketTypes.remove(at: indexPath.row)
            ticketTypeTableView.deleteRows(at: [indexPath], with: .fade)
            ticketTypeTableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.ticketTypes.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //variable type is inferred
        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL")
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "CELL")
        }
        
        cell!.textLabel?.text = ticketTypes[indexPath.row].name
        
        let i = ticketTypes[indexPath.row].price
        let d = Double(i) / 100
        
        print("d_value" + String(d))
        
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if let number = formatter.string(from:  NSNumber(value: d)) {
            cell!.detailTextLabel?.text = number
        }
        
        
        
        
        return cell!
    }
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if (textField.text?.isEmpty == false){
            let url = URL(string: imageURLTextField.text!) ?? URL(string: "www.apple.com")!
            downloadImage(from: url)
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.imageURLImageView.image = UIImage(data: data)
            }
        }
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer){
        view.endEditing(true)
    }
    
    @objc func dateChanged(dateAndTimePicker: UIDatePicker){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        startDateAndTimeField.text = dateFormatter.string(from: dateAndTimePicker.date)
        //view.endEditing(true)
        
    }
    
    @objc func dateChanged2(dateAndTimePicker2: UIDatePicker){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        endDateAndTimeField.text = dateFormatter.string(from: dateAndTimePicker2.date)
        //view.endEditing(true)
        
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func checkCorrectNess() -> Bool {
        
        var shouldUpload: Bool = true
        
        if (titleTextField.text!.isEmpty){
            shouldUpload = false
            titleTextField.layer.borderWidth = 1
            titleTextField.layer.borderColor = UIColor.red.cgColor
        } else {
            titleTextField.layer.borderWidth = 0
        }
        
        if (startDateAndTimeField.text!.isEmpty){
            shouldUpload = false
            startDateAndTimeField.layer.borderWidth = 1
            startDateAndTimeField.layer.borderColor = UIColor.red.cgColor
        } else {
            endDateAndTimeField.layer.borderWidth = 0
        }
        
        if (endDateAndTimeField.text!.isEmpty){
            shouldUpload = false
            endDateAndTimeField.layer.borderWidth = 1
            endDateAndTimeField.layer.borderColor = UIColor.red.cgColor
        } else {
            endDateAndTimeField.layer.borderWidth = 0
        }
        
        if (Float(maxVenueCapacity.text!) ?? 1000 <= 0){
            shouldUpload = false
            maxVenueCapacity.layer.borderWidth = 1
            maxVenueCapacity.layer.borderColor = UIColor.red.cgColor
        } else {
            maxVenueCapacity.layer.borderWidth = 0
        }
        
        if (Float(maxTickets.text!) ?? 1000 <= 0){
            shouldUpload = false
            maxTickets.layer.borderWidth = 1
            maxTickets.layer.borderColor = UIColor.red.cgColor
        } else {
            maxTickets.layer.borderWidth = 0
        }
        
        if (addressField.text!.isEmpty){
            shouldUpload = false
            addressField.layer.borderWidth = 1
            addressField.layer.borderColor = UIColor.red.cgColor
        } else {
            addressField.layer.borderWidth = 0
        }
        
        if (imageURLTextField.text!.isEmpty){
            shouldUpload = false
            imageURLTextField.layer.borderWidth = 1
            imageURLTextField.layer.borderColor = UIColor.red.cgColor
        } else {
            imageURLTextField.layer.borderWidth = 0
        }
        
        if (ticketTypes.count == 0){
            shouldUpload = false
            ticketTypeTableView.layer.borderWidth = 1
            ticketTypeTableView.layer.borderColor = UIColor.red.cgColor
        } else {
            ticketTypeTableView.layer.borderWidth = 0
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        endDateAndTimeField.layer.borderWidth = 0
        startDateAndTimeField.layer.borderWidth = 0
        
        if let d1 = dateFormatter.date(from: startDateAndTimeField.text!){
            if let d2 = dateFormatter.date(from: endDateAndTimeField.text!){
                
                
                
                if (d1 < Date()) {shouldUpload = false
                    startDateAndTimeField.layer.borderWidth = 1
                    startDateAndTimeField.layer.borderColor = UIColor.red.cgColor
                }
                if (d2 < Date()) {shouldUpload = false
                    endDateAndTimeField.layer.borderWidth = 1
                    endDateAndTimeField.layer.borderColor = UIColor.red.cgColor
                }
                
                if (d1 > d2) {shouldUpload = false
                    startDateAndTimeField.layer.borderWidth = 1
                    startDateAndTimeField.layer.borderColor = UIColor.red.cgColor
                    endDateAndTimeField.layer.borderWidth = 1
                    endDateAndTimeField.layer.borderColor = UIColor.red.cgColor
                }
                
            }else {
                shouldUpload = false
                endDateAndTimeField.layer.borderWidth = 1
                endDateAndTimeField.layer.borderColor = UIColor.red.cgColor
            }
        } else {
            shouldUpload = false
            startDateAndTimeField.layer.borderWidth = 1
            startDateAndTimeField.layer.borderColor = UIColor.red.cgColor
        }
        
        return shouldUpload
    }
    
    @IBAction func confirmPressed(_ sender: Any) {
        
        //Write to Firebase Database
        
        //Check for correctness constraints
        
        var shouldUpload: Bool = checkCorrectNess()
        
        if (shouldUpload){
            //Upload the event using required and optional fields
            
            let key = self.eventID
            
            //Check if event exists
            
            
            self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(self.eventID ?? "").observeSingleEvent(of: .value, with: {(snapshot) in
                
                let value = snapshot.value as? NSDictionary ?? [:]
                
                if (value != nil  && value != [:]){
                    
                    
                    
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("eventTitle").setValue(self.titleTextField.text!)
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("startDateAndTime").setValue(self.startDateAndTimeField.text!)
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("endDateAndTime").setValue(self.endDateAndTimeField.text!)
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("location").setValue(self.addressField.text!)
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("pictureURL").setValue(self.imageURLTextField.text!)
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("maxTickets").setValue(Int(self.maxTickets.text!) ?? nil)
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("dressCode").setValue(String(self.dressCodeTextField.text!) ?? nil)
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("totalVenueCapacity").setValue(Int(self.maxVenueCapacity.text!) ?? nil)
                    self.ref?.child("vendors").child(Auth.auth().currentUser?.uid ?? "").child("events").child(key ?? "").child("description").setValue(String(self.eventDescription.text!) ?? nil)
                    
                    var ticketDictionary: Dictionary = [:] as [String: Any]
                    
                    for t in self.ticketTypes {
                        ticketDictionary[t.name] = t.price
                    }
                    
                    let update2 =  ["/vendors/\(Auth.auth().currentUser!.uid)/events/\(key!)/ticketTypes/": ticketDictionary]
                    self.ref?.updateChildValues(update2)
                    
                    self.navigationController?.popViewController(animated: true)
                }
            })
            
            
            
        }
        
        
        
        
    }
    
    
}
