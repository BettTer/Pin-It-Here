//
//  File.swift
//  PlanFlowLocalSharedPackge
//
//  Created by YY.COUPLE on 2025-07-15.
//

import Foundation
import UIKit

extension UIFont {
    public var fontWeight: UIFont.Weight? {
        let traits = fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        if let weightValue = traits?[.weight] as? CGFloat {
            return UIFont.Weight(rawValue: weightValue)
        }
        return nil
    }
}
