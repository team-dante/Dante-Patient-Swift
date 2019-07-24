//
//  beacons.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/18/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import KontaktSDK

class Beacons: NSObject {
    
    static let shared = Beacons()
    
    var beaconManager: KTKBeaconManager!
    var ref: DatabaseReference!
    var region: KTKBeaconRegion!
    var region1: KTKBeaconRegion!
    var region2: KTKBeaconRegion!
    
    // records a queue of 10 distances for each beacon
    var roomDict: [Int: [Double]] = [1: [], 2: [], 3:[]]
    // map beacon major to the real clinic room
    let majorToRoom = [ 1: "exam1", 2: "CTRoom", 3: "femaleWaitingRoom" ]
    // map beacon major to its corresponding cutoff value (1m)
    let cutoff = [1: 1.5, 2: 1.5, 3: 1.5]
    // after 10 rounds, perform stats analysis
    let threshold = 5
    
    var counter = 0
    
    var count = 0
    var prevRoom = ""
    var currRoom = ""
    var startTime = 0
    
    var dateToday: String!
    var userPhoneNum: String?
    
    func detectBeacons() {
        // get today's date and current user's phone number
        dateToday = self.formattedDate()
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        // initiate Database
        ref = Database.database().reference()
        
        // ---------------- set up kontakt beacons ------------------
        Kontakt.setAPIKey("IKLlxikqjxJwiXbyAgokGeLkcZqipAnc")
        // Initiate Beacon Manager
        beaconManager = KTKBeaconManager(delegate: self)
        beaconManager.requestLocationAlwaysAuthorization()
        
        // overall ranging region (more general, major not specified)
        region = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID,
                                     identifier: "region-identifer")
        
        // monitoring region 1 (major 1)
        region1 = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID,
                                      major: 1, identifier: "region-identifer")
        beaconManager.startMonitoring(for: region1)
        
        // monitoring region 2(major 2)
        region2 = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID,
                                      major: 2, identifier: "region-identifer")
        beaconManager.startMonitoring(for: region2)
        
        // range for the overall region
        beaconManager.startRangingBeacons(in: region)
        print("start ranging")
        // ----------- end of setting up kontakt beacons ----------------
    }
    
    // when the app is about to terminate; stop monitoring and ranging; set room to "Private"
    func stopRanging() {
        beaconManager.stopMonitoring(for: region1)
        beaconManager.stopMonitoring(for: region2)
        beaconManager.stopRangingBeacons(in: region)
        
        // set room to "Private" when patients close the app completely (slide up the app and throw it out)
        ref.child("/PatientLocation/\(userPhoneNum!)/room").setValue("Private")
    }
    
    // return today's date in YYYY-MM-DD format
    func formattedDate() -> String {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        let formattedMonth = month < 10 ? "0\(month)" : "\(month)"
        let formattedDay = day < 10 ? "0\(day)" : "\(day)"
        return "\(year)-\(formattedMonth)-\(formattedDay)"
    }
}

extension Beacons: KTKBeaconManagerDelegate {
    
    func beaconManager(_ manager: KTKBeaconManager, didRangeBeacons beacons: [CLBeacon], in region: KTKBeaconRegion) {
        
        // Debugging purposes
        for beacon in beacons {
            print(beacon.major, beacon.accuracy)
        }
        
        // wait a few rounds (5) to gather data to compute avg
        if (self.count < self.threshold) {
            self.count += 1
            
            for beacon in beacons {
                // if too far, assume 999m away
                if beacon.accuracy == -1 {
                    self.roomDict[Int(truncating: beacon.major)]?.append(999)
                } else {
                    self.roomDict[Int(truncating: beacon.major)]?.append(Double(beacon.accuracy))
                }
            }
        } else {
            for beacon in beacons {
                // queue system; dequeue iff array length >= threshold
                if self.roomDict[Int(truncating: beacon.major)]!.count >= threshold {
                    self.roomDict[Int(truncating: beacon.major)]?.remove(at: 0)
                }
                if beacon.accuracy == -1 {
                    self.roomDict[Int(truncating: beacon.major)]?.append(999)
                } else {
                    self.roomDict[Int(truncating: beacon.major)]?.append(Double(beacon.accuracy))
                }
            }
            // compute avg of the recent 5 results
            var avgList: [Int: Double] = [:]
            for beacon in beacons {
                let beaconArray = self.roomDict[Int(truncating: beacon.major)]
                if beaconArray!.count >= threshold {
                    let avg = Double(beaconArray!.reduce(0, +)) / Double(threshold)
                    avgList[Int(truncating: beacon.major)] = avg
                }
            }
            // sort beacons by avg; [Int:Double] -> [(key: ..., value:...)]
            let sortedBeaconArr = avgList.sorted(by: { $0.1 < $1.1})
            
            // if no beacons are detected or the distance of the nearest beacon is greater than the cutoff,
            //      set currRoom to Private
            if sortedBeaconArr.count != 0 {
                if sortedBeaconArr[0].value >= self.cutoff[sortedBeaconArr[0].key]! {
                    self.currRoom = "Private"
                } else {
                    self.currRoom = self.majorToRoom[sortedBeaconArr[0].key]!
                }
            } else {
                self.currRoom = "Private"
            }
            
            // get the room of the last round
            if let prevRoom = UserDefaults.standard.string(forKey: "currRoom") {
                self.prevRoom = prevRoom
            } else {
                self.prevRoom = "Private"
            }
            // then start time tracking
            DispatchQueue.main.async {
                self.startTimeTracking()
            }
        }
    }
    
