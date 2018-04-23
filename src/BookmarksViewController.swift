
//
//  BookmarksViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 4/22/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit

class BookmarksViewController: UITableViewController {

    var pageMarks:[Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = .blue
        QData.bookmarks({(list) in
            if let pageMarks = list {
                self.pageMarks = pageMarks.allKeys//TODO: preserve the sorting, collect keys using enumerated()
                self.tableView.reloadData()
            }
        })
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source delegates

    override func numberOfSections(in tableView: UITableView) -> Int {
        //return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return the number of rows (Quran parts)
        if let pageMarks = self.pageMarks{
            return pageMarks.count
        }
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let qData = QData.instance()
        let cell = tableView.dequeueReusableCell(withIdentifier: "Bookmark", for: indexPath)
        let rowIndex = indexPath.row
        if let pageMarks = self.pageMarks{
            let pageIndex = Int(pageMarks[rowIndex] as! String)!
            let suraIndex = qData.suraIndex(pageIndex: pageIndex)
            let suraName = qData.suraName(suraIndex: suraIndex)!
            cell.textLabel!.text = suraName
            cell.detailTextLabel!.text = String(format:NSLocalizedString("PartInfo", comment: ""), pageIndex+1, suraIndex+1, suraName)
            cell.tag = pageIndex + 1 //for segue use
        }
        
        return cell
    }
    
    // MARK: - Navigation

    override
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let qPagesBrowser = segue.destination as! QPagesBrowser
        if let viewCell = sender as? UITableViewCell {
            qPagesBrowser.startingPage = viewCell.tag
        }
        
    }

}
