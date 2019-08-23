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
    
    // draw timeline on the left
    override func draw(_ rect: CGRect) {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: offSet,y: self.bounds.midY), radius: CGFloat(circleRadius), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        UIColor("#00446A").setStroke()
        circlePath.stroke()
        
        // draw dashes
        let dashes: [CGFloat] = [12, 1]

        //creating the top-half dashes with dashed pattern
        let dashPath1 = UIBezierPath()
        let startPoint1 = CGPoint(x: offSet, y: 0)
        dashPath1.move(to: startPoint1)
        
        let endPoint1 = CGPoint(x: offSet, y: self.bounds.midY - circleRadius)
        dashPath1.addLine(to: endPoint1)
        
        dashPath1.setLineDash(dashes, count: dashes.count, phase: 0)
        dashPath1.lineWidth = 2.0
        dashPath1.lineCapStyle = .butt
        
        //creating the bottom-half dashes with dashed pattern
        let dashPath2 = UIBezierPath()
        let startPoint2 = CGPoint(x: offSet, y: self.bounds.midY + circleRadius)
        dashPath2.move(to: startPoint2)
        
        let endPoint2 = CGPoint(x: offSet, y: self.bounds.maxY)
        dashPath2.addLine(to: endPoint2)
        
        dashPath2.setLineDash(dashes, count: dashes.count, phase: 0)
        dashPath2.lineWidth = 2.0
        dashPath2.lineCapStyle = .butt
        
        // first row: if only 1 row in total, no dashes; if > 1 row in total, draw the bottom half dashes
        // last row: draw the top-half dashes
        // the rest: draw both top and bottom dashes
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
    
    // redraw UIBezierPath when table cells are being recycled (e.g. scrolling)
    override func prepareForReuse() {
        super.prepareForReuse()
        self.setNeedsDisplay()
    }
}
