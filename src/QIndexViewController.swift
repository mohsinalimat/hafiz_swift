//
//  QIndexViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 7/30/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class QIndexViewController: UITableViewController
    ,UIActionAlertsManager
{
    
    override
    func viewDidLoad() {
        // Preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false

        //relead data upon signed In user is changed
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.signedIn, object: nil)
        
        //relead data upon data change
        NotificationCenter.default.addObserver(self, selector: #selector(onDataUpdated), name: AppNotifications.dataUpdated, object: nil)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func onDataUpdated(){
        tableView.reloadData()
    }

    override
    func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backgroundColor = .blue
    }

    // MARK: - Actions Alerts delegate methods

    func handleAlertAction(_ id: AlertActions, _ selection: Any?) {
        switch id {
        case .revisedHifz:
            //TODO: duplicate code
            if let hifzRange = selection as? HifzRange{
                let _ = QData.promoteHifz(hifzRange){
                    snapshot in
                    Utils.showMessage(self, title: AStr.revisionSaved, message: AStr.goodJob)
                }
            }
            break
        case .removeHifz:
            //TODO: duplicate code
            if let hifzRange = selection as? HifzRange,
                let suraName = QData.instance.suraName(suraIndex: hifzRange.sura){
                let desc = QData.describe(hifzTitle: hifzRange)
                //TODO: duplicate code
                Utils.confirmMessage(
                    self,
                    AStr.removeSfromHifz(s: AStr.suraSdescS(s: suraName.name, d: desc)),
                    AStr.areYouSure,
                    .yes_destructive
                ){ yes in
                    if yes {
                        QData.deleteHifz([hifzRange]){ snapshot in }
                    }
                }
            }
            break
        default:
            break
        }
    }
    
    // MARK: - Table view data source delegates
    
    override
    func numberOfSections(in tableView: UITableView) -> Int {
        return 31
    }

    override
    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        let qData = QData.instance
        
        switch sectionIndex{
        case 0://reading position
            return 1
        default:
            let partIndex = sectionIndex - 1
            if let partInfo = qData.partInfo(partIndex: partIndex) {
                let rows = partInfo.endSura - partInfo.sura
                return rows + 1
            }
        }
        
        return 0
    }
    
    // MARK: - Table view UI delegates
    
    override
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = AppColors.silverBg
        if let header = view as? UITableViewHeaderFooterView{
            header.textLabel?.textColor = AppColors.blueText
        }
    }
    
    override
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        if let cell = tableView.cellForRow(at: indexPath) as? IndexTableViewCell{
            var menuItems = [
                UIMenuItem(title: AStr.tafseer, action: #selector(IndexTableViewCell.tafseer))
            ]
            menuItems.append(
                UIMenuItem(title: cell.in_hifz ? AStr.updateHifz : AStr.addHifz, action: #selector(IndexTableViewCell.addUpdateHifz))
            )
            if !cell.bookmarked{
                menuItems.append(
                    UIMenuItem(title: AStr.bookmark, action: #selector(IndexTableViewCell.bookmark))
                )
            }

            //cell.updateRangeColor() //to override selection forced background color
            UIMenuController.shared.menuItems = menuItems
            return true
        }
        return false
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //reset the ranges colors if found
//        if let cell = tableView.cellForRow(at: indexPath) as? IndexTableViewCell{
//            cell.updateHifzColor()
//        }
    }
    
    override
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return AStr.readingStop
        }
        return AStr.partN(n: section)
    }

    override
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let qData = QData.instance
        var ayaPos = 0
        var partStartPage = 0
        var suraStartPage = 0
        var pageNumber = 0
        var insideSura = false
        var suraIndex = 0
        var aya = 0

        if indexPath.section == 0 { // reading stop
            let readingStop = Utils.readSetting("reading_stop") as? Int ?? 0
            pageNumber = readingStop + 1
            if let pageInfo = qData.pageInfo(readingStop){
                aya = pageInfo.ayaIndex
                suraIndex = pageInfo.suraIndex
                ayaPos = pageInfo.ayaPos
                if pageInfo.ayaIndex != 0{
                    insideSura = true
                }
            }
        }
        else {// parts and suras
            let partIndex = indexPath.section - 1
            
            suraIndex = qData.suraIndex(partIndex: partIndex) + indexPath.row
            
            if let partInfo = qData.partInfo(partIndex: partIndex) {
                partStartPage = partInfo.page
                aya = partInfo.aya
                ayaPos = qData.ayaPosition(sura: partInfo.sura, aya: aya)
            }

            if let sInfo = qData.suraInfo(suraIndex) {
                suraStartPage = sInfo.page
            }

            if indexPath.row == 0 {
                //first row in the section, it could be a part or a sura
                pageNumber = partStartPage + 1//displayed page
                if suraStartPage != partStartPage{
                    //the part started in the middle of a sura
                    insideSura = true
                }
            }else{
                pageNumber = suraStartPage + 1
                ayaPos = qData.ayaPosition(sura: suraIndex, aya: 0)
                aya = 0
            }
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "SuraStart", for: indexPath)
        cell.tag = ayaPos
        
        if let suraName = qData.suraName(suraIndex: suraIndex),
           let suraCell = cell as? IndexTableViewCell
        {
            suraCell.setCellInfo( ayaPos, suraIndex )
            suraCell.suraNumber.text = insideSura ? "..." : String(suraIndex+1)
            suraCell.pageNumber.text = String(pageNumber)
            let ayaNumber = (aya>0) ? " (\(aya+1))" : ""
            suraCell.suraName.text = suraName.name + ayaNumber
            if let ayaText = qData.ayaText(ayaPosition: ayaPos){
                suraCell.firstAya.text = ayaText
            }
            suraCell.backgroundImage.image = insideSura ? nil : UIImage(named: "index_item_background")
        }
        
        return cell;
    }
    
    override
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let viewCell = sender as? UITableViewCell
           //,let qPagesBrowser = segue.destination as? QPagesBrowser
        {
            //let qData = QData.instance
            let ayaPos = viewCell.tag
            //qPagesBrowser.startingPage = qData.pageIndex(ayaPosition: ayaPos) + 1
            //Reset previous selections and mask
            MaskStart = -1
            SelectStart = ayaPos
            SelectEnd = ayaPos
        }
        
        if  let tafseerView = segue.destination as? TafseerViewController,
            let indexCell = sender as? IndexTableViewCell,
            let ayaPos = indexCell.ayaPos
        {
            let (sura,aya) = QData.instance.ayaLocation(ayaPos)
            tafseerView.ayaPosition = QData.instance.ayaPosition(sura: sura, aya: aya)
        }
        
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var titles = ["*"]
        for n in 1...30 {
            titles.append(String(n))
        }
        return titles
    }
}

