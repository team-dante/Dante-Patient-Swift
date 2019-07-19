//
//  AppDelegate.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/1/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import UIColor_Hex_Swift
import IQKeyboardManagerSwift
import KontaktSDK
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var beaconManager: KTKBeaconManager!
    var backgroundTask: UIBackgroundTaskIdentifier!
    var inBackground = false
    
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // configure Firebase
        FirebaseApp.configure()
        
        // get today's date and current user's phone number
        dateToday = self.formattedDate()
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        // customize the navigation header for all screens
        let nav = UINavigationBar.appearance()
        nav.barTintColor = UIColor("#31c1ff")
        nav.tintColor = UIColor("#fcfcfc")
        nav.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor("#fff"), NSAttributedString.Key.font: UIFont(name:"Rubik-Medium", size: 18)!]
        
        // smart keyboard avoiding library
        IQKeyboardManager.shared.enable = true
        
        // ---------------- set up kontakt beacons ------------------
        Kontakt.setAPIKey("IKLlxikqjxJwiXbyAgokGeLkcZqipAnc")
        // Initiate Beacon Manager
        beaconManager = KTKBeaconManager(delegate: self)
        beaconManager.requestLocationAlwaysAuthorization()

        let region = KTKBeaconRegion(proximityUUID: UUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID, identifier: "region-identifer")
        region.notifyEntryStateOnDisplay = true
        beaconManager.startMonitoring(for: region)
        beaconManager.startRangingBeacons(in: region)

        backgroundTask = UIBackgroundTaskIdentifier.invalid
        inBackground = true
        // ----------- end of setting up kontakt beacons ----------------
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("I am in background")
        self.extendingBackgroundRunningTime()
        print("don't")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        self.inBackground = false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    
    func beaconManager(_ manager: KTKBeaconManager, didDetermineState state: CLRegionState, for region: KTKBeaconRegion) {
        if inBackground {
            self.extendingBackgroundRunningTime()
        }
    }
    
    func extendingBackgroundRunningTime() {
        if backgroundTask != .invalid {
            return
        }
        let self_terminate = true
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DummyTask", expirationHandler: {
            if self_terminate {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
            }
        })
        
        DispatchQueue.global(qos: .default).async {
            execute: do {
                print("Background task started")
                while true {
                    print(String(format: "background time remaining: %8.2f", UIApplication.shared.backgroundTimeRemaining))
                    Thread.sleep(forTimeInterval: 1)
                }
            }
        }
    }
    
}

extension AppDelegate: KTKBeaconManagerDelegate {
    func beaconManager(_ manager: KTKBeaconManager, didRangeBeacons beacons: [CLBeacon], in region: KTKBeaconRegion) {
        let sortedBeacons = beacons.sorted(by: { $0.accuracy < $1.accuracy })
        
        if (self.count < self.threshold) {
            self.count += 1
            for beacon in sortedBeacons {
                if beacon.accuracy == -1 {
                    self.roomDict[Int(truncating: beacon.major)]?.append(999)
                } else {
                    self.roomDict[Int(truncating: beacon.major)]?.append(Double(beacon.accuracy))
                }
            }
        } else {
            for beacon in sortedBeacons {
                self.roomDict[Int(truncating: beacon.major)]?.remove(at: 0)
                if beacon.accuracy == -1 {
                    self.roomDict[Int(truncating: beacon.major)]?.append(999)
                } else {
                    self.roomDict[Int(truncating: beacon.major)]?.append(Double(beacon.accuracy))
                }
            }
            
            var avgList: [Int: Double] = [:]
            for beacon in sortedBeacons {
                let beaconArray = self.roomDict[Int(truncating: beacon.major)]
                if beaconArray!.count >= threshold {
                    let avg = Double(beaconArray!.reduce(0, +)) / Double(threshold)
                    avgList[Int(truncating: beacon.major)] = avg
                }
            }
            
            let sortedBeaconArr = avgList.sorted(by: { $0.1 < $1.1})
            if sortedBeaconArr.count != 0 {
                print(sortedBeaconArr[0].value)
                if sortedBeaconArr[0].value >= self.cutoff[sortedBeaconArr[0].key]! {
                    self.currRoom = "Private"
                } else {
                    self.currRoom = self.majorToRoom[sortedBeaconArr[0].key]!
                }
            }

            print(self.currRoom)
        }
    }
    
    func beaconManager(_ manager: KTKBeaconManager, didEnter region: KTKBeaconRegion) {
        print("Enter region \(region)")
    }
    
    func beaconManager(_ manager: KTKBeaconManager, didExitRegion region: KTKBeaconRegion) {
        print("Exit region \(region)")
    }
    
}
