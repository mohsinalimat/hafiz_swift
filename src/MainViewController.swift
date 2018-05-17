//
//  MainViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 8/27/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
//import GoogleSignIn

class MainViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //GIDSignIn.sharedInstance().uiDelegate = self
        //GIDSignIn.sharedInstance().signInSilently()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override var shouldAutorotate: Bool{
//        return visibleViewController?.shouldAutorotate ?? true
//    }
//    
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
//        return visibleViewController?.supportedInterfaceOrientations ?? AppDelegate.orientation
//    }
//    
//    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
//        return .landscapeLeft
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
