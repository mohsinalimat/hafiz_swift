
//
//  PartsTableViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 9/1/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit


class HifzTableViewCell : UITableViewCell {
    
    @IBOutlet weak var suraName: UILabel!
    @IBOutlet weak var rangeDescription: UILabel!
    @IBOutlet weak var lastRevision: UILabel!
    
    @IBOutlet weak var hifzChart: UIView!
    @IBOutlet weak var rangeLeading: UIView!
    @IBOutlet weak var rangeBody: UIView!
    
    var hifzRange:HifzRange?
    
    func setRange(_ hifzRange: HifzRange ){
        self.hifzRange = hifzRange
        updateRangeColor()
        updateHifzChart()
    }
    
    func updateRangeColor(){
        if let hifzRange = self.hifzRange{
            rangeBody.backgroundColor = QData.hifzColor(range: hifzRange)
        }
    }
    
    func updateHifzChart(){
        let qData = QData.instance
        
        if let hifzRange = self.hifzRange,
           let suraInfo = qData.suraInfo(hifzRange.sura)
        {
            //remove existing constraints
            hifzChart.removeConstraints( hifzChart.constraints.filter{ $0.identifier == "rangeStart" || $0.identifier == "rangeWidth" } )
            rangeLeading.removeConstraints( rangeLeading.constraints.filter{ $0.identifier == "rangeStart" } )
            rangeBody.removeConstraints( rangeBody.constraints.filter{ $0.identifier == "rangeWidth" } )
            
            let suraStartPage = CGFloat(suraInfo.page)
            let suraEndPage = CGFloat(suraInfo.endPage)
            let pagesCount = CGFloat(suraEndPage - suraStartPage + 1)

            let rangeStartMultiplier = (CGFloat(hifzRange.page) - suraStartPage)  / pagesCount
            let rangeWidthMultiplier = CGFloat(hifzRange.count) / pagesCount

            let leadingConstraint = rangeLeading.widthAnchor.constraint(equalTo: hifzChart.widthAnchor, multiplier: rangeStartMultiplier)
            let widthConstraint = rangeBody.widthAnchor.constraint(equalTo: hifzChart.widthAnchor, multiplier: rangeWidthMultiplier)
            leadingConstraint.identifier = "rangeStart"
            widthConstraint.identifier = "rangeWidth"

            NSLayoutConstraint.activate( [ leadingConstraint, widthConstraint ] )
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(reviseHifz)
            || action == #selector(readHifz)
            || action == #selector(viewHifzDetails)
    }

    @objc func reviseHifz(){
        if let vc = self.parentViewController as? HifzViewController{
            vc.performSegue(withIdentifier: "ReviseHifz", sender: self)
        }
    }

    @objc func viewHifzDetails(){
        if let vc = self.parentViewController as? HifzViewController{
            vc.performSegue(withIdentifier: "ViewHifzDetails", sender: self)
        }
    }

    @objc func readHifz(){
        if let vc = self.parentViewController as? HifzViewController{
            vc.performSegue(withIdentifier: "ReadHifz", sender: self)
        }
    }


//    @objc func dummy(sender: Any?){
//        //Utils.showMessage(nil, title: "Dummy", message: "Menu Command")
//        print ("Cell.dummy(sender) called")
//    }
}

class HifzViewController: UITableViewController {

    var hifzRanges:HifzList?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        
        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        
        //relead data upon signed In user is changed
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.signedIn, object: nil)
        
