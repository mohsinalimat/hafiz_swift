//
//  SearchResultsViewController.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 4/29/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource {

    @IBOutlet weak var resultsDescription: UILabel!
    @IBOutlet weak var searchResultsTable: UITableView!
    
    var results:[Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        doSearch()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        NotificationCenter.default.removeObserver(self)
    }
    
    func removeExistingPageBrowserFromStack(){
        if let navController = navigationController{
            if let ndx = navController.viewControllers.index(where: { (vc) in
                if let _ = vc as? QPagesBrowser {
                    return true
                }
                return false
            })
            {
                navController.viewControllers.remove(at: ndx)
            }
        }
    }

    @objc func searchOpenAya(vc: SearchViewController){
        //Remove existing QPageBrowser from stack
        removeExistingPageBrowserFromStack()
        self.performSegue(withIdentifier: "OpenPagesBrowser", sender: self)//
    }

    @objc func searchViewResults(vc: SearchViewController){
        //re-run the search
        doSearch()
    }

    func doSearch(){
        resultsDescription.text = "Results for \(SearchText)"

        let qData = QData.instance()
        
        self.results = qData.searchQuran(SearchText, max: 1000)
        
        searchResultsTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TableView delegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)
        let qData = QData.instance()
        let rowIndex = indexPath.row
        if self.results.count > rowIndex {
            let ayaPosition = results[rowIndex]
            
            if let textLabel = cell.textLabel{
                if ayaPosition < 0 {// This is suraNumber in negative
                    let suraNumber = -ayaPosition
                    textLabel.text = qData.suraName( suraIndex: suraNumber-1 )
                    cell.tag = qData.ayaPosition(sura: suraNumber-1, aya: 0)
                    if let textDetails = cell.detailTextLabel {
                        textDetails.text = ""
                    }
                }
                else{
                    cell.tag = ayaPosition
                    textLabel.text = qData.ayaText(ayaPosition: ayaPosition)
                    
                    if let textDetails = cell.detailTextLabel {
                        let (suraIndex,ayaIndex) = qData.ayaLocation(ayaPosition)
                        textDetails.text = qData.suraName(suraIndex:suraIndex)! + ": " +  String(ayaIndex+1)
                    }
                }
            }
        }
        return cell
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let ayaCellView = sender as? UITableViewCell{
            SelectStart = ayaCellView.tag
            SelectEnd = SelectStart
        }
        
        if SelectStart != -1, let vc = segue.destination as? QPagesBrowser{
            removeExistingPageBrowserFromStack()
            let qData = QData.instance()
            vc.startingPage = qData.pageIndex(ayaPosition: SelectStart) + 1
        }

    }
    

}
