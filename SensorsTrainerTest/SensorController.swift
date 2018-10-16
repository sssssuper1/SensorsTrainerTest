//
//  SensorController.swift
//  SensorsTrainerTest
//
//  Created by Edison on 2018/8/9.
//  Copyright © 2018年 Edison. All rights reserved.
//

import UIKit
import SwiftySensors
import SwiftySensorsTrainers

class SensorController: UIViewController {
    
    enum SensorType {
        case wahoo
        case tacx
        case unknown
    }
    
    var sensor: Sensor!
    var sensorType: SensorType = .unknown
    var model = 0
    
    @IBOutlet weak var powerTextFeild: UILabel!
    @IBOutlet weak var speedTextFeild: UILabel!
    @IBOutlet weak var modelValue: UITextField!
    @IBOutlet weak var sensorName: UILabel!
    
    @IBAction func changeModel(_ sender: UISegmentedControl) {
        model = sender.selectedSegmentIndex
    }
    
    @IBAction func send(_ sender: UIButton) {
        if let target = Int(modelValue.text ?? "0") {
            print(target)
            switch sensorType {
            case .wahoo:
                setResistanceByWahoo(model: model, target: target)
            case .tacx:
                setResistanceByTacx(model: model, target: target)
            default:
                break
            }
        }
    }
    
    private var cyclingPowerService : CyclingPowerService? {
        didSet {
            cyclingPowerService?.sensor.onCharacteristicDiscovered.subscribe(on: self) { [weak self] sensor, characteristic in
                let uuid = characteristic.cbCharacteristic.uuid.uuidString
                print(uuid)
                switch uuid {
                case "2A63" :
                    if self?.sensorType != .tacx {
                        self?.measurement = characteristic as? CyclingPowerService.Measurement
                    }
                case "A026E005-0A7D-4AB3-97FA-F1500F9FEB8B" :
                    self?.wahooController = characteristic as? CyclingPowerService.WahooTrainer
                    self?.sensorType = .wahoo
                default :
                    break
                }
            }
        }
    }
    
    private var measurement : CyclingPowerService.Measurement? {
        didSet {
            measurement?.onValueUpdated.subscribe(on: self) {
                [weak self] characteristic in
                self?.refreshData()
            }
        }
    }
    
    private var wahooController : CyclingPowerService.WahooTrainer?
    
    private func setResistanceByWahoo(model: Int, target: Int) {
        switch model {
        case 0:
            wahooController?.setErgMode(UInt16(target))
        case 1:
            wahooController?.setStandardMode(level: UInt8(target))
        case 2:
            wahooController?.setResistanceMode(resistance: Float(target) / 100)
        default:
            break
        }
    }
    
    private var tacxService : TacxService? {
        didSet {
            tacxService?.sensor.onCharacteristicDiscovered.subscribe(on: self) { [weak self] sensor, characteristic in
                let uuid = characteristic.cbCharacteristic.uuid.uuidString
                print(uuid)
                switch(uuid) {
                case "6E40FEC2-B5A3-F393-E0A9-E50E24DCCA9E" :
                    self?.fecRead = characteristic as? TacxService.FECRead
                case "6E40FEC3-B5A3-F393-E0A9-E50E24DCCA9E" :
                    self?.fecWrite = characteristic as? TacxService.FECWrite
                default :
                    break
                }
            }
        }
    }
    
    private var fecRead : TacxService.FECRead? {
        didSet {
            fecRead?.onValueUpdated.subscribe(on: self) {
                [weak self] characteristic in
                self?.refreshData()
            }
        }
    }
    
    private var fecWrite : TacxService.FECWrite?
    
    private func setResistanceByTacx(model: Int, target: Int) {
        switch model {
        case 0:
            tacxService?.sendTargetPower(watts: Int16(target))
        default:
            tacxService?.sendTargetPower(watts: Int16(target))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sensorName.text = sensor.peripheral.name

        sensor.onServiceDiscovered.subscribe(on: self) {
            [weak self] sensor, service in
            let uuid = service.cbService.uuid.uuidString
            print(uuid)
            switch uuid {
            case "1818" :
                CyclingPowerService.WahooTrainer.activate()
                self?.cyclingPowerService = service as? CyclingPowerService
            case "6E40FEC1-B5A3-F393-E0A9-E50E24DCCA9E" :
                self?.tacxService = service as? TacxService
                self?.sensorType = .tacx
            default:
                break
            }
            
        }
    }
    
    private func refreshData() {
        switch sensorType {
        case .wahoo:
            powerTextFeild.text = String(measurement?.instantaneousPower ?? 0)
            speedTextFeild.text = String(measurement?.speedKPH ?? 0)
        case .tacx:
            powerTextFeild.text = String(fecRead?.instantaneousPower ?? 0)
            speedTextFeild.text = String(fecRead?.speedKPH ?? 0)
        default:
            break
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
