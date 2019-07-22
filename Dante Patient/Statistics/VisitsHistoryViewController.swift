//
//  VisitsHistoryViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/21/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

struct Visit {
    var room: String!
    var startTime: Int!
    var timeElapsed: Int!
}

class VisitsHistoryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    
//    let dates = ["2019-07-18", "2019-07-19", "2019-07-20", "2019-07-21", "2019-07-22", "2019-07-23","2019-07-24", "2019-07-25", "2019-07-26", "2019-07-27", "2019-07-28"]
    
    @IBOutlet weak var yearView: UIView!
    var dates = [String]()
    var selectedDate: String!
    var selectedDateVisit = [Visit]()
    var userPhoneNum: String?
    let bottom = CALayer()
    var ref: DatabaseReference!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // collection view set up; no cell spacing in between
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        self.drawCollectionViewBorder()
        
        // tableView set up; no selection on cells
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        
        // get user phone number (aka. username)
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        // init Firebase
        ref = Database.database().reference()
        
        // get date keys (in format "YYY-MM-DD") from Firebase /PatientVisitsByDates/123
        // starting 2019-07-18 since data prev dates do not adhere to the current format
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)").queryStarting(atValue: nil, childKey: "2019-07-18").observeSingleEvent(of: .value, with: { (snapshot) in
            if let dateObjs = snapshot.value as? [String: Any] {
                for dateObj in dateObjs {
                    self.dates.append(dateObj.key)
                }
                self.dates.sort(by: {$0 < $1})
                self.collectionView.reloadData()
                
                // make sure reload data is done before auto selecting the last day in the date list
                DispatchQueue.main.async {
                    self.collectionView.delegate?.collectionView!(self.collectionView, didSelectItemAt: IndexPath(item: self.dates.count-1, section: 0))
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    func drawCollectionViewBorder() {
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0.0, y: collectionView.frame.height-2,
                                    width: collectionView.frame.width, height: 1.0)
        bottomBorder.backgroundColor = UIColor("#B8C9D2").cgColor
        collectionView.layer.addSublayer(bottomBorder)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(section)
        return dates.count
    }
    
    // parse "YYYY-MM-DD" to day, weekday, and month
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCollectionViewCell", for: indexPath) as! DateCollectionViewCell
        
        let date = dates[indexPath.item]
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "yyyy-MM-dd"
        let parsedDate1 = dateFormatter1.date(from: date)
        let f = DateFormatter()
        
        cell.monthLabel.text = f.monthSymbols[Calendar.current.component(.month, from: parsedDate1!)-1].prefix(3).uppercased()
        cell.weekdayLabel.text = f.weekdaySymbols[Calendar.current.component(.weekday, from: parsedDate1!)-1].prefix(3).uppercased()
        cell.dayLabel.text = String(date.split(separator: "-")[2])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // when tapped on a collectionView cell, the tapped cell will be auto centered
        collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        
        // add thick border to the selected cell
        if let cell = collectionView.cellForItem(at: indexPath) {
            bottom.frame = CGRect(x: 0.0, y: (cell.frame.height) - 4, width: (cell.frame.width), height: 4.0)
            bottom.backgroundColor = UIColor("#5C7B8C").cgColor
            cell.layer.addSublayer(bottom)
        }
        
        // get the selected date
        self.selectedDate = dates[indexPath.item]
        
        // get room, startTime, and timeElapsed for each time tracking slot and append them to a list of struct Visit(room, startTime, timeElapsed)
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(self.selectedDate!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if let timeObjs = snapshot.value as? [String: Any] {
                self.selectedDateVisit = []
                for timeObj in timeObjs {
                    if let obj = timeObj.value as? [String: Any] {
                        let room = obj["room"] as? String
                        let startTime = obj["startTime"] as? Int
                        let timeElapsed = obj["timeElapsed"] as? Int
                        self.selectedDateVisit.append(Visit(room: room!, startTime: startTime!, timeElapsed: timeElapsed!))
                    }
                }
                self.selectedDateVisit.sort(by: {$0.startTime > $1.startTime})
                self.tableView.reloadData()
            }
        })
    }
    
    // when deselecting a cell, remove thick border, clear selectedDateVisit
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        bottom.removeFromSuperlayer()
        self.selectedDateVisit = []
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedDateVisit.count
    }
    
    // decompose the selectedDateVisit
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let room = self.selectedDateVisit[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "VisitHistoryTableViewCell", for: indexPath) as! VisitHistoryTableViewCell
        
        cell.roomLabel.text = self.prettifyRoom(room: room.room)
        cell.timeElapsedLabel.text = "\(self.parseTimeElapsed(timeElapsed: room.timeElapsed!))"
        cell.startTimeLabel.text = "Start: \(self.parseStartTime(startTime: room.startTime!))"
        
        return cell
    }
}
