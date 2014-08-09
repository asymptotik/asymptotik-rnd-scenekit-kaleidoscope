//
//  KaleidoscopeControlsViewController.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/8/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import UIKit

class KaleidoscopeSettingsViewController: UIViewController {
    
    @IBOutlet weak var breatheSwitch: UISwitch!
    @IBOutlet weak var breatheDepthSlider: UISlider!
    @IBOutlet weak var breatheSpeedSlider: UISlider!
    weak var kaleidoscopeViewController: KaleidoscopeViewController!
    
    override func viewDidLoad() {
    }
    
    @IBAction func breatheSwitchValueChanged(sender: UISwitch) {
        if sender.on {
            self.kaleidoscopeViewController.startBreathing(CGFloat(breatheDepthSlider.value), duration: NSTimeInterval(breatheSpeedSlider.value))
        }
        else {
            self.kaleidoscopeViewController.stopBreathing()
        }
    }
    
    @IBAction func breatheDepthValueChanged(sender: UISlider) {
        if breatheSwitch.on {
            self.kaleidoscopeViewController.startBreathing(CGFloat(breatheDepthSlider.value), duration: NSTimeInterval(breatheSpeedSlider.value))
        }
    }
    
    @IBAction func breatheSpeedValueChanged(sender: UISlider) {
        if breatheSwitch.on {
            self.kaleidoscopeViewController.startBreathing(CGFloat(breatheDepthSlider.value), duration: NSTimeInterval(breatheSpeedSlider.value))
        }
    }
}
