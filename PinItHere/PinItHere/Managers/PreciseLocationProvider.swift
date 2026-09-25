//
//  PreciseLocationProvider.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-09-23.
//

import CoreLocation
import CoreMotion
import LocalSharedPackage

final class PreciseAltitudeProvider: NSObject {
    public static let shared = PreciseAltitudeProvider()
    private let altimeter = CMAltimeter()
    
    func fetchPreciseAltitude(base: Double, callBack: @escaping (Double?) -> Void) {
        print("基准绝对高度（海平面）: \(base) m")
        
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            return
        }
        
        altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
            guard let data = data else {
                callBack(nil)
                return
            }
            
            // * 相对变化量（米）
            let relative = data.relativeAltitude.doubleValue
            let totalAltitude = base + relative
            
            print("相对变化: \(relative) m")
            print("叠加后的当前海拔: \(totalAltitude) m")
            
            callBack(totalAltitude)
        }
    }
}

final class PreciseLocationProvider: NSObject {
    static let shared = PreciseLocationProvider()

    private let manager = CLLocationManager()
    
    // MARK: - Data
    private var minHorizontalAccuracy: CLLocationAccuracy = 10
    private var maxAge: TimeInterval = 5
    private var stopAfterSuccess: Bool = true
    
    // MARK: - Callback
    private var completion: ((Result<CLLocation, Error>) -> Void)?
    private(set) var latestLocation: CLLocation?
    private var lastHeading: CLHeading?
    // ✅ 新增：对外“真北”朝向（度，0~360），若不可用则返回磁北或 nil
    public var latestHeadingTrue: Double? {
        // 1) 优先用 trueHeading
        if let h = lastHeading, h.headingAccuracy >= 0, h.trueHeading >= 0 {
            return h.trueHeading  // [0,360)
        }
        // 2) 其次用 course（也是相对真北）
        if let loc = latestLocation, loc.course >= 0 {
            return loc.course     // [0,360)
        }
        // 3) 兜底用磁北（无磁偏角校正），并打印日志提示
        if let h = lastHeading, h.headingAccuracy >= 0 {
            LOG.p("HEADING", "fallback to magneticHeading=\(h.magneticHeading) (no trueHeading)")
            return h.magneticHeading
        }
        return nil
    }
    
    private override init() {
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        // 如需后台：manager.allowsBackgroundLocationUpdates = true
    }
    
    func start(stopAfterSuccess: Bool, completion: ((Result<CLLocation, Error>) -> Void)?) {
        self.stopAfterSuccess = stopAfterSuccess
        self.completion = completion
        
        determineAuthorizationStatus()
    }
    
    func stop() {        
        manager.stopUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.stopUpdatingHeading()             // ✅ 停止航向
        }
        completion = nil
    }
    
    // * 统一收尾，避免多处强解包
    private func finish(_ result: Result<CLLocation, Error>) {
        completion?(result)
        if stopAfterSuccess {
            stop()
        }
    }
    
    private func determineAuthorizationStatus() {
        // 统一用同一个 manager 的授权状态
        switch manager.authorizationStatus {
        case .notDetermined:
            // 必须在主线程请求授权
            DispatchQueue.main.async { [weak self] in
                self?.manager.requestWhenInUseAuthorization()
            }

        case .denied, .restricted:
            completion!(.failure(CLError(.denied)))
            stop()

        case .authorizedWhenInUse, .authorizedAlways:
            startRespectingAccuracy()

        @unknown default:
            completion!(.failure(CLError(.locationUnknown)))
            stop()
        }
    }
    
    private func startRespectingAccuracy() {
        // 需要“精确定位”时再申请（Info.plist 需配置 full-accuracy 说明）
        if manager.accuracyAuthorization == .reducedAccuracy {
            manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "full-accuracy") { [weak self] _ in
                self?.manager.startUpdatingLocation()
                self?.startHeadingIfAvailable()
            }
        } else {
            manager.startUpdatingLocation()
            startHeadingIfAvailable()
        }
    }
    
    private func startHeadingIfAvailable() {
        guard CLLocationManager.headingAvailable() else {
            LOG.p("HEADING", "heading not available on this device")
            return
        }
        // 可选：限制更新频率/灵敏度（度）。None=尽可能频繁
        manager.headingFilter = kCLHeadingFilterNone
        manager.startUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate
extension PreciseLocationProvider: CLLocationManagerDelegate {
    // * iOS 14+ 正确的授权变更回调
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        determineAuthorizationStatus()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        let age = -location.timestamp.timeIntervalSinceNow
        guard age <= maxAge,
              location.horizontalAccuracy > 0,
              location.horizontalAccuracy <= minHorizontalAccuracy else {
//            location.verticalAccuracy > 0
            return
        }
        // * 68%, 处于Accuracy半径
        finish(.success(location))
        
        latestLocation = location
        
    }
    
    // * 被拒/超时/不可用等
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
        finish(.failure(error))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
        let t = newHeading.trueHeading
        let m = newHeading.magneticHeading
        LOG.p("HEADING", "update true=\(t >= 0 ? "\(t)" : "N/A"), magnetic=\(m), acc=\(newHeading.headingAccuracy)")
    }
    
    /// 当精度差时系统可弹校准界面；也可据情况返回 true 强制
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return lastHeading?.headingAccuracy ?? -1 > 15  // 例：>15 度时允许弹校准
    }
}
