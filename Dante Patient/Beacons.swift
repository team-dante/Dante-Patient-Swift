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
    
    // records a queue of 10 distances for each beacon
    var roomDict: [Int: [Double]] = [1: [], 2: [], 3:[]]
    // map beacon major to the real clinic room
    let majorToRoom = [ 1: "exam1", 2: "CTRoom", 3: "femaleWaitingRoom" ]
    // map beacon major to its corresponding cutoff value (1m)
    let cutoff = [1: 1.5, 2: 1.5, 3: 1.5]
    // after 10 rounds, perform stats analysis
    let threshold = 5
    
    var count = 0
    
    var dateToday: String!
    var userPhoneNum: String?
    
    var currRoom = ""
    
    func detectBeacons() {
        // get today's date and current user's phone number
        dateToday = self.formattedDate()
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        // ---------------- set up kontakt beacons ------------------
        Kontakt.setAPIKey("IKLlxikqjxJwiXbyAgokGeLkcZqipAnc")
        // Initiate Beacon Manager
        beaconManager = KTKBeaconManager(delegate: self)
        beaconManager.requestLocationAlwaysAuthorization()
        
        let region = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID, identifier: "region-identifer")
        
        let region1 = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID, major: 1, identifier: "region-identifer")
        region1.notifyEntryStateOnDisplay = true
        beaconManager.startMonitoring(for: region1)
        
        let region2 = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID, major: 2, identifier: "region-identifer")
        region1.notifyEntryStateOnDisplay = true
        beaconManager.startMonitoring(for: region2)
        
        beaconManager.startRangingBeacons(in: region)
        // ----------- end of setting up kontakt beacons ----------------
    }
    
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
        for beacon in beacons {
            print(beacon.major, beacon.accuracy)
        }
        self.count += 1

        print(count)
        //        if (self.count < self.threshold) {
        //            self.count += 1
        //            for beacon in sortedBeacons {
        //                if beacon.accuracy == -1 {
        //                    self.roomDict[Int(truncating: beacon.major)]?.append(999)
        //                } else {
        //                    self.roomDict[Int(truncating: beacon.major)]?.append(Double(beacon.accuracy))
        //                }
        //            }
        //        } else {
        //            for beacon in sortedBeacons {
        //                self.roomDict[Int(truncating: beacon.major)]?.remove(at: 0)
        //                if beacon.accuracy == -1 {
        //                    self.roomDict[Int(truncating: beacon.major)]?.append(999)
        //                } else {
        //                    self.roomDict[Int(truncating: beacon.major)]?.append(Double(beacon.accuracy))
        //                }
        //            }
        //
        //            var avgList: [Int: Double] = [:]
        //            for beacon in sortedBeacons {
        //                let beaconArray = self.roomDict[Int(truncating: beacon.major)]
        //                if beaconArray!.count >= threshold {
        //                    let avg = Double(beaconArray!.reduce(0, +)) / Double(threshold)
        //                    avgList[Int(truncating: beacon.major)] = avg
        //                }
        //            }
        //
        //            let sortedBeaconArr = avgList.sorted(by: { $0.1 < $1.1})
        //            if sortedBeaconArr.count != 0 {
        //                print(sortedBeaconArr[0].value)
        //                if sortedBeaconArr[0].value >= self.cutoff[sortedBeaconArr[0].key]! {
        //                    self.currRoom = "Private"
        //                } else {
        //                    self.currRoom = self.majorToRoom[sortedBeaconArr[0].key]!
        //                }
        //            }
        //            print(self.currRoom)
        //        }
    }
    
    func beaconManager(_ manager: KTKBeaconManager, didEnter region: KTKBeaconRegion) {
        print("Enter region \(region)")
    }
    
    func beaconManager(_ manager: KTKBeaconManager, didExitRegion region: KTKBeaconRegion) {
        print("Exit region \(region)")
    }
    
}

