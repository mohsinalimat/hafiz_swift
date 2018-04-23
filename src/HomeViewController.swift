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
        //navigationController?.navigationBar.topItem?.title = tabBar.selectedItem?.title
    }
    
    let searchOpenAyaNotification = NSNotification.Name(rawValue: "searchOpenAya")

    override func viewWillAppear(_ animated: Bool) {
        //Show Navigation bar
        navigationController?.navigationBar.isHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        //print("HomeViewController Appear")
        NotificationCenter.default.addObserver(
           self,
           selector: #selector(searchOpenAya),
           name: searchOpenAyaNotification,
           object: nil
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        //print("HomeViewController willDisappear")
        NotificationCenter.default.removeObserver(self)
    }

    @objc func searchOpenAya(vc: SearchViewController){
        //print("HomeViewController.searchOpenAya( \(SelectStart) )")
        self.performSegue(withIdentifier: "OpenPagesBrowser", sender: self)
        //self.navigationController?.pushViewController(QPagesBrowser(), animated: true)
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
        
        //TODO: change the title according to signin status
        var login:UIAlertAction?
        if let _ = Auth.auth().currentUser {
            login = UIAlertAction(title: "Sign Out", style: .default) { (action) in
                GIDSignIn.sharedInstance().signOut()
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "OpenPagesBrowser" {
            if let vc = segue.destination as? QPagesBrowser{
                let qData = QData.instance()
                vc.startingPage = qData.pageIndex(ayaPosition: SelectStart) + 1
            }
        }
    }
    
}



