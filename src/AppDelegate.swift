//
//  AppDelegate.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
import Firebase
//import GoogleSignIn
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI
//import FirebaseTwitterAuthUI
//import TwitterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FUIAuthDelegate {
    
    var window: UIWindow?
    
    static var orientation:UIInterfaceOrientationMask = .all

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()

//        TWTRTwitter.sharedInstance().start(
//            withConsumerKey:"dtEp4yNEwFPLiAFp7quhK9WRo",
//            consumerSecret:"xxxxx"
//        )
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user{
                print ("FIR: Auth: User is \(user.uid)")
                self.handleSignedIn()
            }else{
                self.handleSignedOut()
                print("FIR: Auth: User is out")
            }
        }

        if let authUI = FUIAuth.defaultAuthUI(){
            authUI.delegate = self
            authUI.providers = [
                FUIGoogleAuth()
                ,FUIFacebookAuth()
                //,FUITwitterAuth()
                //,FUIPhoneAuth(authUI:FUIAuth.defaultAuthUI()),
            ]
        }

        Database.database().isPersistenceEnabled = true
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool
    {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String?
        
        print("FIR: open url \(url.absoluteString) from \(sourceApplication!) options: \(options)")

        if let authUI = FUIAuth.defaultAuthUI(){
            
            if authUI.handleOpen(url, sourceApplication: sourceApplication) {
                return true
            }
        
        }
        // other URL handling goes here.
        return false
    }


    //MARK: - FireUIAuth In delegate methods

    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        // handle user and error as necessary
        if let error = error {
            // ...
            print( "AppDelegate FUIAuth Failed to sign in :(" )
            print( error )
            return
        }
        
        print( "AppDelegate FUIAuth signed in :)" )
//      NotificationCenter.default.post(name: AppNotifications.signedIn, object: user)
    }
    
    func handleSignedIn(){
        if let hifzRef = QData.userData("hifz"){
            hifzRef.observe(.childAdded, with: self.notifyDataChanged )
            hifzRef.observe(.childRemoved, with: self.notifyDataChanged )
            hifzRef.observe(.childChanged, with: self.notifyDataChanged )
        }

        if let pageMarks = QData.userData("aya_marks"){
            pageMarks.observe(.childAdded, with: self.notifyDataChanged )
            pageMarks.observe(.childRemoved, with: self.notifyDataChanged )
            pageMarks.observe(.childChanged, with: self.notifyDataChanged )
        }

        NotificationCenter.default.post(name: AppNotifications.signedIn, object: nil)
        NotificationCenter.default.post(name: AppNotifications.dataUpdated, object: nil)
    }
    
    func handleSignedOut(){
        NotificationCenter.default.post(name: AppNotifications.dataUpdated, object: nil)
        NotificationCenter.default.post(name: AppNotifications.signedIn, object: nil)
    }

    @objc func notifyDataChanged(snapshot:DataSnapshot)->Void{
        print("FIR: data changed \(snapshot.key)")
        NotificationCenter.default.post(
            name: AppNotifications.dataUpdated, object: snapshot
        )
    }

    //MARK: - Orientation delegates
    
    //Invoked so many times
    //Not invoked upon calling UIViewController.attemptRotationToDeviceOrientation() !!!!!
    //or UIDevice.current.setValue(AppDelegate.orientation.rawValue, forKey: "orientation") !!!
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        //return AppDelegate.orientation
        return .all
    }

}

struct AppNotifications {
    static var searchOpenAya: NSNotification.Name { return NSNotification.Name(rawValue: "searchOpenAya") }
    static var searchViewResults: NSNotification.Name { return NSNotification.Name(rawValue: "searchViewResults") }
    static var dataUpdated: NSNotification.Name { return NSNotification.Name(rawValue: "dataUpdated") }
    static var signedIn: NSNotification.Name { return NSNotification.Name(rawValue: "signedIn") }
    static var pageViewed: NSNotification.Name { return NSNotification.Name(rawValue: "signedIn") }
}

