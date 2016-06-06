//
//  ViewController.swift
//  PickViewSample
//
//  Created by Emiaostein on 6/3/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var pickerView: PickerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        pickerView.beganAt(component: 50, row: 49)
        
        //        let time: NSTimeInterval = 2.0
        //        let delay = dispatch_time(DISPATCH_TIME_NOW,
        //                                  Int64(time * Double(NSEC_PER_SEC)))
        //        dispatch_after(delay, dispatch_get_main_queue()) {
        //
        //            self.pickerView.beganAt(component: 99, row: 30)
        //        }
    }
}

// MARK: - PickerViewDataSource
extension ViewController: PickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: PickerView) -> Int {
        return 100
    }
    func pickerView(pickerView: PickerView, numberOfRowsInComponent component: Int) -> Int {
        return 100
    }
    func pickerView(pickerView: PickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?, actived: Bool, componentActived: Bool, rowActived: Bool) -> UIView {
        
        if let view = view as? UILabel {
            view.text = "\(component), \(row)"
            UIView.transitionWithView(view, duration: 0.2, options: .TransitionCrossDissolve, animations: {
                actived ? (view.textColor = UIColor.redColor()) : (view.textColor = UIColor.lightGrayColor())
                componentActived ? (view.alpha = 1) : (view.alpha = rowActived ? 1 : 0.2)
                
            }, completion: nil)
            
            return view
        } else {
            let v = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            v.text = "\(component), \(row)"
            v.backgroundColor = UIColor.whiteColor()
            v.textAlignment = .Center
            actived ? (v.textColor = UIColor.redColor()) : (v.textColor = UIColor.lightGrayColor())
            componentActived ? (v.alpha = 1) : (v.alpha = rowActived ? 1 : 0.2)
            
            return v
        }
    }
}

extension ViewController: PickerViewDelegate {
    func pickerView(pickerView: PickerView, didSelectRow row: Int, inComponent component: Int) {
            label.text = "\(component) - \(row)"
    }
}

