//
//  SensorsList.swift
//  SensorsTrainerTest
//
//  Created by Edison on 2018/8/9.
//  Copyright © 2018年 Edison. All rights reserved.
//

import UIKit
import SwiftySensors
import SwiftySensorsTrainers

class SensorsList: UITableViewController {
    
    fileprivate var sensors: [Sensor] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        SensorManager.instance.onSensorDiscovered.subscribe(on: self) { [weak self] sensor in
            guard let s = self else {return}
            if !s.sensors.contains(sensor) {
                s.sensors.append(sensor)
                s.tableView.reloadData()
            }
        }
        
        SensorManager.instance.onSensorConnected.subscribe(on: self) { [weak self] sensor in
            if sensor.peripheral.state == .connected {
                print("connected")
                self?.performSegue(withIdentifier: "sensorConnected", sender: sensor)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sensors = SensorManager.instance.sensors
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sensors.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sensorCell", for: indexPath)
        
        let sensor = sensors[indexPath.row]
        cell.textLabel?.text = sensor.peripheral.name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.row >= sensors.count {return}
        let sensor = sensors[indexPath.row]
        
        if sensor.peripheral.state == .connected {
            SensorManager.instance.disconnectFromSensor(sensor)
        } else if sensor.peripheral.state == .disconnected {
            SensorManager.instance.connectToSensor(sensor)
        }
    }



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "sensorConnected" {
            if let sensorController = segue.destination as? SensorController, let sensor = sender as? Sensor {
                sensorController.sensor = sensor
            }
        }
    }

}
