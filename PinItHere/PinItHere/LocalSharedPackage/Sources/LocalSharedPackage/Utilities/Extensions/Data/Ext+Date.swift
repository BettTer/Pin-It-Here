//
//  Ext+Date.swift
//  PlanFlow
//
//  Created by YY.COUPLE on 2025-07-01.
//

import Foundation

extension Date {
    public var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    public func isTimeEarlier(than otherDate: Date) -> Bool {
        return compareTimeOnly(to: otherDate) == .orderedAscending
    }
    
    public func isTimeLater(than otherDate: Date) -> Bool {
        return compareTimeOnly(to: otherDate) == .orderedDescending
    }
    
    private func compareTimeOnly(to otherDate: Date) -> ComparisonResult {
        let calendar = Calendar.current

        let selfComponents = calendar.dateComponents([.hour, .minute, .second], from: self)
        let otherComponents = calendar.dateComponents([.hour, .minute, .second], from: otherDate)

        if let selfDate = calendar.date(from: selfComponents),
           let otherDate = calendar.date(from: otherComponents) {
            let result = selfDate.compare(otherDate)
            
            return result
        }

        return .orderedSame
    }
    
    public static func calculateDaysBetween(from: Date,
                                     to: Date,
                                     saveDecimals: Int?) -> Double {
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: from, to: to)
        
        let days = Double(components.day ?? 0)
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        
        let totalDays = days + hours / 24.0 + minutes / 60.0 / 24.0
        var result = totalDays
        
        if let saveDecimals = saveDecimals {
            let value = pow(10.0, Double(saveDecimals))
            result = Double(Int(totalDays * value)) / value
        }
        
        return result
    }
    
    public func addDays(days: Double) -> Date? {
//        let result = Calendar.current.date(byAdding: .day, value: days, to: self)
        
        let calendar = Calendar.current
        let intDays = Int(days)
        let fractionalDay = days - Double(intDays)
        
        guard let dateAfterDays = calendar.date(byAdding: .day, value: intDays, to: self) else {
            return nil
        }
        
        let secondsToAdd = fractionalDay * 86400.0
        return dateAfterDays.addingTimeInterval(secondsToAdd)
    }
    
    public func fetchDateString(dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: self)
        
        return dateString
    }
    
}
