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

struct RoomCoords {
    var tl: (Double, Double)
    var tr: (Double, Double)
    var br: (Double, Double)
    var bl: (Double, Double)
}

struct StaffPrevLoc {
    var room: String
    var pos: (Double, Double)
}

class OncMapViewController: UIViewController, UIScrollViewDelegate, FloatingPanelControllerDelegate {
    
    var fpc: FloatingPanelController!
    var pinRef: PinRefViewController!
    var ref: DatabaseReference!
    
    var allLayers = [String:[CAShapeLayer]]()
    
    var showDetails = false
    var selectedRoom = ""
    var roomBtns = [UIButton]()
    
    let PIN_WIDTH_PROP: Double = 10/375.0
    let PIN_HEIGHT_PROP: Double = 23/450.0
    
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapUIView: UIView!
    @IBOutlet weak var mapImageView: UIImageView!
    @IBOutlet weak var queueNum: UILabel!
    @IBOutlet weak var detailBarItem: UIBarButtonItem!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    
    // record the previous room & coordinates that the staff is located
    var prevLoc = [String:StaffPrevLoc]()
    
    let roomCoords: [String: RoomCoords] = [
        "LA1": RoomCoords(tl: (0.345, 0.676), tr: (0.508, 0.676), br: (0.508, 1.0), bl: (0.345, 1.0)),
        "TLA": RoomCoords(tl: (0.825, 0.342), tr: (1, 0.342), br: (1, 0.72), bl: (0.825, 0.72)),
        "CT": RoomCoords(tl: (0.0, 0.725), tr: (0.176, 0.725), br: (0.176, 0.928), bl: (0.0, 0.928)),
        "WR": RoomCoords(tl: (0.269, 0.437), tr: (0.359, 0.437), br: (0.359, 0.545), bl: (0.269, 0.545))
    ]
    
//    let trackedStaff: Set<String> = ["111", "222", "333", "444", "555"]
//    var mapDict: [String: [(Double, Double)]] = [
//        "LA1": [(0.38, 0.7), (0.41, 0.75), (0.46, 0.75), (0.48, 0.7), (0.39, 0.8)],
//        "TLA": [(0.9, 0.36), (0.95, 0.5), (0.83, 0.54), (0.8, 0.5), (0.86, 0.4)],
//        "CT": [(0.0, 0.7), (0.03, 0.75), (0.12, 0.75), (0.06, 0.7), (0.04, 0.8)],
//        "WR": [(0.27, 0.41), (0.3, 0.41), (0.27, 0.47), (0.31, 0.47), (0.33, 0.45)]
//    ]
    
    // configure clickable buttons; (x, y, width, height)
    let clickableRooms: [String: (Double, Double, Double, Double)] = [
        "TLA": (0.794, 0.342, 0.205, 0.378),
        "LA1": (0.345, 0.628, 0.163, 0.372),
        "CT": (0.0, 0.628, 0.179, 0.302)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // connecting to Firebase initially
        ref = Database.database().reference()

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
        
        // configure bottom view height
        let height = UIScreen.main.bounds.height
        if height >= 896 {
            bottomViewHeight.constant = 150
        } else if height >= 812 {
            bottomViewHeight.constant = 110
        } else {
            bottomViewHeight.constant = 90
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // call observe to always listen for event changes
        ref.child("StaffLocation").observe(.value, with: {(snapshot) in
            if let doctors = snapshot.value as? [String: Any] {
                for doctor in doctors {
                    let key = doctor.key
//                    if self.trackedStaff.contains(key) {
                        // get doctor's value e.g. {"room": "CTRoom"}
                        if let doc = doctor.value as? [String: String] {
                            let room = doc["room"]! // e.g. "CTRoom"
                            if room != "Private" {
                                let color = doc["pinColor"]!
                                
                                // remember the prev room a staff has visited
                                let prevRoom = self.prevLoc[key]?.room ?? ""
                                if room != prevRoom {
                                    // remove the old pin before drawing the new pin
                                    self.removePin(key: key)
                                    
                                    // lowerX: topLeft corner x; upperX: topRight corner x; lowerY: topRight corner y; upperY: bottomRight corner y
                                    // random can only be ints; first scale up the coords by 1000; after receiving random numbers, scale down by 1000
                                    let lowerX = Int(self.roomCoords[room]!.tl.0 * 1000)
                                    let upperX = Int((self.roomCoords[room]!.tr.0 - self.PIN_WIDTH_PROP) * 1000)
                                    let lowerY = Int((self.roomCoords[room]!.tr.1 - self.PIN_WIDTH_PROP) * 1000)
                                    let upperY = Int((self.roomCoords[room]!.br.1 - self.PIN_HEIGHT_PROP) * 1000)
                                    
                                    var rand_x: Double
                                    var rand_y: Double
                                    
                                    // repeat while there is a pin-overlap; check if two circles overlap
                                    repeat {
                                        // generate (x,y)
                                        rand_x = Double(Int.random(in: lowerX..<upperX)) / 1000.0
                                        rand_y = Double(Int.random(in: lowerY..<upperY)) / 1000.0
              
                                    } while (self.pinOverlap(room: room, pos_X: rand_x, pos_Y: rand_y))
                                    
                                    self.prevLoc[key] = StaffPrevLoc(room: room, pos: (rand_x, rand_y))
                                    
                                    // drawing the staff to the newest location
                                    self.updateDocLoc(doctor: key, color: color, x: rand_x, y: rand_y)
                                }
                            } else {
                                // remove the old pin before being "invisible"
                                self.removePin(key: key)
                                
                                // reset prev location to default values
                                self.prevLoc[key] = StaffPrevLoc(room: "Private", pos: (-1.0, -1.0))
                            }
                        }
                    }
//                }
            }
        })
    }
    
    // delegate method to help zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.mapUIView
    }
    
