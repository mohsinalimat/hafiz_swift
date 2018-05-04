
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
    @IBOutlet weak var rangeBody: UIView!
    @IBOutlet weak var rangeStart: NSLayoutConstraint!
    @IBOutlet weak var rangeWidth: NSLayoutConstraint!
    
    var hifzRange:HifzRange?
    
    func setRange(_ hifzRange: HifzRange ){
        self.hifzRange = hifzRange
        rangeBody.backgroundColor = QData.hifzColor(range: hifzRange)
    }
    
    func updateHifzChart(width:CGFloat){
        if let hifzRange = self.hifzRange{
            rangeBody.backgroundColor = QData.hifzColor(range: hifzRange)
            let qData = QData.instance()
            if let suraInfo = qData.suraInfo(hifzRange.sura){
                let suraStartPage = CGFloat(suraInfo.page)
                let suraEndPage = CGFloat(suraInfo.endPage)
                let pagesCount = CGFloat(suraEndPage - suraStartPage + 1)
                //TODO: use mutipliers instead of constants to support view resizing
                rangeStart.constant = (CGFloat(hifzRange.page) - suraStartPage) * width / pagesCount
                rangeWidth.constant = CGFloat(hifzRange.count) * width / pagesCount
            }
        }else{
            rangeWidth.constant = 0
        }
    }
}

class HifzViewController: UITableViewController {

    var hifzRanges:[HifzRange]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        
        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.signedIn, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.dataUpdated, object: nil)

        loadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onRefresh(){
        loadData(sync: true)
    }
    
    @objc func onDataUpdated(){
        QData.hifzList(false){(ranges) in
            self.hifzRanges = ranges
            self.tableView.reloadData()
        }
    }
    
    func loadData( sync:Bool = false ){
        QData.hifzList(sync){(ranges) in
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Hifz Cell", for: indexPath) as! HifzTableViewCell

        if let hifzRanges = self.hifzRanges {
            // Populate cell data...
            let rowIndex = indexPath.row
            let hRange = hifzRanges[rowIndex]
            let qData = QData.instance()

            cell.suraName!.text = qData.suraName(suraIndex: hRange.sura)
            cell.rangeDescription!.text = "\(hRange.count) pages from page \(hRange.page)"
            cell.lastRevision!.text = "\(hRange.age) days"
            cell.hifzRange = hRange
        }else{
            //TODO: if not logged in, show login required message
            cell.suraName!.text = "Loading..."
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let hifzCell = cell as? HifzTableViewCell{
            hifzCell.updateHifzChart(width: tableView.frame.size.width)
        }
    }
    
    
    override
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let hifzDetails = segue.destination as? HifzDetailsViewController,
           let viewCell = sender as? HifzTableViewCell,
            let hifzRange = viewCell.hifzRange
        {
            hifzDetails.setHifzRange( hifzRange )
        }
        
        if  let qPagesBrowser = segue.destination as? QPagesBrowser,
            let viewCell = sender as? HifzTableViewCell,
            let hRange = viewCell.hifzRange
        {
            
            let qData = QData.instance()
            let ayaPos = qData.ayaPosition(pageIndex: hRange.page, suraIndex: hRange.sura)
            SelectStart = ayaPos
            SelectEnd = ayaPos
            MaskStart = ayaPos
            qPagesBrowser.startingPage = qData.pageIndex(ayaPosition: ayaPos) + 1
        }
        
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}