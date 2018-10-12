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
    
    var sensor: Sensor!
    
    @IBOutlet weak var powerTextFeild: UILabel!
    @IBOutlet weak var speedTextFeild: UILabel!
    @IBOutlet weak var modelValue: UITextField!
    @IBOutlet weak var sensorName: UILabel!
    
    @IBAction func changeModel(_ sender: UISegmentedControl) {
        if let level = modelValue.text {
            print(level)
            switch sender.selectedSegmentIndex {
            case 0:
                wahooController?.setErgMode(UInt16(level)!)
            case 1:
                wahooController?.setStandardMode(level: UInt8(level)!)
            case 2:
                wahooController?.setResistanceMode(resistance: Float(level)! / 100)
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
                    self?.measurement = characteristic as? CyclingPowerService.Measurement
                case "A026E005-0A7D-4AB3-97FA-F1500F9FEB8B" :
                    self?.wahooController = characteristic as? CyclingPowerService.WahooTrainer
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sensorName.text = sensor.peripheral.name
        // Do any additional setup after loading the view.
        CyclingPowerService.WahooTrainer.activate()
        sensor.onServiceDiscovered.subscribe(on: self) {
            [weak self] sensor, service in
            let uuid = service.cbService.uuid.uuidString
            print(uuid)
            switch uuid {
            case "1818" :
                self?.cyclingPowerService = service as? CyclingPowerService
            default:
                break
            }
            
        }
    }
    
    private func refreshData() {
        powerTextFeild.text = String(measurement?.instantaneousPower ?? 0)
        speedTextFeild.text = String(measurement?.speedKPH ?? 0)
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
