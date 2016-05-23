//
//  ViewController.swift
//  SampleHealthKitApp
//
//  Created by Seino Yoshinori on 2016/04/17.
//  Copyright © 2016年 yoshinori. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tfBodyTemperature:UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        observeBodyTemperature()
//        
//        observeAnchoredBodyTemperature()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnTouchUp(sender: UIButton) {
        print(sender)
        
        let textStr: NSString! = NSString(format: "\(tfBodyTemperature!.text!)")
        VitalStore.saveBodyTemperature(textStr.doubleValue)
        VitalStore.saveHeartRate(textStr.doubleValue)
        VitalStore.findAllBodyTemperature()
    }
}

