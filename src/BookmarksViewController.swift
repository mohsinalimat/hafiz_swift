
//
//  BookmarksViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 4/22/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit
//import GoogleSignIn

class BookmarksViewController: UITableViewController {

    enum NoDataStates{
        case normal,notSignedIn,noData
    }
    
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

        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: AppNotifications.pageViewed, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onSignInUpdate(){
        if QData.signedIn{
            readData()
        }else{
            self.ayaMarks = nil
            setNoDataView(.notSignedIn)
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
    
    @objc func reloadTableData(){
        tableView.reloadData()
    }

    func readData(sync: Bool = false){
        if QData.signedIn {
            let _ = QData.bookmarks(sync:sync){ (list) in
                if let ayaMarks = list {
                    self.ayaMarks = []
                    for ayaPos in ayaMarks{
                        self.ayaMarks!.append(ayaPos)
                    }
                    self.setNoDataView( ayaMarks.count>0 ? .normal : .noData )
                    self.tableView.reloadData()
                    self.tableView.refreshControl!.endRefreshing()
                }
            }
        }else{
            setNoDataView( .notSignedIn )
        }
    }
    
    func setNoDataView(_ state: NoDataStates ){
        switch state{
        case .normal:
            tableView.backgroundView = nil
            break
        case .noData:
            tableView.backgroundView = noDataView
            break
        case .notSignedIn:
            tableView.backgroundView = signInReqView
            break
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = UIColor.darkGray
        tableView.reloadData()
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
//        if let pageMarks = self.ayaMarks {
//            setNoDataView( pageMarks.count == 0 ? noDataView:nil)
//            return pageMarks.count == 0 ? 0 : 1
//        }
        return QData.signedIn ? 2 : 1
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1{
            if let pageMarks = self.ayaMarks{
                return pageMarks.count
            }
            //empty table or not signed in
            return 0 
        }
        let hist = UserDefaults.standard.array(forKey: "nav_history") as? [Int] ?? []
        return hist.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return AStr.lastViewed
        }
        return AStr.bookmarks
    }

    override
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        let menuItems = [
            UIMenuItem(title: AStr.tafseer, action: #selector(BookmarkTableCellView.tafseer)),
            UIMenuItem(title: AStr.revise, action: #selector(BookmarkTableCellView.revise))
        ]
        
        UIMenuController.shared.menuItems = menuItems
        return true
    }
    
    override
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true // never called
    }
    
    override
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        return // never called
    }

    override
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = AppColors.silverBg
        if let header = view as? UITableViewHeaderFooterView{
            header.textLabel?.textColor = AppColors.blueText
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowIndex = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "Bookmark", for: indexPath)

        if indexPath.section == 0,
            let hist = UserDefaults.standard.array(forKey: "nav_history") as? [Int]
        {
            return cellForAya(cell, hist[rowIndex], 0)
        }
        
        if  let ayaMarks = self.ayaMarks{
            return cellForAya(cell, ayaMarks[rowIndex], 1)
        }
        
        return cell
    }
    
    func cellForAya(_ cell:UITableViewCell, _ ayaPos:Int, _ section:Int )->UITableViewCell{
        
        if let cell = cell as? BookmarkTableCellView{
            let qData = QData.instance
            let (sura,aya) = qData.ayaLocation(ayaPos)
            let suraName = qData.suraName(suraIndex: sura)
            let pageNumber = qData.pageIndex(ayaPosition: ayaPos)+1
            cell.suraName.text = suraName?.name ?? "missing"
            cell.pageNumber.text = "\(pageNumber)"
            cell.ayaLocation.text = "(\(aya+1))"
            cell.aya = ayaPos
            if let ayaText = qData.ayaText(ayaPosition: ayaPos){
                cell.ayaText.text = ayaText
            }
            cell.tag = ayaPos //for segue use
            if section == 0{
                cell.icon.image = UIImage(named: "Timer")
            }
            return cell
        }
        
        return cell
    }
    
    // Return right swipe edit actions
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if indexPath.section == 1{//skip navigation history
            return [
                UITableViewRowAction(style: .destructive, title: AStr.remove, handler: {
                    (rowAction, indexPath) in
                    
                    if let ayaPos = self.ayaMarks?.remove(at: indexPath.row){
                        let _ = QData.deleteBookmark(aya: ayaPos){(snapshot) in
                            //tableView.deleteRows(at: [indexPath], with: .fade)
                            print( "Bookmark deleted" )
                        }//dataUpdated event will refresh the table
                    }
                })
            ]
        }
        return []
    }
    
    // MARK: - Navigation

    override
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //let qPagesBrowser = segue.destination as! QPagesBrowser
        if let viewCell = sender as? BookmarkTableCellView, let aya = viewCell.aya {
            //this will work for both tafseer and page view
            SelectStart = aya
            SelectEnd = SelectStart
        }
    }

}

class BookmarkTableCellView : UITableViewCell{
    @IBOutlet weak var suraName: UILabel!
    @IBOutlet weak var ayaLocation: UILabel!
    @IBOutlet weak var ayaText: UILabel!
    @IBOutlet weak var pageNumber: UILabel!
    
    @IBOutlet weak var icon: UIImageView!
    
    var aya:Int?
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(revise)
            || action == #selector(tafseer)
    }
    
    @objc func tafseer(){
        //TODO: duplicate code, move to utils
        if let vc = self.parentViewController{
            vc.navigationController?.removeTafseer()//only allow one instance in the stack
            vc.performSegue(withIdentifier: "ShowTafseer", sender: self)
        }
    }
    @objc func revise(){
        //TODO: duplicate code, move to utils
        MaskStart = aya ?? SelectStart
        if let vc = self.parentViewController{
            vc.performSegue(withIdentifier: "ShowPage", sender: self)
        }
    }
}
