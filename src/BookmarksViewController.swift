
//
//  BookmarksViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 4/22/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit

class BookmarksViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = .blue
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
        return 30
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Bookmark", for: indexPath)

        // Configure the cell...
        let rowIndex = indexPath.row
        cell.textLabel!.text = String(format:NSLocalizedString("Part", comment:""),rowIndex+1)

        let qData = QData.instance()
        let pageNum = qData.pageIndex( partIndex: rowIndex ) + 1
        let suraNum = qData.suraIndex( partIndex: rowIndex ) + 1
        let suraName = qData.suraName( suraIndex: suraNum-1)
        let partDetails = String(format:NSLocalizedString("PartInfo", comment: ""), pageNum, suraNum, suraName!)
        cell.detailTextLabel!.text = partDetails
        cell.tag = pageNum //for segue use
        
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
