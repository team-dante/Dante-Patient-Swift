//
//  VisitHistoryTableViewCell.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/21/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class VisitHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
