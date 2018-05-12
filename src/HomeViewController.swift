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
    
    
    @IBAction func openActions(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //change the title according to signin status
        var login:UIAlertAction?
        
        if let user = Auth.auth().currentUser,let email = user.email {
            login = UIAlertAction(title: "Sign Out \(email)", style: .default) { (action) in
                GIDSignIn.sharedInstance().signOut()
                GIDSignIn.sharedInstance().disconnect()
                GIDSignIn.sharedInstance().signIn()
            }
        }else{
            login = UIAlertAction(title: "Sign In", style: .default) { (action) in
                GIDSignIn.sharedInstance().signIn()
            }
        }
        let changeLanguage = UIAlertAction(title: "Change Language", style: .default) { (action) in
            print(action)
        }

        let close = UIAlertAction(title: "Close", style: .cancel) { (action) in
            print(action)
        }

        alert.addAction(login!)
        alert.addAction(changeLanguage)
        alert.addAction(close)
        self.present(alert, animated: true) {
            print( "Alert Show animation completed" )
        }
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



