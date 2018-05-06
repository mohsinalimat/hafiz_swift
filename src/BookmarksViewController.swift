
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
        loadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.signedIn, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.dataUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onRefresh(){
        loadData(sync:true)
    }

    @objc func onDataUpdated(){
        loadData(sync: false)
    }

    func loadData(sync: Bool = false){
        
        QData.bookmarks(sync:sync){(list) in
            if let pageMarks = list {
                self.pageMarks = []
                for page in pageMarks{
                    self.pageMarks!.append(page)
                }
                self.tableView.reloadData()
                self.tableView.refreshControl!.endRefreshing()
            }
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = .blue
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
    
    // Return right swipe edit actions
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        return [
            UITableViewRowAction(style: .destructive, title: "Remove", handler: {
                (rowAction, indexPath) in
                
                if let page = self.pageMarks?.remove(at: indexPath.row){
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    let _ = QData.deleteBookmark(page: page){(snapshot) in
                        print( "Bookmark deleted")
                    }//dataUpdated event will refresh the table
                }
            })
        ]
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
