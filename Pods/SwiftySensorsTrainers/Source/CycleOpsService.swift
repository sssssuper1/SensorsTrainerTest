//
//  CycleOpsService.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import CoreBluetooth
import SwiftySensors
import Signals

open class CycleOpsService: Service, ServiceProtocol {
    
    public static var uuid: String { return "C0F4013A-A837-4165-BAB9-654EF70747C6" }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        ControlPoint.uuid:  ControlPoint.self
    ]
    
    public var controlPoint: ControlPoint? { return characteristic() }
    
    open class ControlPoint: Characteristic {
        
        public static var uuid: String { return "CA31A533-A858-4DC7-A650-FDEB6DAD4C14" }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
            
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                if let response = CycleOpsSerializer.readReponse(value) {
                    switch response.status {
                    case .speedOkay:
                        break
                    case .speedUp:
                        break
                    case .speedDown:
                        break
                    case .rollDownInitializing:
                        break
                    case .rollDownInProcess:
                        break
                    case .rollDownPassed:
                        break
                    case .rollDownFailed:
                        break
                    }
                }
            }
            super.valueUpdated()
        }
    }
    
    open func setHeadlessMode() {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(bytes: CycleOpsSerializer.setControlMode(.headless)), writeType: .withResponse)
    }
    
    
    // CycleOps trainers require ~3 seconds between manual target messages
    // -- they also take 4-5 seconds for the brake to actually engage and track towared the target.
    private let MinimumWriteInterval: TimeInterval = 3
    private var updateTargetWattTimer: Timer?
    private var targetWatts: Int16 = 0
    
    @objc private func writeTargetWatts(_ timer: Timer? = nil) {
        controlPoint?.cbCharacteristic.write(Data(bytes: CycleOpsSerializer.setControlMode(.manualPower, parameter1: self.targetWatts)), writeType: .withResponse)
    }
    
    open func setManualPower(_ targetWatts: Int16) {
        self.targetWatts = targetWatts
        if updateTargetWattTimer == nil || !updateTargetWattTimer!.isValid {
            writeTargetWatts()
            updateTargetWattTimer = Timer(timeInterval: MinimumWriteInterval, target: self, selector: #selector(writeTargetWatts(_:)), userInfo: nil, repeats: true)
            RunLoop.main.add(updateTargetWattTimer!, forMode: .commonModes)
        }
    }
    
    // weight = kg * 100, grade = % * 10
    open func setManualSlope(_ riderWeight: Int16, _ gradePercent: Int16) {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(bytes: CycleOpsSerializer.setControlMode(.manualSlope, parameter1: riderWeight, parameter2: gradePercent)), writeType: .withResponse)
    }
    
    open func setPowerRange(_ lowerTargetWatts: Int16, _ upperTargetWatts: Int16) {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(bytes: CycleOpsSerializer.setControlMode(.powerRange, parameter1: lowerTargetWatts, parameter2: upperTargetWatts)), writeType: .withResponse)
    }
    
    open func setWarmUp() {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(bytes: CycleOpsSerializer.setControlMode(.warmUp)), writeType: .withResponse)
    }
    
    open func setRollDown() {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(bytes: CycleOpsSerializer.setControlMode(.rollDown)), writeType: .withResponse)
    }    
    
    open func setWheelCircumference(_ tenthsMillimeter: UInt16) {
        
    }
    
}
