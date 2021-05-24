
//
//  MotionManager.swift
//  AIWorkout Collector WatchKit Extension
//
//  Created by Aditya Saravana on 4/12/21.
//

import Foundation
import CoreMotion
import Combine
import HealthKit

// MARK: - MotionManager Class
final class MotionManager: ObservableObject {
    let motionManager = CMMotionManager()
    let serverManager = ServerManager()
    
    @Published var accelerometerData: [[Double]] = []
    @Published var gyroData: [[Double]] = []
    @Published var deviceMotionData: [[Double]] = []
    
    @Published var mostRecentSession = Date()
    
    @Published var fileName = ""
}


// MARK: - MotionManager Functions

extension MotionManager {
    func start() {
        self.mostRecentSession = Date()
        
        let motionIsAvailible = motionManager.isAccelerometerAvailable
        let gyroIsAvailable = motionManager.isGyroAvailable
        let deviceMotionIsAvailible = motionManager.isDeviceMotionAvailable
        
        if motionIsAvailible {
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                guard let data = data, error == nil else {
                    return
                }
                
                
                let timeStamp = Double((Date().timeIntervalSince1970) * 1000)
                self.accelerometerData.append([data.acceleration.x, data.acceleration.y, data.acceleration.z, timeStamp])
                
                
                print(data)
            }
        }
        
        if gyroIsAvailable {
            motionManager.startGyroUpdates(to: .main) { (data, error) in
                guard let data = data, error == nil else {
                    return
                }
                
                let timeStamp = Double((Date().timeIntervalSince1970) * 1000)
                
                self.gyroData.append([data.rotationRate.x, data.rotationRate.y, data.rotationRate.z, timeStamp])
                
                print(data)
            }
        }
        
        if deviceMotionIsAvailible {
            motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
                guard let data = data, error == nil else {
                    return
                }
                
                let timeStamp = Double((Date().timeIntervalSince1970) * 1000)
                
                self.deviceMotionData.append([data.attitude.quaternion.w, data.attitude.quaternion.x, data.attitude.quaternion.y, data.attitude.quaternion.z, data.attitude.pitch, data.attitude.roll, data.attitude.yaw, timeStamp])
                print(data)
            }
        }
    }
    
    
    func save(actionType: ActionType) {
        let fileLabel = "\(actionType)".uppercased()
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        let motionData: [String : [[Double]]] = [
            "AccelerometerData": accelerometerData,
            "GyroData": gyroData,
            "DeviceMotionData": deviceMotionData
        ]
        
        do {
            let sessionID = UUID().uuidString
            let plistURL = URL(fileURLWithPath: "MotionData-\(sessionID)-\(fileLabel)", relativeTo: FileManager.documentsDirectoryURL).appendingPathExtension("plist")
            fileName = "MotionData-\(sessionID)-\(fileLabel)"
            let data = try encoder.encode(motionData)
            try data.write(to: plistURL, options: .atomicWrite)
        } catch let error {
            print(error)
        }
        
    }
    
    func upload() {
        serverManager.sendPostRequest(fileName: fileName)
    }
    
    func stop(actionType: ActionType) {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
        save(actionType: actionType)
        upload()
        accelerometerData = []
        gyroData = []
        deviceMotionData = []
    }
}

