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
    @IBOutlet weak var dateUILabel: UILabel!
    var dates = [String]()
    var selectedDate: String!
    var selectedDateVisit = [Visit]()
    var userPhoneNum: String?
    let bottom = CALayer()
    var indexPath: IndexPath?
    var ref: DatabaseReference!
    var layout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // collection view set up; no cell spacing in between
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        
        layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData { (success) -> Void in
            if success {
                self.processData()
            }
        }
    }
    
    func loadData(completion: @escaping (_ success: Bool) -> Void) {
        // get date keys (in format "YYY-MM-DD") from Firebase /PatientVisitsByDates/123
        // starting 2019-07-18 since data prev dates do not adhere to the current format
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)").queryStarting(atValue: nil, childKey: "2019-07-18").observeSingleEvent(of: .value, with: { (snapshot) in
            self.dates.removeAll()
            if let dateObjs = snapshot.value as? [String: Any] {
                for dateObj in dateObjs {
                    self.dates.append(dateObj.key)
                }
                self.dates.sort(by: {$0 < $1})
                self.collectionView.reloadData()
                completion(true)
            }
        })
    }
    
    // pre-select the last visited cell if indexPath exists; otherwise select today
    func processData() {
        if let indexPath = self.indexPath {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.collectionView(self.collectionView, didSelectItemAt: indexPath)
            }
        } else {
            let index = IndexPath(item: self.dates.count-1, section: 0)
            self.collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView(self.collectionView, didSelectItemAt: index)
            }
        }
    }
    
    func drawCollectionViewBorder() {
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0.0, y: 0.0,
                                    width: tableView.frame.width-1, height: 1.0)
        topBorder.backgroundColor = UIColor("#B8C9D2").cgColor
        tableView.layer.addSublayer(topBorder)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        cell.dayLabel.text = String(date.split(separator: "-")[2])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // when tapped on a collectionView cell, the tapped cell will be auto centered
        collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        
        self.indexPath = indexPath
        
        // add thick bottom border to the selected cell
        if let cell = collectionView.cellForItem(at: indexPath) {
            print("exectued")
            bottom.frame = CGRect(x: 0.0, y: (cell.frame.height) - 3.6, width: (cell.frame.width), height: 3.6)
            bottom.backgroundColor = UIColor("#5C7B8C").cgColor
            cell.layer.addSublayer(bottom)
        }
        
        // get the selected date
        self.selectedDate = dates[indexPath.item]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let parsedDate = dateFormatter.date(from: self.selectedDate)
        
        // set the date string for the UIView at the top
        let f = DateFormatter()
        let month = f.monthSymbols[Calendar.current.component(.month, from: parsedDate!)-1].prefix(3)
        let day = String(self.selectedDate.split(separator: "-")[2])
        let year = String(self.selectedDate.split(separator: "-")[0])
        let weekday = f.weekdaySymbols[Calendar.current.component(.weekday, from: parsedDate!)-1]
        self.dateUILabel.text = "\(weekday), \(month) \(day), \(year)"

        // get room, startTime, and timeElapsed for each time tracking slot and append them to a list of struct Visit(room, startTime, timeElapsed); else get empty list
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(self.selectedDate!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if let timeObjs = snapshot.value as? [String: Any] {
                self.selectedDateVisit.removeAll()
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
            } else {
                self.selectedDateVisit.removeAll()
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.bottom.removeFromSuperlayer()
    }
    
    // when deselecting a cell, remove thick border, clear selectedDateVisit
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.bottom.removeFromSuperlayer()
        self.selectedDateVisit.removeAll()
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