    // ------------------------- Time Tracking Starts Here -----------------------------
    func startTimeTracking() {
        // if the prev room is "Private" but the current one isn't, update current room's start time
        if self.prevRoom == "Private" && self.currRoom != "Private" {
            // get the last non-private room
            let prev = UserDefaults.standard.string(forKey: "prevRoom")
            
            // ex: CTRoom -> Private -> CTRoom, keep updating CTRoom's clock (if Private more than 1 hr, start new clock)
            // ex: CTRoom -> Private -> exam1, start a new clock for exam1
            if prev == self.currRoom {
                let timeNow = Int(Date().timeIntervalSince1970)
                let startTime = UserDefaults.standard.integer(forKey: "startTime")
                if timeNow - startTime <= 3600 {
                    UserDefaults.standard.set(timeNow, forKey: "startTime")
                    // inefficient; update every sec
                    self.updateEndTime()
                } else {
                    self.createNewTimeClock()
                }
            } else {
                self.createNewTimeClock()
            }
            // set current room
            DispatchQueue.main.async {
                self.ref.child("/PatientLocation/" + self.userPhoneNum!).setValue(["room": self.currRoom])
                UserDefaults.standard.set(self.currRoom, forKey: "currRoom")
            }
        }
        // if the prev room isn't "Private" but the current one is, update end time and time spent for prev room;
        else if self.prevRoom != "Private" && self.currRoom == "Private" {
            self.updateEndTime()
            
            DispatchQueue.main.async {
                // update paitent's current location "Private" to database
                self.ref.child("/PatientLocation/" + self.userPhoneNum!).setValue(["room": self.currRoom])
                UserDefaults.standard.set(self.currRoom, forKey: "currRoom")
                print("setting rooms")
                
                // save the prev room first before going into Private
                UserDefaults.standard.set(self.prevRoom, forKey: "prevRoom")
            }
        }
        // if prev and curr rooms are not private
        // if prev and curr rooms are NOT the same, update endTime and timeElapsed for prev room
        // and create a new clock for the new room
        else if self.prevRoom != "Private" && self.currRoom != "Private" {
            if self.prevRoom != self.currRoom {
                self.updateEndTime()
                DispatchQueue.main.async {
                    self.createNewTimeClock()
                    // update paitent's current location to database
                    self.ref.child("/PatientLocation/" + self.userPhoneNum!).setValue(["room": self.currRoom])
                    UserDefaults.standard.set(self.currRoom, forKey: "currRoom")
                }
            } else {
                // inefficient; update every sec
                let timeNow = Int(Date().timeIntervalSince1970)
                let startTime = UserDefaults.standard.integer(forKey: "startTime")
                if timeNow - startTime >= 10800 {
                    self.createNewTimeClock()
                } else {
                    self.updateEndTime()
                }
            }
        }
    }
    
    // new clock: 1. push the curr time to Firebase; 2. set UserDefaults "startTime"; 3. save the current uid; 4. counter back to 0
    func createNewTimeClock() {
        let time = Int(Date().timeIntervalSince1970)
        
        let obj = ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(self.dateToday!)").childByAutoId()
        obj.setValue(["room": self.currRoom, "startTime": time, "endTime": 0, "timeElapsed": 0])
        UserDefaults.standard.set(obj.key, forKey: "currObj")
        UserDefaults.standard.set(time, forKey: "startTime")
        self.counter = 0
    }
    
    // update end time: 1. check if uid of the curr timeObj exists; 2. if yes, update endTime and timeElapsed to database;
    //      3. increment counter (aka timeElapsed)
    func updateEndTime() {
        let timeNow = Int(Date().timeIntervalSince1970)
        if let uid = UserDefaults.standard.string(forKey: "currObj") {
            let path = ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(self.dateToday!)/\(uid)")
            let start = UserDefaults.standard.integer(forKey: "startTime")
            path.child("endTime").setValue(timeNow)
            path.child("timeElapsed").setValue(Int(timeNow - start))
            self.counter = Int(timeNow - start)
        }
    }
    
    // ------------------------------- Monitoring ------------------------------------
    func beaconManager(_ manager: KTKBeaconManager, didEnter region: KTKBeaconRegion) {
        print("Enter region \(region)")
    }
    
    func beaconManager(_ manager: KTKBeaconManager, didExitRegion region: KTKBeaconRegion) {
        print("Exit region \(region)")
    }
}

