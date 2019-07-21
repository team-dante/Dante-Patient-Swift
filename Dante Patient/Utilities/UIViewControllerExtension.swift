//
//  UIViewControllerExtension.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

extension UIViewController {
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
    
    func prettifyRoom(room: String) -> String {
        switch room {
        case "femaleWaitingRoom":
            return "Female Waiting Room"
        case "CTRoom":
            return "CT Room"
        case "exam1":
            return "Exam 1 Room"
        default:
            return ""
        }
    }
    
    func parseTimeElapsed(timeElapsed: Int) -> String {
        let hr = timeElapsed / 3600
        let sec = timeElapsed % 60
        let min = (timeElapsed % 3600) / 60
        let hrStr = (hr < 10) ? "0\(hr)" : "\(hr)"
        let minStr = (min < 10) ? "0\(min)" : "\(min)"
        let secStr = (sec < 10) ? "0\(sec)" : "\(sec)"
        return "\(hrStr):\(minStr):\(secStr)"
    }
    
    func parseStartTime(startTime: Int) -> String {
        let date = NSDate(timeIntervalSince1970: TimeInterval(startTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let parsedTime = dateFormatter.string(from: date as Date)
        return parsedTime
    }
}
