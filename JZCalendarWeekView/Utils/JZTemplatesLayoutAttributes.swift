//
//  JZTemplatesLayoutAttributes.swift
//  Symplast
//
//  Created by Aleksei Konshin on 20.08.2020.
//

#if os(iOS)

import UIKit

final class JZTemplatesLayoutAttributes: UICollectionViewLayoutAttributes {

    var text: String?
    var backgroundColor: UIColor?
    var isUnavailability: Bool?
    var isScheduleTemplate: Bool?
    var labelOffset: Double?
    var isDimmed = false
}

#endif
