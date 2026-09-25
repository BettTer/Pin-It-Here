//
//  File.swift
//  PlanFlowLocalSharedPackge
//
//  Created by YY.COUPLE on 2025-08-12.
//

import Foundation


extension Bundle {
    public var appDisplayName: String {
        // 读取本地化后的 CFBundleDisplayName
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
               object(forInfoDictionaryKey: "CFBundleName") as? String ??
               "Plan Flow"
    }
}
