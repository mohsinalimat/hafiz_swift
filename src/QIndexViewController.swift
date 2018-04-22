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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Sura Info", for: indexPath)

        let partIndex = indexPath.section
        let suraIndex = qData.suraIndex(partIndex: partIndex) + indexPath.row
        
        
        if let suraName = qData.suraName(suraIndex: suraIndex) {
            if let sInfo = qData.suraInfo?[suraIndex], let page = sInfo["sp"]{
                let pagePrompt = NSLocalizedString("Pg", comment: "")
                
                cell.tag = page;
                cell.detailTextLabel!.text = String(format:pagePrompt, page)
                //cell.detailTextLabel!.text = String(pageNum)
            }
            cell.textLabel!.text = "\(suraIndex+1) \(suraName)";
        }
        
        
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