class IndexTableViewCell : UITableViewCell {
    
    @IBOutlet weak var suraNumber: UILabel!
    @IBOutlet weak var suraName: UILabel!
    @IBOutlet weak var pageNumber: UILabel!
    @IBOutlet weak var firstAya: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    var ayaPos:Int?
    var sura:Int?
    var bookmarked = false
    var in_hifz = false
    var hifzList:HifzList?
    
    func setCellInfo(_ aya: Int, _ sura:Int ){
        self.ayaPos = aya
        self.sura = sura
        bookmarked = false
        in_hifz = false
        let qData = QData.instance
        
//  Not needed to improve performance
//        QData.isBookmarked(aya){
//            yes in
//            self.bookmarked = yes
//        }
        //let sura = qData.suraIndex(ayaPosition: aya)
        
        
        QData.suraHifzList(sura){
            hifzList in
            if let hifzList = hifzList,
                let suraInfo = qData.suraInfo(sura){

                self.hifzList = hifzList

                if hifzList.count == 1,
                    let hifzRange = hifzList.first {
                    let totalSuraPages = suraInfo.endPage - suraInfo.page + 1
                    if hifzRange.count == totalSuraPages{
                        self.in_hifz = true // all sura inside hifz
                    }
                }
            }
            self.updateHifzColor()
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(addUpdateHifz)
            || action == #selector(bookmark)
            || action == #selector(tafseer)
    }
    
    @objc func tafseer(){
        //TODO: duplicate code, move to utils
        if let vc = self.parentViewController as? QIndexViewController{
            vc.navigationController?.removeTafseer()//only allow one instance in the stack
            vc.performSegue(withIdentifier: "ShowTafseer", sender: self)
        }
    }
    
    @objc func bookmark(){
        if let ayaPos = self.ayaPos,
            let vc = self.parentViewController as? QIndexViewController{
            QData.bookmark(vc, ayaPos)
            bookmarked = true
        }
    }
    
    @objc func addUpdateHifz(){
        if in_hifz{//all sura in hifz
            if let hifzList = self.hifzList,
                let hifzRange = hifzList.first,
                let suraName = self.suraName.text,
                let vc = self.parentViewController
            {
                let desc = QData.describe(hifzTitle: hifzRange)
                
                vc.showAlertActions(
                    [
                        vc.alertAction(.revisedHifz, AStr.revisedToday, hifzRange),
                        vc.alertAction(.removeHifz, AStr.removeFromHifz, hifzRange)
                    ],
                    AStr.suraSdescS(s: suraName, d: desc)
                )
            }
        }else{
            //let qData = QData.instance
            if let vc = self.parentViewController as? QIndexViewController,
                let sura = self.sura,
                let suraInfo = QData.instance.suraInfo(sura)
            {
                Utils.confirmAddSuraToHifz(vc:vc, sura:sura){ yes in
                    if yes {
                        self.addSuraToHifz(suraInfo: suraInfo)
                    }
                }
            }
        }
    }
    
    func addSuraToHifz(suraInfo:SuraInfo){
        let addParams = AddHifzParams(sura: suraInfo.sura, page: suraInfo.page, select:.all)
        QData.addHifz(params: addParams){ hifzRange in
            self.hifzList = [hifzRange]
            self.in_hifz = true
            self.updateHifzColor()
            //self.confirmPromoteHifz()
        }
    }
   
//    func confirmPromoteHifz(){
//        if let hifzList = self.hifzList,
//            let hifzRange = hifzList.first,
//            let suraName = QData.instance.suraName(suraIndex: hifzRange.sura),
//            let vc = self.parentViewController as? QIndexViewController
//        {
//            Utils.confirmMessage(vc, "Sura \(suraName.name)", "Would you like to mark it as revised today?", .yes){ yes in
//                if yes {
//                    let _ = QData.promoteHifz(hifzRange){ hifzRange in
//                        self.hifzList = [hifzRange]
//                        Utils.showMessage(vc, title: "Done", message: "Good job :)")
//                        self.updateHifzColor()
//                    }
//                }
//            }
//        }
//    }
    
    func updateHifzColor(){
        if in_hifz,
            let hifzList = self.hifzList,
            let hifzRange = hifzList.first{
            self.backgroundColor = QData.hifzColor(range: hifzRange)
        }
        else{
            self.backgroundColor = .white
        }
    }
}
