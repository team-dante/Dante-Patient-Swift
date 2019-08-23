//
//  TimeTrackerViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/23/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class TimeTrackerViewController: UIViewController {
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var clockLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    
    var ref: DatabaseReference!
    var timer: Timer?
    let shapeLayer = CAShapeLayer()
    
    var counter = 0
    var userPhoneNum: String?
    var today: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        roomLabel.text = "Private"
        clockLabel.text = "00:00"
        startTimeLabel.text = ""
        
        ref = Database.database().reference()
        
        today = self.formattedDate()
        
        let center = view.center
        
        let trackLayer = CAShapeLayer()
        
        let circularPath = UIBezierPath(arcCenter: center, radius: 140, startAngle: CGFloat(-0.5 * .pi), endAngle: CGFloat(1.5 * .pi), clockwise: true)
        trackLayer.path = circularPath.cgPath
        
        trackLayer.strokeColor = UIColor("#31c1ff").cgColor
        trackLayer.lineWidth = 10
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round
        view.layer.addSublayer(trackLayer)
    
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = UIColor("#F3846B").cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        
        shapeLayer.strokeEnd = 0
        
        view.layer.addSublayer(shapeLayer)
        
        self.roomLabel.text = "Private"
        self.clockLabel.text = "00:00"
        self.startTimeLabel.text = ""
        
        timer = Timer.scheduledTimer(timeInterval:1.0, target:self, selector:#selector(processTimer), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
    }
    
    func processStroke(elapsed: Int) {
        let hour = 3600.0
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        let prevTime = Double(elapsed).remainder(dividingBy: hour) / hour
        basicAnimation.fromValue = prevTime
        
        let incTime = (Double(elapsed) + 1.0).remainder(dividingBy: hour) / hour
        basicAnimation.toValue = incTime
        
        basicAnimation.duration = 1
        basicAnimation.fillMode = .forwards
        basicAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        basicAnimation.isRemovedOnCompletion = true
        basicAnimation.repeatCount = .greatestFiniteMagnitude
        
        shapeLayer.add(basicAnimation, forKey: "progress-bar")
    }
    
    @objc func processTimer() {
    ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(today!)").queryOrdered(byChild: "inSession").queryEqual(toValue: true).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                if let timeObj = snapshot.value as? [String:Any] {
                    for object in timeObj {
                        if let obj = object.value as? [String: Any]{
                            
                            let room = obj["room"] as! String
                            let startTime = obj["startTime"] as! Int
                            let now = Int(NSDate().timeIntervalSince1970)
                            self.counter = now - startTime
                            self.processStroke(elapsed: self.counter)
                            self.roomLabel.text = self.prettifyRoom(room: room)
                            self.clockLabel.text = "\(self.parseTimeElapsed(timeElapsed: self.counter))"
                            self.startTimeLabel.text = "Start: \(self.parseStartTime(startTime: startTime))"
                        }
                    }
                }
            } else {
                self.roomLabel.text = "Private"
                self.clockLabel.text = "00:00"
                self.startTimeLabel.text = ""
                self.processStroke(elapsed: 0)
            }
        })
    }
}
