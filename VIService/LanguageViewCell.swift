//
//  LanguageViewCell.swift
//  VIService
//
//  Created by Coding Guru on 11/18/24.
//  Copyright © 2024 Polestar. All rights reserved.
//

import UIKit

class LanguageViewCell: UITableViewCell {

    @IBOutlet weak var flagImageView: UIImageView!
    
    @IBOutlet weak var langTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configureCell(with flagImage: UIImage?, langName: String) {
        flagImageView.image = flagImage
        langTitle.text = langName
    }
    
}
