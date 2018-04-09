//
//  SearchViewController.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 2/3/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit

class SearchViewController:
    UIViewController,
    UISearchBarDelegate,
    UITableViewDelegate,
    UITableViewDataSource
{

    var searchText: String?
    var results : [Int]?
    
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        searchBar.becomeFirstResponder();
        searchBar.delegate = self
        results = []
    }

    @IBAction func onTabOutsideSearchbar(_ sender: Any) {
        //dismiss(animated: true, completion: nil)
    }

    // MARK: - SearchBarDelegates methods
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print( searchBar.text! )
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = ""
        if( searchText.count > 0 ){
            self.searchText = searchText
        }
        let qData = QData.instance()
        
        self.results = qData.searchQuran(searchText, max: 10)
        
        searchResultsTable.reloadData()
    }
    
    // MARK: - UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let results = self.results{
            return results.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SResult Item", for: indexPath)
        let qData = QData.instance()
        if let results = self.results {
            let ayaPosition = results[indexPath.row]
            cell.tag = ayaPosition
            
            if let textLabel = cell.textLabel{
                textLabel.text = qData.ayaText(ayaPosition: ayaPosition)
            }
            
            if let textDetails = cell.detailTextLabel {
                let (suraIndex,ayaIndex) = qData.ayaLocation(ayaPosition)
                textDetails.text = qData.suraName(suraIndex:suraIndex)! + ": " +  String(ayaIndex+1)
            }
        }
        
        return cell
    }

    // MARK: - UITableViewDelegate methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let results = self.results {
            let ayaPosition = results[indexPath.row]
            SelectStart = ayaPosition
            SelectEnd = ayaPosition
            dismiss(animated: false, completion: nil)
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: "searchOpenAya"),
                object: self
            )
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override
//    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        if let viewCell = sender as? UITableViewCell, let qPagesBrowser = segue.destination as? QPagesBrowser {
//            let ayaPosition = viewCell.tag, qData = QData.instance()
//
//            qPagesBrowser.startingPage = qData.pageIndex(ayaPosition: ayaPosition) + 1
//
//            SelectStart = ayaPosition
//            SelectEnd = ayaPosition
//
//            //Reset previous selections and mask
//            MaskStart = -1
//
//            //dismiss(animated: true, completion: nil)
//        }
//
//    }

}
