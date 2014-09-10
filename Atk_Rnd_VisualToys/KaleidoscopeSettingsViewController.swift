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

    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var cameraSwitch: UISwitch!
    
    @IBOutlet weak var cameraZoomSlider: UISlider!
    
    override func viewDidLoad() {
    }
    
    func settingsWillOpen() {
        self.updateCameraSettings()
    }
    
    func settingsDidClose() {
        
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
    
    @IBAction func cameraSwitchValueChanged(sender: UISwitch) {
        if cameraSwitch.on {
            cameraLabel.text = "Face Exploration"
        }
        else {
            cameraLabel.text = "Space Exploration"
        }
        
        self.kaleidoscopeViewController.isUsingFrontFacingCamera = cameraSwitch.on
        self.updateCameraSettings()
    }
    
    @IBAction func cameraZoomValueChanged(sender: UISlider) {
        self.kaleidoscopeViewController.zoom = CGFloat(sender.value)
    }
    
    func updateCameraSettings() {
        self.cameraZoomSlider.maximumValue = Float(self.kaleidoscopeViewController.maxZoom)
        self.cameraZoomSlider.value = Float(self.kaleidoscopeViewController.zoom)
    }
}
