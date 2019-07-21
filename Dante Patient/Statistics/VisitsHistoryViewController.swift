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
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        ref = Database.database().reference()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.dates = []
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)").queryStarting(atValue: nil, childKey: "2019-07-18").observeSingleEvent(of: .value, with: { (snapshot) in
            if let dateObjs = snapshot.value as? [String: Any] {
                for dateObj in dateObjs {
                    self.dates.append(dateObj.key)
                }
                self.dates.sort(by: {$0 < $1})
                self.collectionView.reloadData()
            }
//            self.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        })

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(section)
        return dates.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCollectionViewCell", for: indexPath) as! DateCollectionViewCell
        
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0.0, y: cell.frame.height - 1, width: cell.frame.width, height: 1.0)
        bottomBorder.backgroundColor = UIColor.lightGray.cgColor
        cell.layer.addSublayer(bottomBorder)
        
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
        collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        let cell = collectionView.cellForItem(at: indexPath)
        
        bottom.frame = CGRect(x: 0.0, y: (cell?.frame.height)! - 4, width: (cell?.frame.width)!, height: 4.0)
        bottom.backgroundColor = UIColor.darkGray.cgColor
        cell?.layer.addSublayer(bottom)
        
        self.selectedDate = dates[indexPath.item]
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(self.selectedDate!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if let timeObjs = snapshot.value as? [String: Any] {
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
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        bottom.removeFromSuperlayer()
        self.selectedDateVisit = []
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedDateVisit.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let room = self.selectedDateVisit[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "VisitHistoryTableViewCell", for: indexPath) as! VisitHistoryTableViewCell
        
        cell.roomLabel.text = self.prettifyRoom(room: room.room)
        cell.timeElapsedLabel.text = "\(self.parseTimeElapsed(timeElapsed: room.timeElapsed!))"
        cell.startTimeLabel.text = "Start: \(self.parseStartTime(startTime: room.startTime!))"
        
        return cell
    }
}
