//
//  HomeViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 8/13/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class HomeViewController: UITabBarController
    ,UITabBarControllerDelegate
    ,UIPopoverPresentationControllerDelegate
    {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    let searchOpenAyaNotification = NSNotification.Name(rawValue: "searchOpenAya")

    override func viewWillAppear(_ animated: Bool) {
        //Show Navigation bar
        navigationController?.navigationBar.isHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        print("HomeViewController Appear")
        NotificationCenter.default.addObserver(
           self,
           selector: #selector(searchOpenAya),
           name: searchOpenAyaNotification,
           object: nil
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        print("HomeViewController willDisappear")
        NotificationCenter.default.removeObserver(self)
    }

    @objc func searchOpenAya(vc: SearchViewController){
        print("HomeViewController.searchOpenAya( \(SelectStart) )")
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
            print (title)
        }
    }
    
    @IBAction func openSearch(_ sender: UIBarButtonItem) {
        //let search = UISearchController()
    }
    
    @IBAction func openActions(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let login = UIAlertAction(title: "Login", style: .default) { (action) in
            print(action)
        }
        let changeLanguage = UIAlertAction(title: "Change Language", style: .default) { (action) in
            print(action)
        }

        let close = UIAlertAction(title: "Close", style: .cancel) { (action) in
            print(action)
        }

        alert.addAction(login)
        alert.addAction(changeLanguage)
        alert.addAction(close)
        self.present(alert, animated: true) {
            print( "Alert Show animation completed" )
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