    // check if pins overlap each other (if circles overlap; don't care about the rect stand)
    func pinOverlap(room: String, pos_X: Double, pos_Y: Double) -> Bool {
        for (_, v) in self.prevLoc {
            if v.room == room && abs(v.pos.0 - pos_X) < PIN_WIDTH_PROP && abs(v.pos.1 - pos_Y) < PIN_WIDTH_PROP {
                return true
            }
        }
        return false
    }
    
    // remove staff's pin
    func removePin(key: String) {
        // allLayers serve to record all pin layers
        if let val = self.allLayers[key] {
            // remove pin (circle + rect); remove from array
            val.forEach({ $0.removeFromSuperlayer() })
            self.allLayers.removeValue(forKey: key)
        }
    }
    
    // utilize offsets; add doc pin(UIImage) to UIView
    func updateDocLoc(doctor: String, color: String, x: Double, y: Double) {
        // parse color
        let rgb = color.split(separator: "-")
        let r = CGFloat(Int(rgb[0])!)
        let g = CGFloat(Int(rgb[1])!)
        let b = CGFloat(Int(rgb[2])!)
        
        // coords.0: x in pixels; coords.1: y in pixels; coords.2: width; coords.3: total height of pin shape
        let coords = self.pinCoords(propX: x, propY: y, propW: PIN_WIDTH_PROP, propH: PIN_HEIGHT_PROP)
        
        // circle: same width and height
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: CGRect(x: coords.0, y: coords.1, width: coords.2, height: coords.2)).cgPath
        circleLayer.fillColor = UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1.0).cgColor
        circleLayer.strokeColor = UIColor.black.cgColor
        // high z-index for the circle
        circleLayer.zPosition = 1000
        
        // pin stand: right under the circle, has width of 4, height = total height - circle height
        let rectLayer = CAShapeLayer()
        rectLayer.path = UIBezierPath(rect: CGRect(x: coords.0 + coords.2 / 2.0 - 1.0, y: coords.1 + coords.2, width: 2, height: coords.3 - coords.2)).cgPath
        rectLayer.fillColor = UIColor.black.cgColor
        // low z-index for the stand
        rectLayer.zPosition = 1
        
        self.mapUIView.layer.addSublayer(circleLayer)
        self.mapUIView.layer.addSublayer(rectLayer)
        
        self.allLayers[doctor] = [circleLayer, rectLayer]
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
    
    
    @IBAction func onShowRoomDetails(_ sender: Any) {
        self.showDetails = !self.showDetails
        self.detailBarItem.title = self.showDetails ? "Done" : "Details"

        if self.showDetails {
            // set room buttons' positions
            for (k, v) in self.clickableRooms {
                let (x, y, w, h) = self.pinCoords(propX: v.0, propY: v.1, propW: v.2, propH: v.3)
                let btn = UIButton(frame: CGRect(x: x, y: y, width: w, height: h))
                btn.accessibilityIdentifier = k
                btn.setImage(UIImage(named: "info_disclosure"), for: .normal)
                btn.addTarget(self, action: #selector(didClick), for: .touchUpInside)
                self.customizeRoomButtons(btn: btn)
                
                self.roomBtns.append(btn)
                self.mapUIView.addSubview(btn)
            }
        } else {
            for btn in self.roomBtns {
                btn.removeFromSuperview()
            }
            self.roomBtns.removeAll()
        }
    }
    
    @objc func didClick(_ sender: UIButton) {
        let roomId = sender.accessibilityIdentifier
        self.selectedRoom = roomId!
        self.performSegue(withIdentifier: "RoomDetailsSegue", sender: nil)
    }
    
    func customizeRoomButtons(btn: UIButton) {
        btn.backgroundColor = UIColor("#31c1ff").withAlphaComponent(0.6)
        btn.layer.borderColor = UIColor("#31B464").cgColor
        btn.layer.borderWidth = 2
        btn.layer.zPosition = 2000
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        ref.removeAllObservers()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailsVC = segue.destination as? RoomDetailsViewController {
            detailsVC.roomStr = self.selectedRoom
        }
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
        case .tip:// A bottom inset from the safe area
            let height = UIScreen.main.bounds.height
            if height >= 896 {
                return 145
            } else if height >= 812 {
                return 106
            } else {
                return 87
            }
        default: return nil // Or `case .hidden: return nil`
        }
    }
}

