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
        Utils.showNavBar(self)
        //navigationController?.setNavigationBarHidden(false, animated: true)
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
    
    @objc func searchOpenAya(vc: SearchViewController){
        //Remove existing QPageBrowser from stack
        navigationController?.removeQPageBrowser()
        self.performSegue(withIdentifier: "OpenPagesBrowser", sender: self)//
    }

    @objc func searchViewResults(vc: SearchViewController){
        //re-run the search
        doSearch()
    }

    func doSearch(){

        let qData = QData.instance
        
        self.results = qData.searchQuran(SearchText, max: 1000)

        Utils.addToSearchHistory(SearchText, results.count)
        
        let plus = results.count >= 1000 ? "+" : ""

        resultsDescription.text = AStr.nResultsForS(ns: "\(results.count)\(plus)", s: SearchText)

        searchResultsTable.reloadData()
        searchResultsTable.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
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
        let qData = QData.instance
        let rowIndex = indexPath.row
        if self.results.count > rowIndex {
            let ayaPosition = results[rowIndex]
            
            if let textLabel = cell.textLabel{
                if ayaPosition < 0 {// This is suraNumber in negative
                    let suraNumber = -ayaPosition
                    let suraName = qData.suraName( suraIndex: suraNumber-1 )
                    let name = suraName?.name ?? "missing"
                    textLabel.text = AStr.suraName(s: name)
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
                        textDetails.text = qData.suraName(suraIndex:suraIndex)!.name + ": " +  String(ayaIndex+1)
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
        
        if let _ = segue.destination as? QPagesBrowser{
            navigationController?.removeQPageBrowser()
//            let qData = QData.instance
//            vc.startingPage = qData.pageIndex(ayaPosition: SelectStart) + 1
        }

    }
    

}