        //relead data upon data change
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.dataUpdated, object: nil)

        loadData()
        
        becomeFirstResponder()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeFirstResponder: Bool{
        get {
            return true
        }
    }
    
    @objc func dummy(){
        print("UITableView.dumm() called")
    }
    
    
    @objc func onRefresh(){
        loadData(sync: true)
    }
    
    @objc func onDataUpdated(){
        QData.hifzList(sortByAge: true, sync: true){(ranges) in
            self.hifzRanges = ranges
            self.tableView.reloadData()
        }
    }
    
    func loadData( sync:Bool = false ){
        QData.hifzList(sortByAge: true, sync: sync){(ranges) in
            self.hifzRanges = ranges
            self.tableView.reloadData()
            self.tableView.refreshControl!.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = .brown
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        //return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let hifzRanges = self.hifzRanges {
            return hifzRanges.count
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let hifzRanges = self.hifzRanges {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Hifz Cell", for: indexPath) as! HifzTableViewCell
            // Populate cell data...
            let rowIndex = indexPath.row
            let hRange = hifzRanges[rowIndex]
            let qData = QData.instance
            
            cell.suraName!.text = qData.suraName(suraIndex: hRange.sura)?.name
            cell.rangeDescription!.text = "\(hRange.count) pages from page \(hRange.page)"
            cell.lastRevision!.text = "\(Int(-hRange.age)) days"
            cell.setRange(hRange)
            return cell
        }
        
        //TODO: if not logged in, show login required message
        let loadingCell = tableView.dequeueReusableCell(withIdentifier: "Loading", for: indexPath)
        loadingCell.textLabel?.text = "Loading Hifz data..."
        return loadingCell
    }
    
    //Will be invoked upon long press to check for supported edit menus ( usually "Copy", "Paste", "Delete" )
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        //print ("shouldShowMenuForRowAt(\(indexPath.row))")
        if let cell = tableView.cellForRow(at: indexPath) as? HifzTableViewCell{
            UIMenuController.shared.menuItems =  [
                UIMenuItem(title: "Read", action: #selector(HifzTableViewCell.readHifz)),
                UIMenuItem(title: "Revise", action: #selector(HifzTableViewCell.reviseHifz)),
                UIMenuItem(title: "Details", action: #selector(HifzTableViewCell.viewHifzDetails))
            ]
            cell.updateRangeColor()
            return true
        }
        return false
    }
    
    //UIMenuController will call the cell view to check if the action is supported,
    //However, we have to override this method in the tableview in order for UIMenuController to consider showing the context menu
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool
    {
        //Never called
        return action == #selector(HifzTableViewCell.readHifz)
            || action == #selector(HifzTableViewCell.viewHifzDetails)
            || action == #selector(HifzTableViewCell.reviseHifz)
    }

    //UIMenuController will call the cell view to check if the action is supported,
    //However, we have to override this method in the tableview in order for UIMenuController to consider showing the context menu
    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?)
    {
        //Never called
        print( "I am not expected to be called" )
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? HifzTableViewCell{
            cell.updateRangeColor()
        }
    }
    
    // Return right swipe edit actions
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        return [
            UITableViewRowAction(style: .destructive, title: "Revised", handler: {
                (rowAction, indexPath) in
                
                if let hifzRange = self.hifzRanges?.remove(at: indexPath.row){
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    let _ = QData.promoteHifz(hifzRange, {(snapshot) in })//dataUpdated event will refresh the table
                }
            }),
            
            UITableViewRowAction(style: .normal, title: "Edit", handler: {
                (rowAction, indexPath) in
                if let cell = tableView.cellForRow(at: indexPath) as? HifzTableViewCell {
                    self.performSegue(withIdentifier: "ViewHifzDetails", sender: cell)
                }
            })
        ]
    }
    
//    @IBAction func onLongPressHifzTable(_ sender: UILongPressGestureRecognizer) {
//        let p = sender.location(in: tableView)
//        if  let indexPath = tableView.indexPathForRow(at: p),
//            let cell = tableView.cellForRow(at: indexPath) as? HifzTableViewCell
//        {
//            Utils.showMessage(self, title: "Long Pressed", message: cell.suraName!.text!)
//        }
//    }
    
    override
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //Segue to HifzDetailsViewController
        if let hifzDetails = segue.destination as? HifzDetailsViewController,
           let viewCell = sender as? HifzTableViewCell,
            let hifzRange = viewCell.hifzRange
        {
            hifzDetails.setHifzRange( hifzRange )
        }
        
        //Segue to QPageBrowser
        if  let qPagesBrowser = segue.destination as? QPagesBrowser,
            let viewCell = sender as? HifzTableViewCell,
            let hRange = viewCell.hifzRange
        {
            
            let qData = QData.instance
            let ayaPos = qData.ayaPosition(pageIndex: hRange.page, suraIndex: hRange.sura)
            
            SelectStart = ayaPos
            SelectEnd = ayaPos
            
            if segue.identifier == "ReviseHifz"{
                MaskStart = ayaPos
            }
            
            qPagesBrowser.startingPage = qData.pageIndex(ayaPosition: ayaPos) + 1
        }
        
    }
    
    // MARK: - Table Editing delegate methods
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    /*
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */
}
