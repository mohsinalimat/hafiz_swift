//
//  QIndexViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 7/30/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class QIndexViewController: UITableViewController{
    
    override
    func viewDidLoad() {
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }

    override
    func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 51/256, green: 102/256, blue: 51/256, alpha: 1)
    }

    // MARK: - Table view data source delegates
    
    override
    func numberOfSections(in tableView: UITableView) -> Int {
        return 30
    }

    override
    func tableView(_ tableView: UITableView, numberOfRowsInSection partIndex: Int) -> Int {
        let qData = QData.instance()
        
        if let partInfo = qData.partInfo(partIndex: partIndex) {
            let rows = partInfo["es"]! - partInfo["s"]!
            return rows + 1
        }
        
        return 0
    }
    
    override
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(format:NSLocalizedString("Part", comment:""),section+1)
    }

    override
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let qData = QData.instance()
        var cellID = "SuraStart"

        let partIndex = indexPath.section
        let suraIndex = qData.suraIndex(partIndex: partIndex) + indexPath.row
        

        let pagePrompt = NSLocalizedString("Pg", comment: "")
        var partStartPage = 0
        var suraStartPage = 0
        var pageNumber = 0
        var suraPrefix = "\(suraIndex+1)"
        //let backgroundView = UIImageView(image: UIImage(named: "Heart"))

        if let partInfo = qData.partInfo(partIndex: partIndex), let page = partInfo["p"]{
            partStartPage = page
        }

        if let sInfo = qData.suraInfo(suraIndex: suraIndex), let page = sInfo["sp"]{
            suraStartPage = page
        }

        if indexPath.row == 0 {
            pageNumber = partStartPage
            if suraStartPage != partStartPage{
                suraPrefix = "..."
                cellID = "SuraResume"
            }
        }else{
            pageNumber = suraStartPage
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.tag = pageNumber;
        if cellID == "SuraStart"{
            cell.backgroundView = UIImageView(image:UIImage(named: "index_item_background")!)
        }
        if let suraName = qData.suraName(suraIndex: suraIndex) {
            cell.textLabel!.text = "\(suraPrefix) \(suraName)";
        }
        cell.detailTextLabel!.text = String(format:pagePrompt, pageNumber)
        
        return cell;
    }
    
    
    override
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let viewCell = sender as? UITableViewCell, let qPagesBrowser = segue.destination as? QPagesBrowser
        {
            qPagesBrowser.startingPage = viewCell.tag
            //Reset previous selections and mask
            MaskStart = -1
            SelectStart = -1
            SelectEnd = -1
        }
        
    }
}
