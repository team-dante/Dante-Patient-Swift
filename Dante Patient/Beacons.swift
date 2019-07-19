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
    
    // records a queue of 10 distances for each beacon
    var roomDict: [Int: [Double]] = [1: [], 2: [], 3:[]]
    // map beacon major to the real clinic room
    let majorToRoom = [ 1: "exam1", 2: "CTRoom", 3: "femaleWaitingRoom" ]
    // map beacon major to its corresponding cutoff value (1m)
    let cutoff = [1: 1.5, 2: 1.5, 3: 1.5]
    // after 10 rounds, perform stats analysis
    let threshold = 5
    
    var count = 0
    var currRoom = ""
    
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
        let region = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID,
                                     identifier: "region-identifer")
        
        // monitoring region 1 (major 1)
        let region1 = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID,
                                      major: 1, identifier: "region-identifer")
        region1.notifyEntryStateOnDisplay = true
        beaconManager.startMonitoring(for: region1)
        
        // monitoring region 2(major 2)
        let region2 = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID,
                                      major: 2, identifier: "region-identifer")
        region1.notifyEntryStateOnDisplay = true
        beaconManager.startMonitoring(for: region2)
        
        // range for the overall region
        beaconManager.startRangingBeacons(in: region)
        // ----------- end of setting up kontakt beacons ----------------
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
        
//        // Debugging purposes
//        for beacon in beacons {
//            print(beacon.major, beacon.accuracy)
//        }
        
        // wait a few rounds to gather data to compute avg
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
                // queue system; FIFO
                self.roomDict[Int(truncating: beacon.major)]?.remove(at: 0)
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
            print(self.currRoom)
            
            // update paitent's current location to database
            ref.child("/PatientLocation/" + userPhoneNum!).setValue(["room": self.currRoom])
        }
    }
    
    func beaconManager(_ manager: KTKBeaconManager, didEnter region: KTKBeaconRegion) {
        print("Enter region \(region)")
    }
    
    func beaconManager(_ manager: KTKBeaconManager, didExitRegion region: KTKBeaconRegion) {
        print("Exit region \(region)")
    }
    
}

