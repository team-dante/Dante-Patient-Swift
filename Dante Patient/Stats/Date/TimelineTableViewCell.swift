//
//  TimelineTableViewCell.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/21/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class TimelineTableViewCell: UITableViewCell {
    
    var allRows = Int()
    var currentIndexPath = IndexPath()
    let offSet: CGFloat = 30.0
    let circleRadius: CGFloat = 10.0
    
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func draw(_ rect: CGRect) {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: offSet,y: self.bounds.midY), radius: CGFloat(circleRadius), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        UIColor("#00446A").setStroke()
        circlePath.stroke()
        
        let dashes: [CGFloat] = [12, 1] //line with dash pattern of 4 thick and i unit space

        //creating the top line with dashed pattern
        let dashPath1 = UIBezierPath()
        let startPoint1 = CGPoint(x: offSet, y: 0)
        dashPath1.move(to: startPoint1)
        
        let endPoint1 = CGPoint(x: offSet, y: self.bounds.midY - circleRadius)
        dashPath1.addLine(to: endPoint1)
        
        dashPath1.setLineDash(dashes, count: dashes.count, phase: 0)
        dashPath1.lineWidth = 2.0
        dashPath1.lineCapStyle = .butt
        
        //creating the bottom line with dashed pattern
        let dashPath2 = UIBezierPath()
        let startPoint2 = CGPoint(x: offSet, y: self.bounds.midY + circleRadius)
        dashPath2.move(to: startPoint2)
        
        let endPoint2 = CGPoint(x: offSet, y: self.bounds.maxY)
        dashPath2.addLine(to: endPoint2)
        
        dashPath2.setLineDash(dashes, count: dashes.count, phase: 0)
        dashPath2.lineWidth = 2.0
        dashPath2.lineCapStyle = .butt
        
        switch currentIndexPath.row {
        case 0:
            if allRows > 1 {
                dashPath2.stroke()
            }
        case allRows - 1:
            dashPath1.stroke()
        default:
            dashPath1.stroke()
            dashPath2.stroke()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.setNeedsDisplay()
    }
}
