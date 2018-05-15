
//
//  BookmarksViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 4/22/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit
import GoogleSignIn

class BookmarksViewController: UITableViewController {

    var ayaMarks:[Int]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        readData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onSignInUpdate), name: AppNotifications.signedIn, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.dataUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onSignInUpdate(){
        if QData.signedIn{
            readData()
        }else{
            self.ayaMarks = nil
            setNoDataView(signInReqView)
            tableView.reloadData()
        }
    }

    @objc func onRefresh(){
        if !QData.signedIn{
            self.tableView.refreshControl!.endRefreshing()
            return
        }
        readData(sync:true)
    }

    @objc func onDataUpdated(){
        readData(sync: false)
    }

    func readData(sync: Bool = false){
        if QData.signedIn {
            setNoDataView(nil)

            let _ = QData.bookmarks(sync:sync){ (list) in
                if let ayaMarks = list {
                    self.ayaMarks = []
                    for ayaPos in ayaMarks{
                        self.ayaMarks!.append(ayaPos)
                    }
                    self.tableView.reloadData()
                    self.tableView.refreshControl!.endRefreshing()
                }
            }
        }else{
            setNoDataView( signInReqView )
        }
    }
    
    func setNoDataView(_ vw: UIView? ){
        tableView.backgroundView = vw
        tableView.separatorStyle = vw == nil ? .singleLine : .none
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = UIColor.darkGray
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet var noDataView: UIView!
    @IBOutlet var signInReqView: UIView!
    @IBAction func signInClicked(_ sender: Any) {
        QData.signIn(self)
    }
    

    // MARK: - Table view data source delegates

    override func numberOfSections(in tableView: UITableView) -> Int {
        //return the number of sections
        if let pageMarks = self.ayaMarks {
            setNoDataView( pageMarks.count == 0 ? noDataView:nil)
            return pageMarks.count == 0 ? 0 : 1
        }
        return QData.signedIn ? 1 : 0
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let pageMarks = self.ayaMarks{
            return pageMarks.count
        }

        return QData.signedIn ? 1:0 //to show loading
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let qData = QData.instance
        let rowIndex = indexPath.row
        
        if  let ayaMarks = self.ayaMarks,
            let cell = tableView.dequeueReusableCell(withIdentifier: "Bookmark", for: indexPath) as? BookmarkTableCellView
        {
            let ayaPos = ayaMarks[rowIndex]
            let (sura,aya) = qData.ayaLocation(ayaPos)
            let suraName = qData.suraName(suraIndex: sura)
            let pageNumber = qData.pageIndex(ayaPosition: ayaPos)+1
            cell.suraName.text = suraName?.name ?? "missing"
            cell.pageNumber.text = "\(pageNumber)"
            cell.ayaLocation.text = "(\(aya+1))"
            if let ayaText = qData.ayaText(ayaPosition: ayaPos){
                cell.ayaText.text = ayaText
            }
            cell.tag = ayaPos //for segue use
            return cell
        }
        
        let loadingCell = tableView.dequeueReusableCell(withIdentifier: "Loading", for: indexPath)
        loadingCell.textLabel!.text = "Loading..."
        return loadingCell
    }
    
    // Return right swipe edit actions
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        return [
            UITableViewRowAction(style: .destructive, title: "Remove", handler: {
                (rowAction, indexPath) in
                
                if let ayaPos = self.ayaMarks?.remove(at: indexPath.row){
                    let _ = QData.deleteBookmark(aya: ayaPos){(snapshot) in
                        //tableView.deleteRows(at: [indexPath], with: .fade)
                        print( "Bookmark deleted")
                    }//dataUpdated event will refresh the table
                }
            })
        ]
    }
    
    // MARK: - Navigation

    override
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //let qPagesBrowser = segue.destination as! QPagesBrowser
        if let viewCell = sender as? UITableViewCell {
            SelectStart = viewCell.tag
            SelectEnd = SelectStart
        }
    }

}

class BookmarkTableCellView : UITableViewCell{
    @IBOutlet weak var suraName: UILabel!
    @IBOutlet weak var ayaLocation: UILabel!
    @IBOutlet weak var ayaText: UILabel!
    @IBOutlet weak var pageNumber: UILabel!
    
}
