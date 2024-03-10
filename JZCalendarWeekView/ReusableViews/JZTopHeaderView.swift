//
//  JZTopHeaderView.swift
//  JZCalendarWeekView
//
//  Created by Sergei Kviatkovskii on 3/10/24.
//  Copyright © 2024 Jeff Zhang. All rights reserved.
//

import UIKit

open class JZTopHeaderView: UICollectionReusableView {
        
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        isOpaque = true
        layer.isDoubleSided = false
        backgroundColor = .white
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
