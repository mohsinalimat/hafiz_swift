//
//  SearchViewController.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 2/3/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    var searchText: String?
    @IBOutlet weak var searchResultsTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        searchBar.becomeFirstResponder();
        searchBar.delegate = self
    }
    

    @IBOutlet weak var searchBar: UISearchBar!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTabOutsideSearchbar(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        
        searchResultsTable.reloadData()
    }

    // MARK: - TableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let searchText = self.searchText{
            return searchText.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SResult Item", for: indexPath)

        if let textLabel = cell.textLabel{
            textLabel.text = "Result Item \(indexPath.row)"
            if let searchText = self.searchText {
                if searchText.count > 0{
                    textLabel.text = searchText
                }
            }
        }
        
        return cell
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
