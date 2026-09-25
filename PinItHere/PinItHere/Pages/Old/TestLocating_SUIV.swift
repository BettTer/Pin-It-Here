//
//  TestLocating_SUIV.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-09-22.
//

import SwiftUI
import CoreLocation

struct TestLocating_SUIV: View {
    var body: some View {
        Button {
            PreciseLocationProvider.shared.start(stopAfterSuccess: true) { result in
                switch result {
                case .success(let loc):
                    let latitude = loc.coordinate.latitude
                    let longitude = loc.coordinate.longitude
                    let altitude = loc.altitude
                    let horizontalAccuracy = loc.horizontalAccuracy
                    let verticalAccuracy = loc.verticalAccuracy
                    
                    let resultString = String(format: "=>纬度: %.6f\n=>经度: %.6f\n=>海拔: %.1f m\n=>水平误差: %.1f m\n=>垂直误差: %.1f m", latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy)

                    print("\(resultString)")
                    
//                    PreciseAltitudeProvider.shared.fetchPreciseAltitude(base: altitude) { preciseAltitude in
//                        if let preciseAltitude = preciseAltitude {
//                            let resultString = String(format: "=>纬度: %.6f\n=>经度: %.6f\n=>海拔: %.1f m\n=>水平误差: %.1f m\n=>垂直误差: %.1f m", latitude, longitude, preciseAltitude, horizontalAccuracy, verticalAccuracy)
//                            print("修正后:\n\(resultString)")
//
//                        }
//
//                    }
                    
                case .failure(let error):
                    print(error)
                    
                }
                
            }
            
        } label: {
            Text("点击开始定位")
                .foregroundStyle(Color(.label))
        }
    }
}

#Preview {
    TestLocating_SUIV()
}
