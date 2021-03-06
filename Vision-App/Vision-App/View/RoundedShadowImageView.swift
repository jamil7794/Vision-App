//
//  RoundedShadowImageView.swift
//  Vision-App
//
//  Created by Jamil Jalal on 1/20/19.
//  Copyright © 2019 Jamil Jalal. All rights reserved.
//

import UIKit

class RoundedShadowImageView: UIImageView {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = 15

    }

}
