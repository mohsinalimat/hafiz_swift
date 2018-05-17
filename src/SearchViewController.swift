//
//  SearchViewController.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 2/3/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit

var SearchText = ""

class SearchViewController:
    UIViewController,
    UISearchBarDelegate,
    UITableViewDelegate,
    UITableViewDataSource
{

    var searchText: String?
    var results : [Int]?
    var history: [String]?
    
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var historyTable: UITableView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        searchBar.becomeFirstResponder();
        //searchBar.delegate = self //storyboard takes care of that
        self.history = UserDefaults.standard.array(forKey: "search_history") as? [String] ?? [
            "محمد",
            "نوح",
            "ادريس",
            "ابراهيم",
            "اسماعيل",
            "اسحاق",
            "يعقوب",
            "يوسف",
            "موسى",
            "هارون",
            "عيسى",
            "ايوب",
            "داوود",
            "سليمان"
        ]
    }

    @IBAction func onTapOutsideResults(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - SearchBarDelegates methods
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if  let searchText = searchBar.text,
            searchText.count > 0
        {
            if let results = self.results, results.count == 0{
                // no results, check page numbers
                if let pageNumber = Int(searchText){
                    if pageNumber>0 && pageNumber<=QData.lastPageIndex{
                        let aya = QData.instance.ayaPosition(pageIndex: pageNumber-1)
                        SelectStart = aya
                        SelectEnd = aya
                        dismiss(animated: true, completion: nil)
                        NotificationCenter.default.post(
                            name: AppNotifications.searchOpenAya,
                            object: self
                        )
                    }
                }
                return
            }
            
            SearchText = searchText

            dismiss(animated: true, completion: nil)

            NotificationCenter.default.post(
                name: AppNotifications.searchViewResults,
                object: self
            )
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        self.searchText = searchText
        let qData = QData.instance
        
        self.results = qData.searchQuran(searchText, max: 10)
        
        searchResultsTable.reloadData()
        historyTable.isHidden = searchText.count>0 ? true:false
    }
    
    // MARK: - UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let id = tableView.restorationIdentifier {
            if id == "SResults"{
                if let results = self.results{
                    return results.count
                }
            }
            else if id == "History", let history = self.history {
                return history.count
            }
        }
        return 0 // no history nor search results
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let table_id = tableView.restorationIdentifier ?? "SResults"
        let cell_id = "\(table_id)Cell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cell_id, for: indexPath)
        
        if table_id == "SResults"{
            let qData = QData.instance
            if let results = self.results {
                let ayaPosition = results[indexPath.row]
                
                if let textLabel = cell.textLabel{
                    if ayaPosition < 0 {
                        let suraNumber = -ayaPosition
                        let suraName = qData.suraName( suraIndex: suraNumber-1 )
                        let name = suraName?.name ?? "missing"
                        textLabel.text = String(format:NSLocalizedString("SuraName", comment: ""),name)
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
        }
        else if table_id == "History" {
            if let history = self.history{
                cell.textLabel?.text = history[indexPath.row]
            }
        }
        
        return cell
    }

    // MARK: - UITableViewDelegate methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let table_id = tableView.restorationIdentifier ?? "unknown"
        let row = indexPath.row
        
        if table_id == "SResults", let results = self.results{
            var aya = results[row]
            if aya < 0 {
                let qData = QData.instance
                let suraIndex = -aya-1
                aya = qData.ayaPosition(sura: suraIndex, aya: 0)
            }
            SelectStart = aya
            SelectEnd = aya
            dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(
                name: AppNotifications.searchOpenAya,
                object: self
            )
            
            Utils.addToSearchHistory(searchBar.text ?? "") // as user opens a result, we save that search

        }else if table_id == "History", let history = self.history{
            searchBar.text = history[row]
            self.searchBar(self.searchBar, textDidChange: history[row])
        }
    }
   

}
