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
        
        updateSignInButtonTitle()
        
        //let blankImage = UIImage()
        //navigationController?.navigationBar.setBackgroundImage(blankImage, for: .default)
        //navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    @objc func updateSignInButtonTitle()
    {
        signInBarButton.title = QData.signedIn ? "Sign Out" : "Sign In"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Show Navigation bar
        //navigationController?.navigationBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: true)
        updateSignInButtonTitle()
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSignInButtonTitle),
            name: AppNotifications.signedIn,
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

    @IBOutlet weak var signInBarButton: UIBarButtonItem!
    
    @IBAction func signInButtonClicked(_ sender: UIBarButtonItem) {
        if QData.signedIn {
            QData.signOut(self)
        }else{
            QData.signIn(self)
        }
        updateSignInButtonTitle()
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
            QData.signOut(self)
            break
        case .signIn:
            QData.signIn(self)
            break
        case .changeLang:
            self.showAlertActions([
                alertAction(.arabic, "عربي", "ar"),
                alertAction(.english, "English", "en")
                ],
                "Select Language"
            )
            break
        case .shareTheApp:
            QData.publicDataValue("appstore"){ val in
                if let appstore = val {
                    let activityViewController = UIActivityViewController(
                        activityItems: ["Try out this App",appstore],
                        applicationActivities: nil
                    )
                    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                    self.present(activityViewController, animated: true, completion: nil)
                }
            }
            break
        case .arabic, .english:
            if let langCode = selection as? String{
                Utils.confirmMessage(
                    self,
                    "App Restart Required",
                    "In order to change the language, the App must be closed and reopened",
                    .yes )
                {
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
        let actions = [
            alertAction(.changeLang, "Change Language"),
            alertAction(.shareTheApp, "Share this App")
        ]
        
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



