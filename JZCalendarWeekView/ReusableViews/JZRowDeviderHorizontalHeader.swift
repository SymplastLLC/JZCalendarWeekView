//
//  JZRowDividerHorizontalHeader.swift
//  Symplast
//
//  Created by Sergei Kviatkovskii on 04.05.2021.
//

#if os(iOS)

import UIKit

open class JZRowDividerHorizontalHeader: UICollectionReusableView {

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = JZWeekViewColors.gridLine
        label.textAlignment = .right
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        layer.isDoubleSided = false
        backgroundColor = .white
        addSubview(timeLabel)
        timeLabel.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        timeLabel.text = nil
        if let attributes = layoutAttributes as? JZDividerLayoutAttributes,
           let text = attributes.text,
           !text.isEmpty {
            isHidden = false
            timeLabel.text = attributes.text
        } else {
            isHidden = true
        }
    }
}

#endif
