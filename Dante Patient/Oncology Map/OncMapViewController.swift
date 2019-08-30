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
    var showDetails = false
    var CTBtn: UIButton!
    var TLABtn: UIButton!
    
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapUIView: UIView!
    @IBOutlet weak var mapImageView: UIImageView!
    @IBOutlet weak var queueNum: UILabel!
    @IBOutlet weak var detailBarItem: UIBarButtonItem!
    
    let trackedStaff: Set<String> = ["111", "222", "333", "444", "555"]
    var docDict: [String: UIImageView] = [:]
    var mapDict: [String: [(Double, Double)]] = [
        "LA1": [(0.38, 0.7), (0.41, 0.75), (0.46, 0.75), (0.48, 0.7), (0.39, 0.8)],
        "TLA": [(0.9, 0.36), (0.95, 0.5), (0.83, 0.54), (0.8, 0.5), (0.86, 0.4)],
        "CT": [(0.0, 0.7), (0.03, 0.75), (0.12, 0.75), (0.06, 0.7), (0.04, 0.8)],
        "WR": [(0.27, 0.41), (0.3, 0.41), (0.27, 0.47), (0.31, 0.47), (0.33, 0.45)]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // connecting to Firebase initially
        ref = Database.database().reference()
        
        // Singleton Beacon class
//        Beacons.shared.detectBeacons()

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
        
        //  Add FloatingPanel to a view with animation.
        fpc.addPanel(toParent: self, animated: true)
        
        // --------------- Done setting up FloatingPanel ------------------

        // zoom in
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 4.0
        
        // stylings for queueNum label
        queueNum.layer.cornerRadius = queueNum.frame.height/3
        queueNum.backgroundColor = UIColor("#fff")
        queueNum.textColor = UIColor("#62B245")
        queueNum.layer.masksToBounds = true
        
        // Assume we have a set number of doctors for now (would make the pin coloring scheme dynamic in future)
        for i in 1...7 {
            let pin = i * 111;
            docDict[String(pin)] = UIImageView(image: UIImage(named: String(pin)))
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // set room buttons' positions
        let (x1, y1, w1, h1) = self.pinCoords(propX: 0.0, propY: 0.629, propW: 0.178, propH: 0.303)
        CTBtn = UIButton(frame: CGRect(x: x1, y: y1, width: w1, height: h1))
        self.addRoomBtn(btn: CTBtn)
        
        let (x2, y2, w2, h2) = self.pinCoords(propX: 0.794, propY: 0.3418, propW: 0.2045, propH: 0.3786)
        TLABtn = UIButton(frame: CGRect(x: x2, y: y2, width: w2, height: h2))
        self.addRoomBtn(btn: TLABtn)
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

        // call observe to always listen for event changes
        ref.child("StaffLocation").observe(.value, with: {(snapshot) in
            var mapDictCopy = self.mapDict
            if let doctors = snapshot.value as? [String: Any] {
                for doctor in doctors {
                    let key = doctor.key
                    if self.trackedStaff.contains(key) {
                        // get doctor's value e.g. {"room": "CTRoom"}
                        if let doc = doctor.value as? [String: String] {
                            let room = doc["room"]! // e.g. "CTRoom"

                            if room == "Private" { // private room -> don't show pins
                                self.docDict[key]!.isHidden = true
                            }
                            else {
                                self.docDict[key]!.isHidden = false

                                // add the assigned doctor pin onto the image; re-render when event changes
                                self.updateDocLoc(doctor: self.docDict[key]!, x: mapDictCopy[room]![0].0, y: mapDictCopy[room]![0].1)

                                let firstElement = mapDictCopy[room]!.remove(at: 0)
                                mapDictCopy[room]!.append(firstElement)
                            }
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
    
    // utilize offsets; add doc pin(UIImage) to UIView
    func updateDocLoc(doctor: UIImageView, x: Double, y: Double) {
        let coords = self.pinCoords(propX: x, propY: y, propW: 10/375.0, propH: 21/450.0)
        doctor.frame = CGRect(x: coords.0, y: coords.1, width: coords.2, height: coords.3)
        self.mapUIView.addSubview(doctor)
    }
    
    // change the default floatingPanel layout
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return MyFloatingPanelLayout()
    }
    
    func pinCoords(propX: Double, propY: Double, propW: Double, propH: Double) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var x: CGFloat = 0.0
        var y: CGFloat = 0.0
        var w: CGFloat = 0.0
        var h: CGFloat = 0.0
        
        let deviceWidth = self.view.frame.width
        let deviceHeight = self.middleView.frame.height

        let propHeight = deviceWidth / 0.8333

        if propHeight < deviceHeight {
            let yAxisOffset = (deviceHeight - propHeight)/CGFloat(2.0)
            x = deviceWidth * CGFloat(propX)
            y = propHeight * CGFloat(propY) + yAxisOffset
            w = deviceWidth * CGFloat(propW)
            h = propHeight * CGFloat(propH)
        } else {
            let propWidth = deviceHeight * CGFloat(0.8333)
            let xAxisOffset = (deviceWidth - propWidth)/CGFloat(2.0)
            x = propWidth * CGFloat(propX) + xAxisOffset
            y = deviceHeight * CGFloat(propY)
            w = propWidth * CGFloat(propW)
            h = deviceHeight * CGFloat(propH)
        }
        return (x, y, w, h)
    }
    
    func addRoomBtn(btn: UIButton) {
        btn.backgroundColor = UIColor("#00C213").withAlphaComponent(0.55)
        btn.layer.borderColor = UIColor("#BBA012").cgColor
        btn.layer.borderWidth = 1.5
        mapUIView.addSubview(btn)
        btn.isHidden = true
    }
    
    @IBAction func onShowRoomDetails(_ sender: Any) {
        self.showDetails = !self.showDetails
        self.detailBarItem.title = self.showDetails ? "Done" : "Details"
        self.CTBtn.isHidden = !self.CTBtn.isHidden
        self.TLABtn.isHidden = !self.TLABtn.isHidden
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        ref.removeAllObservers()
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
        case .tip: return 90.0 // A bottom inset from the safe area
        default: return nil // Or `case .hidden: return nil`
        }
    }
}

