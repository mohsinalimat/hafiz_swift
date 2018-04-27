
//
//  BookmarksViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 4/22/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit

class BookmarksViewController: UITableViewController {

    var pageMarks:[Int]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
    }
    
    @objc func onRefresh(){
        QData.bookmarks({(list) in
            if let pageMarks = list {
                self.pageMarks = []
                for page in pageMarks{
                    self.pageMarks!.append(page)
                }
                self.tableView.reloadData()
                self.tableView.refreshControl!.endRefreshing()
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = .blue
        onRefresh()
//        QData.bookmarks({(list) in
//            if let pageMarks = list {
//                self.pageMarks = []
//                for page in pageMarks{
//                    self.pageMarks!.append(page)
//                }
//                self.tableView.reloadData()
//            }
//        })
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source delegates

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let pageMarks = self.pageMarks{
            return pageMarks.count
        }
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let qData = QData.instance()
        let cell = tableView.dequeueReusableCell(withIdentifier: "Bookmark", for: indexPath)
        let rowIndex = indexPath.row
        if let pageMarks = self.pageMarks{
            let pageIndex = pageMarks[rowIndex]
            let suraIndex = qData.suraIndex(pageIndex: pageIndex)
            let suraName = qData.suraName(suraIndex: suraIndex)!
            cell.textLabel!.text = suraName
            cell.detailTextLabel!.text = String(format:NSLocalizedString("PartInfo", comment: ""), pageIndex+1, suraIndex+1, suraName)
            cell.tag = pageIndex + 1 //for segue use
        }else{
            cell.textLabel!.text = "Loading..."
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
