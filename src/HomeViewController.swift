//
//  HomeViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 8/13/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class HomeViewController: UITabBarController
    ,UITabBarControllerDelegate
    ,UIPopoverPresentationControllerDelegate
    ,GIDSignInDelegate
    ,GIDSignInUIDelegate
    ,UIActionAlertsManager
{
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
        //let blankImage = UIImage()
        
//        navigationController?.navigationBar.setBackgroundImage(blankImage, for: .default)
//        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Show Navigation bar
        //navigationController?.navigationBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: true)

    }

    override func viewDidAppear(_ animated: Bool) {
        //print("HomeViewController Appear")
        NotificationCenter.default.addObserver(
           self,
           selector: #selector(searchOpenAya),
           name: AppNotifications.searchOpenAya,
           object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchViewResults),
            name: AppNotifications.searchViewResults,
            object: nil
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        //print("HomeViewController willDisappear")
        NotificationCenter.default.removeObserver(self)
    }

    @objc func searchOpenAya(vc: SearchViewController){
        self.performSegue(withIdentifier: "OpenPagesBrowser", sender: self)
    }

    @objc func searchViewResults(vc: SearchViewController){
        self.performSegue(withIdentifier: "OpenSearchResults", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITabBarController delegates
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let title = item.title{
            navigationController!.navigationBar.topItem?.title = title
        }
    }
    
    // MARK: - UIActionAlertsManager delegate methods
    func handleAlertAction(_ id: AlertActions, _ selection: Any?) {
        switch id{
        case .signOut:
            GIDSignIn.sharedInstance().signOut()
            GIDSignIn.sharedInstance().disconnect()
            GIDSignIn.sharedInstance().signIn()
            break
        case .signIn:
            GIDSignIn.sharedInstance().signIn()
            break
        case .changeLang:
            self.showAlertActions([
                alertAction(.arabic, "Arabic", "ar"),
                alertAction(.english, "Enblish", "en")
                ],
                "Select Language"
            )
            break
        case .arabic, .english:
            if let langCode = selection as? String{
                Utils.confirmMessage(self, "App Restart Required", "In order to change the language, the App must be closed and reopened", .yes){
                    isYes in
                    if isYes {
                        UserDefaults.standard.set([langCode], forKey: "AppleLanguages")
                        UserDefaults.standard.synchronize()
                        exit(EXIT_SUCCESS)
                    }
                }
            }
            break
        default:
            break
        }
    }

    @IBAction func openActions(_ sender: Any) {
        var actions = [UIAlertAction]()
        
        if let user = Auth.auth().currentUser,let email = user.email {
            actions.append(alertAction(.signOut, "Sign Out \(email)"))
        }else{
            actions.append(alertAction(.signIn, "Sign In"))
        }

        actions.append(alertAction(.changeLang, "Change Language"))

        self.showAlertActions(actions)
    }

    // MARK: - GIDSignInDelegate methods
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let _ = user{
            print( "HomeViewController Signed IN!!" )
        }else{
            print( "Not Signed In" )
        }
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier! == "OpenPagesBrowser" {
//            print( "Prepare segue OpenPagesBrowser" )
//        }
//    }
    
}



