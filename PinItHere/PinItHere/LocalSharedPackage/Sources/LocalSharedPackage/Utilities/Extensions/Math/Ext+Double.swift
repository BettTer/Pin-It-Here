//
//  Ext+Double.swift
//  PlanFlow
//
//  Created by YY.COUPLE on 2025-07-06.
//

import Foundation

extension Double {
    public func rounded(toDecimals decimals: Int) -> Double {
        let multiplier = pow(10.0, Double(decimals))
        let rawValue = self * multiplier
        
        guard rawValue.isFinite else { return self }

        let intValue = Int(rawValue.rounded())
        return Double(intValue) / multiplier
    }
}
