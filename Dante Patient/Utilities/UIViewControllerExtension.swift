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
        case "LA1":
            return "Linear Accelerator 1"
        case "TLA":
            return "Trilogy Linear Acc."
        case "CT":
            return "CT Simulator"
        case "WR":
            return "Waiting Room"
        default:
            return ""
        }
    }
    
    func parseTimeElapsed(timeElapsed: Int) -> String {
//        let hr = timeElapsed / 3600
        let sec = timeElapsed % 60
        let min = (timeElapsed % 3600) / 60
//        let hrStr = (hr < 10) ? "0\(hr)" : "\(hr)"
        let minStr = (min < 10) ? "0\(min)" : "\(min)"
        let secStr = (sec < 10) ? "0\(sec)" : "\(sec)"
        return "\(minStr):\(secStr)"
    }
    
    func parseTotalTime(timeElapsed: Int) -> String {
        let hr = timeElapsed / 3600
        let min = Int((Double(timeElapsed % 3600) / 60.0).rounded())
        let minStr = (min < 10) ? "0\(min)" : "\(min)"
        return "\(hr) hr \(minStr) min"
    }
    
    func parseStartTime(startTime: Int) -> String {
        let date = NSDate(timeIntervalSince1970: TimeInterval(startTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let parsedTime = dateFormatter.string(from: date as Date)
        return parsedTime
    }
    
    func parseEndTime(endTime: Int) -> String {
        let date = NSDate(timeIntervalSince1970: TimeInterval(endTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let parsedTime = dateFormatter.string(from: date as Date)
        return parsedTime
    }
    
    func parseMonth(mon: String) -> String {
        switch mon {
        case "01":
            return "Jan"
        case "02":
            return "Feb"
        case "03":
            return "Mar"
        case "04":
            return "Apr"
        case "05":
            return "May"
        case "06":
            return "Jun"
        case "07":
            return "Jul"
        case "08":
            return "Aug"
        case "09":
            return "Sep"
        case "10":
            return "Oct"
        case "11":
            return "Nov"
        case "12":
            return "Dec"
        default:
            return "none"
        }
    }
    
    func parseStartOfWeek(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.date(from: date)
        
        let startWeek = formattedDate?.startOfWeek
        let startDate = dateFormatter.string(from: startWeek!)
        
        return startDate
    }
    
    func parseEndOfWeek(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.date(from: date)
        
        let endWeek = formattedDate?.endOfWeek
        let endDate = dateFormatter.string(from: endWeek!)

        return endDate
    }
    
    func parseWeek(firstDay: String, lastDay: String) -> String {

        // split the first day and the last day of the week
        let startDateArr = firstDay.split(separator: "-")
        let endDateArr = lastDay.split(separator: "-")
        
        // get month and day of the start and end of the week
        let startMonth = self.parseMonth(mon: String(startDateArr[1]))
        let endMonth = startDateArr[1] == endDateArr[1] ? "" : self.parseMonth(mon: String(endDateArr[1])) + " "
        let firstDayOfWeek = startDateArr[2]
        let lastDayOfWeek = endDateArr[2]
        
        let weekStr = "\(startMonth) \(firstDayOfWeek) - \(endMonth)\(lastDayOfWeek)"
        
        return weekStr
    }
    
    func hideNavigationBar() {
        let navigationBar = navigationController!.navigationBar
        navigationBar.barTintColor = UIColor("#E8FAFD")
        navigationBar.tintColor = nil
        navigationBar.isTranslucent = false
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
    }
    
    func customizeTableView(tableView: UITableView) {
        tableView.layer.cornerRadius = 20
        tableView.layer.masksToBounds = true
        tableView.layer.shadowColor = UIColor.black.cgColor
        tableView.layer.shadowOpacity = 0.3
        tableView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        tableView.layer.shadowRadius = 8
    }
}
