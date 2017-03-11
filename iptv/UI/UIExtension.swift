//
//  UIExtension.swift
//  iptv
//
//  Created by Alexandr Kolganov on 02.11.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class UICommonString {
    static let programNotFound = "TV-program not found"
}

extension UIFont {
    
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits)) {
            return UIFont(descriptor: descriptor, size: 0)
        }
        return self
    }
    
    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
    
    func boldItalic() -> UIFont {
        return withTraits(traits: .traitBold, .traitItalic)
    }
    
    func regular() -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: 0))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    
}



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
    
    func setSureHidden(_ isHidden: Bool) {
        var attempts = 0
        while self.isHidden != isHidden {
            self.isHidden = isHidden
            attempts += 1
            if attempts >= 100 {
                break
            }
        }
        if attempts > 1 {
            print("setSureHidden::attempts:\(attempts)")
        }
    }
    
    //focused/unfocused
    
    enum FocusedChangeState {
        case focused, unFocused, noChange
    }

    func focusedChange(_ context:UIFocusUpdateContext) -> FocusedChangeState {
        if  let prevView = context.nextFocusedView,
            let nextView = context.previouslyFocusedView
        {
            
            let isPrev = prevView.isDescendant(of: self)
            let isNext = nextView.isDescendant(of: self)
            
            if(isNext && !isPrev) {
                return FocusedChangeState.focused;
            }
            if(!isNext && isPrev) {
                return FocusedChangeState.unFocused;
            }
        }
        return FocusedChangeState.noChange;
    }

}

extension UIViewController { //add/remove child  controller
    
    func containerAdd(childViewController:UIViewController, toView:UIView) {
        self.addChildViewController(childViewController)
        toView.addSubviewWithSomeSize(childViewController.view)
        childViewController.didMove(toParentViewController: self)
    }
    
    func containerRemove(childViewController:UIViewController) {
        childViewController.willMove(toParentViewController: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParentViewController()
    }
    
    func containerReplace(fromController:UIViewController, toController:UIViewController, inView:UIView) {
        fromController.willMove(toParentViewController: nil)
        self.addChildViewController(toController)
        toController.view.frame = fromController.view.frame
        
        //transfer from top to bottom
        self.transition(from: fromController, to: toController, duration: 0.25, options: .transitionCrossDissolve, animations: {},
            completion:{ (finished) in
                fromController.removeFromParentViewController()
                toController.didMove(toParentViewController: self)
            }
        )
    }
    
    //if controller into navigation controller then title add to title of previous controller
    func addNavigationTitle(_ title:String) {
        guard let viewControllers = self.navigationController?.viewControllers,
            viewControllers.count >= 2,
            viewControllers[viewControllers.count - 2].title != nil
        
        else {
            self.title = title
            return
        }
        self.title = viewControllers[viewControllers.count - 2].title!  + "/" + title
    }
}

extension UIViewController { //simple alert actions

    func simpleAlert(title: String, message: String, buttonTitle: String, completion: (() -> Swift.Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: completion)
    }
    
    func simpleAlertOk(title: String, message: String, completion: (() -> Swift.Void)? = nil) {
        simpleAlert(title: title, message: message, buttonTitle: "Ok", completion: completion)
    }

    
    func simpleAlertChooser(title: String, message: String, buttonTitles: [String], prefferButton:Int = 0, completion: @escaping ((Int) -> Swift.Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for i in 0..<buttonTitles.count {
            
            let action = UIAlertAction(title: buttonTitles[i], style:  .default, handler: { (_) in
                    completion(i)
            })
            alertController.addAction(action)
            if i == prefferButton { //add hidden cancel action for exit by menu button
                alertController.preferredAction = action
                let cancelAction = UIAlertAction(title: nil, style:  .cancel, handler: { (_) in
                    completion(i)
                })
                alertController.addAction(cancelAction)
            }
        }
        
        //add alert cancel
        self.present(alertController, animated: true, completion: nil)
    }

}

extension UIButton {
    func setTitleForAllStates(_ title: String) {
        self.setTitle(title, for: .normal)
        self.setTitle(title, for: .focused)
        self.setTitle(title, for: .selected)
    }
    
    func setImageForAllStates(_ image: UIImage) {
        self.setImage(image, for: .normal)
        self.setImage(image, for: .focused)
        self.setImage(image, for: .selected)
    }
}


extension UITextView {
    override open func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if (context.nextFocusedView == self) {
            self.backgroundColor = UIColor.white
        }
        else {
            self.backgroundColor = UIColor.clear
        }
    }
    
}

