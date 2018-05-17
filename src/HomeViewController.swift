//
//  HomeViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 8/13/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UITabBarController
    ,UITabBarControllerDelegate
    ,UIPopoverPresentationControllerDelegate
    ,UIActionAlertsManager
{
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSignInButtonTitle()
        
        //let blankImage = UIImage()
        //navigationController?.navigationBar.setBackgroundImage(blankImage, for: .default)
        //navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    @objc func updateSignInButtonTitle()
    {
        signInBarButton.image = UIImage(named: QData.signedIn ? "logout" : "login")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Show Navigation bar
        Utils.showNavBar(self)
        updateSignInButtonTitle()

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

    override func viewDidAppear(_ animated: Bool) {
        //print("HomeViewController Appear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        //print("HomeViewController willDisappear")
        NotificationCenter.default.removeObserver(self)
    }

    @objc func searchOpenAya(vc: SearchViewController){
        self.performSegue(withIdentifier: "ShowPage", sender: self)
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
                AStr.selectLanguage
            )
            break
        case .rateApp:
            QData.publicDataValue("rate_url"){ val in
                if let appURL = val {
                    if let url = URL(string: appURL){
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
            break
        case .shareTheApp:
            QData.publicDataValue("appstore"){ val in
                if let appstore = val {
                    let activityViewController = UIActivityViewController(
                        activityItems: [AStr.tryOutThisApp,appstore],
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
                    AStr.appRestartRequired,
                    AStr.appRestartRequiredDesc,
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
            alertAction(.changeLang, AStr.changeLanguage),
            alertAction(.shareTheApp, AStr.shareQuranHafiz),
            alertAction(.rateApp, AStr.rateQuranHafiz)
        ]
        
        self.showAlertActions(actions)
    }

}



