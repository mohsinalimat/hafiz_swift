//
//  AppDelegate.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    var window: UIWindow?
    
    static var orientation:UIInterfaceOrientationMask = .all

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        
        return true
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                         sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                         annotation: [:])
    }
    
    //for ios 8 or older
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                         sourceApplication: sourceApplication,
                         annotation: annotation)
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    //Invoked so many times
    //Not invoked upon calling UIViewController.attemptRotationToDeviceOrientation() !!!!!
    //or UIDevice.current.setValue(AppDelegate.orientation.rawValue, forKey: "orientation") !!!
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        //return AppDelegate.orientation
        return .all
    }

    //MARK: - Google Sign In delegate methods
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            // ...
            print( "AppDelegate Google Failed to sign in :(" )
            print( error )
            return
        }

        print( "AppDelegate Google signed in :)" )

        guard let authentication = user.authentication else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)

        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print("AppDelegate Firebase Failed to sign in :(")
                print(error)
                return
            }
            print( "AppDelegate Firebase signed in :)" )
            
            if let hifzRef = QData.userData("hifz"){
                hifzRef.observe(.childAdded, with: self.notifyDataChanged )
                hifzRef.observe(.childRemoved, with: self.notifyDataChanged )
                hifzRef.observe(.childChanged, with: self.notifyDataChanged )
            }

            if let pageMarks = QData.userData("page_marks"){
                pageMarks.observe(.childAdded, with: self.notifyDataChanged )
                pageMarks.observe(.childRemoved, with: self.notifyDataChanged )
                pageMarks.observe(.childChanged, with: self.notifyDataChanged )
            }

            NotificationCenter.default.post(name: AppNotifications.signedIn, object: user)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        if let error = error {
            print( "AppDelegate Failed to sign out" )
            print( error )
            return
        }

        print( "AppDelegate Signed out" )

        NotificationCenter.default.post(name: AppNotifications.signedIn, object: user)
        NotificationCenter.default.post(name: AppNotifications.dataUpdated, object: user)

        // User is signed out
        // broadcast a notification to refresh the data
    }

    @objc func notifyDataChanged(snapshot:DataSnapshot)->Void{
        NotificationCenter.default.post(
            name: AppNotifications.dataUpdated, object: snapshot
        )
    }

}

struct AppNotifications {
    static var searchOpenAya: NSNotification.Name { return NSNotification.Name(rawValue: "searchOpenAya") }
    static var searchViewResults: NSNotification.Name { return NSNotification.Name(rawValue: "searchViewResults") }
    static var dataUpdated: NSNotification.Name { return NSNotification.Name(rawValue: "dataUpdated") }
    static var signedIn: NSNotification.Name { return NSNotification.Name(rawValue: "signedIn") }
}

