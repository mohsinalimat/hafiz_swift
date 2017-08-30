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
        //self.navigationController?.navigationBar.backgroundColor = .green
    }
    
    override
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Sura Info", for: indexPath)

        let rowIndex = indexPath.row;
        
        if let urData = qData, let suraName = urData.suraName(suraIndex: rowIndex) {
            if let sInfo = urData.suraInfo?[rowIndex], let page = sInfo["sp"]{
                let pagePrompt = NSLocalizedString("Pg", comment: "")
                
                cell.tag = page;
                cell.detailTextLabel!.text = String(format:pagePrompt, page)
                //cell.detailTextLabel!.text = String(pageNum)
            }
            cell.textLabel!.text = "\(rowIndex+1) \(suraName)";
        }
        
        
        return cell;
    }
    
    override
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 114
    }
    
    override
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let qPagesBrowser = segue.destination as! QPagesBrowser
        if let viewCell = sender as? UITableViewCell {
            qPagesBrowser.startingPage = viewCell.tag
        }
        
    }
}
