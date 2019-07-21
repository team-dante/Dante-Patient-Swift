//
//  currRoomTableViewCell.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class CurrRoomTableViewCell: UITableViewCell {

    @IBOutlet weak var currRoom: UILabel!
    @IBOutlet weak var clockLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
