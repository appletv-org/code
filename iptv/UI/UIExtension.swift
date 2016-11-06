//
//  UIExtension.swift
//  iptv
//
//  Created by Alexandr Kolganov on 02.11.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

//------ childViewController ---------


extension UIView {
    
    func addSubviewWithSomeSize(_ subView: UIView) {
        
        //set frame
        subView.frame = CGRect.init(origin: CGPoint(x:0, y:0), size: self.frame.size)
        
        //set constrains
        self.addSubview(subView)
        var viewBindingsDict = [String: AnyObject]()
        viewBindingsDict["subView"] = subView
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[subView]|",
                                                                                 options: [], metrics: nil, views: viewBindingsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subView]|",                                                                                 options: [], metrics: nil, views: viewBindingsDict))
    }
    
    func findFirstInDeep(where predicate: (UIView) -> Bool) -> UIView? {
        for view in self.subviews {
            if predicate(view) {
                return view
            }
            else {
                let deepFind = view.findFirstInDeep(where: predicate)
                if deepFind != nil {
                    return deepFind
                }
            }
        }
        return nil
    }
}

extension UIViewController {
    
    func containerAdd(childViewController:UIViewController, toView:UIView) {
        self.addChildViewController(childViewController)
        //childViewController.view.frame = CGRect.init(origin: CGPoint(x:0, y:0), size: toView.frame.size)
        toView.addSubviewWithSomeSize(childViewController.view)
        childViewController.didMove(toParentViewController: self)
    }
    
    func containerRemove(childViewController:UIViewController) {
        self.willMove(toParentViewController: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParentViewController()
    }
}

