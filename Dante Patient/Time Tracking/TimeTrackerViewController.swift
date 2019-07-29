//
//  TimeTrackerViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/23/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class TimeTrackerViewController: UIViewController {
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var clockLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    
    var timer: Timer?
    var progressTimer: Timer?
    let shapeLayer = CAShapeLayer()
    var currRoom = "Private"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        roomLabel.text = "Detecting Beacons..."
        clockLabel.text = "00:00"
        startTimeLabel.text = ""
        
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
        
        timer = Timer.scheduledTimer(timeInterval:1, target:self, selector:#selector(processTimer), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        currRoom = Beacons.shared.currRoom
        if currRoom == "Private" || currRoom == "" {
            self.roomLabel.text = "Detecting Beacons..."
            self.clockLabel.text = "00:00"
            self.startTimeLabel.text = ""
        } else {
            self.roomLabel.text = self.prettifyRoom(room: currRoom)
            
            let counter = Beacons.shared.counter
            processStroke(elapsed: counter)

            self.clockLabel.text = "\(self.parseTimeElapsed(timeElapsed: counter))"
            
            let start = UserDefaults.standard.integer(forKey: "startTime")
            self.startTimeLabel.text = "Start: \(self.parseStartTime(startTime: start))"
        }
    }
}
