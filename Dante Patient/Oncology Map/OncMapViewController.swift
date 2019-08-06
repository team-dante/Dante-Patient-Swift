//
//  ViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/1/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FloatingPanel

class OncMapViewController: UIViewController, UIScrollViewDelegate, FloatingPanelControllerDelegate {
    
    var fpc: FloatingPanelController!
    var pinRef: PinRefViewController!
    var ref: DatabaseReference!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapUIView: UIView!
    @IBOutlet weak var mapImageView: UIImageView!
    @IBOutlet weak var queueNum: UILabel!
    
    var docDict: [String: UIImageView] = [:]
    var mapDict: [String: [(Int, Int)]] = [
        "femaleWaitingRoom": [(159, 163),(175, 170),(166, 160),(180, 169), (157, 183), (171, 182), (182, 184)],
        "CTRoom": [(20, 312),(47, 312), (57, 253), (44, 253), (10, 266), (28, 266), (50, 282)],
        "exam1": [(225, 241),(242, 241),(232, 242),(226, 263),(243, 263),(231, 264), (237, 250)]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // connecting to Firebase initially
        ref = Database.database().reference()
        
        // Singleton Beacon class
        Beacons.shared.detectBeacons()

        // --------------- settting up FloatingPanel ------------------
        // init FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self
        
        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = .clear
        if #available(iOS 11, *) {
            fpc.surfaceView.cornerRadius = 9.0
        } else {
            fpc.surfaceView.cornerRadius = 0.0
        }
        fpc.surfaceView.shadowHidden = false
        
        pinRef = storyboard?.instantiateViewController(withIdentifier: "PinRef") as? PinRefViewController
        
        // insert ViewController into FloatingPanel
        fpc.set(contentViewController: pinRef)
        fpc.track(scrollView: pinRef.tableView)
        
        // tap on surface to trigger events
        let surfaceTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSurface(tapGesture:)))
        fpc.surfaceView.addGestureRecognizer(surfaceTapGesture)
        
        // tap on backdrop to trigger events
        let backdropTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackdrop(tapGesture:)))
        fpc.backdropView.addGestureRecognizer(backdropTapGesture)
        
        // --------------- Done setting up FloatingPanel ------------------

        // zoom in
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 4.0
        
        // stylings for queueNum label
        queueNum.layer.cornerRadius = 15
        queueNum.backgroundColor = UIColor("#fff")
        queueNum.textColor = UIColor("#62B245")
        queueNum.layer.masksToBounds = true
        
        // Assume we have a set number of doctors for now (would make the pin coloring scheme dynamic in future)
        for i in 1...7 {
            let pin = i * 111;
            docDict[String(pin)] = UIImageView(image: UIImage(named: String(pin)))
        }
    }
    
    // if FloatingPanel's position is at tip, then it will be at half
    @objc func handleSurface(tapGesture: UITapGestureRecognizer) {
        if fpc.position == .tip {
            fpc.move(to: .half, animated: true)
        }
    }
    
    // tap on backdrop will move down the FloatingPanel
    @objc func handleBackdrop(tapGesture: UITapGestureRecognizer) {
        fpc.move(to: .tip, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //  Add FloatingPanel to a view with animation.
        fpc.addPanel(toParent: self, animated: true)
        
        // call observe to always listen for event changes
        ref.child("DoctorLocation").observe(.value, with: {(snapshot) in
            if let doctors = snapshot.value as? [String: Any] {
                for doctor in doctors {
                    let key = doctor.key
                    // get doctor's value e.g. {"room": "CTRoom"}
                    if let doc = doctor.value as? [String: String] {
                        let room = doc["room"]! // e.g. "CTRoom"

                        if room == "Private" { // private room -> don't show pins
                            self.docDict[key]!.isHidden = true
                        }
                        else {
                            self.docDict[key]!.isHidden = false

                            // add the assigned doctor pin onto the image; re-render when event changes
                            self.updateDocLoc(doctor: self.docDict[key]!, x: self.mapDict[room]![0].0, y: self.mapDict[room]![0].1)

                            let firstElement = self.mapDict[room]!.remove(at: 0)
                            self.mapDict[room]!.append(firstElement)
                        }
                    }
                }
            }
        })
    }
    
    // delegate method to help zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.mapUIView
    }
    
    // center scrollView when zooming
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let subview = scrollView.subviews[0]
        let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width)*0.5, 0.0)
        let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height)*0.5, 0.0)
        subview.center = CGPoint(x: scrollView.contentSize.width*0.5 + offsetX, y: scrollView.contentSize.height*0.5 + offsetY)
    }
    
    // utilize offsets; add doc pin(UIImage) to UIView
    func updateDocLoc(doctor: UIImageView, x: Int, y: Int) {
        doctor.frame = CGRect(x: x, y: y, width: 10, height: 21)
        self.mapUIView.addSubview(doctor)
    }
    
    // change the default floatingPanel layout
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return MyFloatingPanelLayout()
    }
}

class MyFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 120.0 // A top inset from safe area
        case .half: return 250.0 // A bottom inset from the safe area
        case .tip: return 150.0 // A bottom inset from the safe area
        default: return nil // Or `case .hidden: return nil`
        }
    }
}

