//
//  QData.swift
//  test
//
//  Created by Ramy Eldesoky on 8/4/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
//import GoogleSignIn
import Firebase
import FirebaseAuthUI


typealias NamedIntegers = [String:Int]
typealias PageInfo = (suraIndex:Int, ayaIndex:Int, ayaPos:Int, ayaCount:Int)
typealias SuraInfo = (sura:Int, page:Int, endPage:Int, totalAyat:Int, tanzeel:Int)
typealias PartInfo = (sura:Int, aya:Int, endSura:Int, endAya:Int, page:Int, endPage:Int)
typealias AyaInfo = (sura:Int, aya:Int, page:Int)//unused
typealias AyaFullInfo = (sura:Int, aya: Int,page: Int, sline:Int, spos:CGFloat, eline:Int, epos:CGFloat)
typealias AyaRecord = (sura:String,aya: String, aya_text: String, page: String)
typealias HifzRange = (sura:Int, page:Int, count:Int, age:Double, revs:Int)
typealias HifzList = [HifzRange]
typealias SuraPageLocation = (sura:Int, page:Int, fromLine:Int, toLine: Int)
typealias PageMap = [AyaFullInfo]
typealias SuraInfoList = [SuraInfo]
typealias SuraName = (sura:Int, name:String)
typealias SuraNames = [SuraName]

enum SelectAddHifz{
    case all, fromStart, toEnd, page
}


class QData{
    var suraInfoList:SuraInfoList?
    var partInfo:[NamedIntegers]?
    var pageInfoList:[PageInfo]?
    var suraNames:NSArray?
    var quranData:NSArray?
    var normalizedQuranTextArray:NSArray?
    var normalizedSuraNames:[String]?
    var quranText:NSArray?
    
    static let totalAyat = 6236
    static let lastPageIndex = 603
    
    enum Direction {
        case forward, backward
    }
    
    enum Position {
        case first, inside, last
    }
    
    typealias AyaPagePosition = ( page:Int, position:Position )

    init(){
        do{
            if let path = Bundle.main.url(forResource: "qdata", withExtension: "json") {

                let jsonData = try Data(contentsOf: path)
                
                let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])
                
                if let object = json as? [String: Any] {

                    // json is a [String:Any] dictionary
                    self.suraInfoList = []
                    
                    if let suras = object["sura_info"] as? [NamedIntegers] {
                        //process the data for quicker access
                        for n in 0..<suras.count{
                            self.suraInfoList?.append(self.suraInfo(n, suras:suras)!)
                        }
                    }
                    if let partInfo = object["parts"]{
                        self.partInfo = partInfo as? [NamedIntegers]
                    }
                    if let pagesInfo = object["pagesInfo"] as? [NamedIntegers]{
                        self.pageInfoList = []
                        for n in 0..<pagesInfo.count{
                            self.pageInfoList?.append( self.pageInfo(n, infoList: pagesInfo)! )
                        }
                    }
                }
            }
        }
        catch{
            print ("JSON load error")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSignIn), name: AppNotifications.signedIn, object: nil)
    }

    static var qData: QData?
    
    class var instance:QData{
        get{
            if let inst = qData {
                return inst
            }
            qData = QData()
            return qData!
        }
    }

    @objc func handleSignIn(){
        //clear cached data
        QData.cachedHifzList = nil
        QData.cachedBookmarks = nil
        QData.cachedSortedHifzList = nil
    }
    
    //Synchronous!, consider caching for smoother page navigation
    class func pageMap(_ pageIndex:Int)->PageMap{
        do{
            if let path = Bundle.main.url(forResource: "pg_map/pm_\(pageIndex+1)", withExtension: "json")
            {
                let jsonData = try Data(contentsOf: path)
                let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])

                if let object = json as? [String: Any] {
                    // json is a [String:String] dictionary
                    if let jsonArray = object["child_list"] as? [[String:String]]{
                        //return (ayaFullInfoList as? [[String : String]])!
                        var retArray = PageMap()
                        for ndx in 0..<jsonArray.count{
                            retArray.append(self.ayaFullInfo(jsonArray[ndx]))
                        }
                        return retArray
                    }
                }
            }
        }
        catch{
            print ("JSON load error")
        }
        return []
    }
    
    func ayaMapInfo(_ ayaPosition:Int, pageMap: PageMap)->AyaFullInfo?{
        let (suraIndex,ayaIndex) = self.ayaLocation(ayaPosition)
        for ayaInfo in pageMap{
            if ayaInfo.sura == suraIndex  && ayaInfo.aya == ayaIndex {
                return ayaInfo
            }
        }
        return nil //not found
    }
    
    //Returns list of suras found in the page
    func pageSuraInfoList(_ pageIndex: Int, pageMap: PageMap )->SuraInfoList{
        var suraInfoList = SuraInfoList()
        var lastSura = -1
        for ayaInfo in pageMap{
            if ayaInfo.sura != lastSura, let suraInfo = self.suraInfo(ayaInfo.sura) {
                lastSura = ayaInfo.sura
                suraInfoList.append( suraInfo )
            }
        }
        return suraInfoList
    }

    func pageInfo(_ pageIndex: Int )->PageInfo?{
        if let pagesInfo = self.pageInfoList, pageIndex < pagesInfo.count {
            return pagesInfo[pageIndex]
        }
        return nil
    }
    
    //Slow function
    private func pageInfo(_ pageIndex: Int, infoList: [NamedIntegers] )->PageInfo? {
        if pageIndex < 0 || pageIndex > infoList.count{
            return nil
        }

        let info = infoList[pageIndex]
        let suraIndex = info["s"]! - 1
        let ayaIndex = info["a"]! - 1
        
        //two CPU expensive calls
        let startAya = ayaPosition(sura: suraIndex, aya: ayaIndex)
        var nextPageStartAya = QData.totalAyat
        
        if pageIndex+1 < infoList.count{//not last page
            let nextPageInfo = infoList[pageIndex+1]
            nextPageStartAya = ayaPosition(sura: nextPageInfo["s"]! - 1, aya: nextPageInfo["a"]! - 1)
        }

        return (
            suraIndex: suraIndex,
            ayaIndex: ayaIndex,
            ayaPos: startAya,
            ayaCount: nextPageStartAya-startAya
        )
    }
    
    func ayaMapInfo(_ ayaPosition:Int, pageIndex: Int )->AyaFullInfo?{
        let pageMap = QData.pageMap( pageIndex )
        return ayaMapInfo(ayaPosition, pageMap: pageMap)
    }
    
    func ayaPosition( pageIndex: Int )->Int{
        let pageInfo = self.pageInfo( pageIndex )!
        return pageInfo.ayaPos
    }

    func ayaPosition( pageIndex: Int, suraIndex: Int )->Int{
        
        if let suraInfo = self.suraInfo(suraIndex),
            suraInfo.page == pageIndex{
            //Sura starts in this page, return first sura's first aya
            return self.ayaPosition(sura:suraIndex, aya:0)
        }
        
        if let pageInfo = self.pageInfo(pageIndex){
            return pageInfo.ayaPos
        }
        
        return -1
    }

    func ayaPosition( sura: Int, aya: Int )->Int{
        var index = 0
        for suraIndex in 0..<sura{
            if let suraInfo = self.suraInfo(suraIndex) {
                index += suraInfo.totalAyat
            }
        }
        return index+aya
    }
    
    func ayaLocation(_ index:Int )->(sura:Int,aya:Int){
        var suraStartIndex = 0
        if let suras = self.suraInfoList {
            for suraIndex in 0..<114{
                let suraInfo = suras[suraIndex]
                if suraStartIndex + suraInfo.totalAyat > index {
                    return (suraIndex, index-suraStartIndex)
                }
                suraStartIndex+=suraInfo.totalAyat
            }
        }
        return (0,0)
    }
    
    func suraIndex( pageIndex: Int, direction: Direction = .forward )->Int{
        
        if let suraInfoList = self.suraInfoList {
            
            let seq = (direction == .backward) ?
                        suraInfoList.reversed().enumerated() : suraInfoList.enumerated()
            
            for (suraIndex, suraInfo) in seq {
                
                if(direction == .forward){
                    //found first sura that the page is inside it
                    if suraInfo.endPage >= pageIndex{
                        return suraIndex
                    }
                }
                else{//find last sura where the target page is inside it
                    if suraInfo.page <= pageIndex{
                        //sura is found in the reverse order
                        return suraInfoList.count - suraIndex
                    }
                }
                
            }
            return direction == .backward ? 0 : suraInfoList.count - 1 //return first or last sura
        }
        return 0
    }
    
    func partIndex(pageIndex: Int) -> Int{
        let pageNumber = pageIndex+1
        
        for (n,pInfo) in self.partInfo!.enumerated() {
            if let pStartPage = pInfo["p"], let pEndPage = pInfo["ep"] {
                
                if pageNumber >= pStartPage && pageNumber <= pEndPage {
                    return n
                }
            }
        }
        return 0
    }
    
    func suraIndex(partIndex: Int) -> Int{
        if let partInfo = self.partInfo(partIndex:partIndex){
            return partInfo.sura
        }
        return 0
    }
    
    func suraIndex( ayaPosition: Int )-> Int{
        let (suraIndex, _) = ayaLocation(ayaPosition)
        return suraIndex
    }
    
    /// Returns the next sura relative to a specific page
    /// It skips suras that are in the same page if found
    ///
    /// - Parameter prevSuraPage: the page to seek forward from
    /// - Returns: following sura and its first page index
    func nextSura( fromPage: Int ) -> (sura:Int,page:Int){
        var prevSuraIndex = suraIndex(pageIndex:fromPage)
        if(prevSuraIndex>=113){
            return (sura:0,page:0)
        }
        var pgIndex:Int
        
        repeat{
            prevSuraIndex += 1
            pgIndex = pageIndex ( suraIndex: prevSuraIndex )
        } while (pgIndex == fromPage)
        
        return (sura:prevSuraIndex, page:pgIndex)
    }

    
    /// Returns the prior sura relative to a specific page
    /// It skips suras that are in the same page if found
    ///
    /// - Parameter nextSuraPage: the page to seek backward from
    /// - Returns: prior sura and its first page index
    func priorSura( fromPage: Int ) -> (sura:Int,page:Int){
        var nextSuraIndex = suraIndex( pageIndex:fromPage, direction: .backward )
        
        if(nextSuraIndex==0){
            return (sura:113, page:pageIndex( suraIndex: 113 ))
        }
        
        var pgIndex:Int
        
        repeat{
            nextSuraIndex -= 1
            pgIndex = pageIndex( suraIndex: nextSuraIndex )
        } while (pgIndex == fromPage)
        
        return (sura:nextSuraIndex, page:pgIndex)
    }
    
    func readQuranData() -> NSArray? {
        if quranData == nil {
            if let path = Bundle.main.path(forResource: "quran", ofType: "plist") {
                quranData = NSArray(contentsOfFile: path) //cache quranData NSDictionary
            }
        }
        return quranData
    }
    
    func readQuranText()->NSArray?{
        if quranText == nil {
            if let path = Bundle.main.path(forResource: "quran_text", ofType: "plist") {
                quranText = NSArray(contentsOfFile: path) //cache quranData NSDictionary
            }
        }
        return quranText
    }
    
    func ayaText( ayaPosition: Int ) -> String? {
        if let quranText = readQuranText() {
            if let aya_text = quranText[ayaPosition] as? String {
                return aya_text
            }
        }
        return nil
    }
    
    func suraName( suraIndex: Int ) -> SuraName? {
        
        if let suraNames = readSuraNames(), let name = suraNames[suraIndex] as? String{
            return SuraName(sura:suraIndex, name: name)
        }
        return nil
    }
    
    func suraNames( suras: [Int] )-> SuraNames{
        var names = SuraNames()
        for sura in suras {
            if let suraName = self.suraName( suraIndex: sura ){
                names.append(suraName)
            }
        }
        return names
    }
    
    func readSuraNames() -> NSArray?{
        if suraNames == nil {
            if let path = Bundle.main.path(forResource: "SuraNames", ofType: "plist") {
                suraNames = NSArray(contentsOfFile: path) //cache suraNames NSDictionary
            }
        }
        return suraNames //cached list
    }
    
    // MARK: - Search functions
    func readNormalizedSuraNames()-> [String]?{
        if normalizedSuraNames == nil {
            if let suraNames = readSuraNames(){
                normalizedSuraNames = []

                for i in 0..<suraNames.count {
                    if let name = suraNames[i] as? String {
                        normalizedSuraNames!.append(name.normalizeAya())
                    }
                }
            }
        }
        return normalizedSuraNames
    }
    
    func readNormalizedText()-> NSArray?{
        if normalizedQuranTextArray == nil {
            if let path = Bundle.main.path(forResource: "normalized_quran", ofType: "plist") {
                normalizedQuranTextArray = NSArray(contentsOfFile: path) //cache quranData NSDictionary
            }
        }
        return normalizedQuranTextArray
    }
    
    func searchQuran(_ pattern: String, max: Int ) -> [Int] {
        var results :[Int]  = []
        
        let search_term = pattern.normalizeAya()
        
        if let suraNames = readNormalizedSuraNames() {
            for suraNumber in 1...suraNames.count {
                if suraNames[suraNumber-1].range(of: search_term) != nil {
                    results.append( -suraNumber )
                }
            }
        }

        if pattern.count < 2 {
            return results
        }
        
        if let quranData = readNormalizedText(){
            for pos in 0..<quranData.count{
                if let ayaText = quranData[pos] as? String{
                    if ayaText.range(of:search_term) != nil {
                        results.append(pos)
                        if results.count>=max{
                            break
                        }
                    }
                }
            }
        }
        
        return results
    }
    
    func suraName( pageIndex: Int ) -> SuraName? {
        let sIndex = suraIndex( pageIndex: pageIndex )
        return suraName( suraIndex: sIndex )
    }
    
    func pageIndex( partIndex: Int )-> Int{
        if let partInfo = self.partInfo(partIndex:partIndex){
            return partInfo.page
        }
        return 0
    }
    
    func pageIndex( suraIndex: Int )-> Int{
        if let suraInfo = self.suraInfo(suraIndex){
            return suraInfo.page
        }
        return 0
    }
    
    func pageIndex( ayaPosition: Int )->Int{
        let (suraIndex,ayaIndex) = self.ayaLocation(ayaPosition)
        let pageIndex = self.pageIndex(suraIndex: suraIndex)
        for p in pageIndex...QData.lastPageIndex {
            let pageInfo = pageInfoList![p]
            let pageSuraIndex = pageInfo.suraIndex
            let pageStartAyaIndex = pageInfo.ayaIndex
            if ( pageSuraIndex > suraIndex )
                || ( pageSuraIndex == suraIndex && pageStartAyaIndex > ayaIndex )
            {
                return p-1
            }
        }
        return QData.lastPageIndex
    }
    
    func partInfo( partIndex: Int ) -> PartInfo?{
        if let parts = self.partInfo{
            if(partIndex<parts.count){
                let partValues = parts[partIndex]
                return PartInfo(
                    sura: partValues["s"]! - 1,
                    aya: partValues["a"]! - 1,
                    endSura: partValues["es"]! - 1,
                    endAya: partValues["ea"]! - 1,
                    page: partValues["p"]! - 1,
                    endPage: partValues["ep"]! - 1
                )
            }
        }
        return nil
    }

    func suraInfo( ayaPos: Int ) -> SuraInfo?{
        let sura = self.suraIndex(ayaPosition: ayaPos)
        return suraInfo(sura)
    }

    func suraInfo(_ suraIndex: Int ) -> SuraInfo?{
        if let suras = self.suraInfoList, suraIndex<suras.count{
            return suras[suraIndex]
        }
        return nil
    }

    private func suraInfo(_ suraIndex: Int, suras: [NamedIntegers] ) -> SuraInfo?{
        if(suraIndex<suras.count){
            let sInfo = suras[suraIndex]
            
            return SuraInfo(
                sura: suraIndex,
                page:sInfo["sp"]! - 1,
                endPage:sInfo["ep"]! - 1,
                totalAyat: sInfo["ac"]!,
                tanzeel: sInfo["t"]!
            )
        }
        return nil
    }

    
    func ayaCount( suraIndex: Int ) -> Int?{
        if let suraInfo = suraInfo(suraIndex) {
            return suraInfo.totalAyat
        }
        return nil
    }
    
    static func findSuraPageLocation( suraIndex: Int, pageMap:PageMap)->SuraPageLocation?{
        var fromLine = -1, toLine = -1, page = -1
        
        for ndx in 0..<pageMap.count {
            let ayaInfo = pageMap[ndx]
            if ayaInfo.sura == suraIndex {
                if fromLine == -1 {
                    page = ayaInfo.page
                    fromLine = ayaInfo.sline
                }
                toLine = ayaInfo.eline
            }
        }
        
        if fromLine != -1 {
            return SuraPageLocation( sura:suraIndex, page:page, fromLine:fromLine, toLine:toLine )
        }
        
        return nil
    }

    func locateAya( pageMap:PageMap, pageSize: CGSize, location: CGPoint )->AyaFullInfo?{
        let line = Int(location.y * 15 / pageSize.height)
        let line_pos = 1000 - (location.x * 1000) / pageSize.width
        for ayaInfo in pageMap {
            
            if ayaInfo.eline > line || ayaInfo.eline == line && ayaInfo.epos >= line_pos {
                return ayaInfo
            }
        }
        return nil
    }
    
    static func ayaFullInfo(_ pageMapItem: [String:String] )-> AyaFullInfo{
        let ayaInfo : AyaFullInfo = (
            eline: Int(pageMapItem["eline"]!)!,
            epos: CGFloat(Float(pageMapItem["epos"]!)!),
            sura: Int(pageMapItem["sura"]!)! - 1,
            aya: Int(pageMapItem["aya"]!)! - 1,
            sline:Int(pageMapItem["sline"]!)!,
            spos: CGFloat(Float(pageMapItem["spos"]!)!),
            page: Int(pageMapItem["page"]!)!-1
        )
        
        return ayaInfo
    }
    
    // TODO: not referenced
    func pageAya( at: Position, pageMap: PageMap ) -> Int {
        var ayaMapInfo:AyaFullInfo?
        
        if at == .first {
            ayaMapInfo = pageMap.first
        }
        if at == .last {
            ayaMapInfo = pageMap.last
        }
        if let ayaMapInfo = ayaMapInfo {
            return self.ayaPosition( sura: ayaMapInfo.sura, aya: ayaMapInfo.aya )
        }
        return -1
    }
    
    func ayaPagePosition(_ ayaPosition : Int )-> AyaPagePosition{
        let (sura,aya) = self.ayaLocation(ayaPosition)
        let pageIndex = self.pageIndex(ayaPosition: ayaPosition)
        let pageMap = QData.pageMap(pageIndex)
        let firstPageAya = pageMap.first!
        
        if sura == firstPageAya.sura && aya == firstPageAya.aya {
            return (page: pageIndex, position: .first)
        }
        
        let lastPageAya = pageMap.last!
        
        if sura == lastPageAya.sura && aya == lastPageAya.aya {
            return (page: pageIndex, position: .last)
        }
        return (page: pageIndex, position: .inside)
    }

    // MARK: - Bookmarks data methods
    
    static var cachedBookmarks:[Int]?
    
    static func isBookmarked(_ aya:Int, block: @escaping(Bool)->Void ){
        if false == bookmarks(sync:false, {(list) in
            //find the page in the list
            if let list = list,
               let _ = list.first(where:{(item) in item == aya})
            {
                block(true)
            }
            else{
                block(false)
            }
        })
        {//user is not logged in not bookmarked
            block(false)
        }
    }
    
    static func bookmark(_ vc: UIViewController,_ aya: Int ){
        if QData.checkSignedIn(vc){
            let _ = QData.createBookmark(aya: aya){snapshot in
                Utils.showMessage(vc,
                                  title: AStr.bookmarkAdded,
                                  message: AStr.bookmarkAddedDesc
                )
            }
        }
    }
    
    static func bookmarks(sync: Bool,_ block: @escaping([Int]?)->Void )->Bool {
        if !sync, let bookmarks = cachedBookmarks {
            DispatchQueue.main.async{
                block(bookmarks)
            }
        }
        
        if let ref = userData("aya_marks") {
            if sync {
                ref.keepSynced(true)
            }

            let bookmarks = ref.queryOrderedByValue() //value is the reversed timestamp
            
            bookmarks.observeSingleEvent(of: .value, with: {(snapshot) in
                var list:[Int] = []
                for child in snapshot.children.allObjects as! [DataSnapshot]{
                    list.append(Int(child.key)!)
                }
                cachedBookmarks = list
                block(list)
            }) { (error) in
                print( error )
                block(nil)
            }
            return true
        }
        
        return false
    }

    static func createBookmark( aya: Int, block: @escaping( DataSnapshot? )->Void )->Bool{
        if let pageMarks = userData("aya_marks") {
            pageMarks.keepSynced(true)//update remote data if connected
            
            pageMarks.observeSingleEvent(of: .childAdded) { (snapshot) in
                block(snapshot)
                AppDelegate.notifyDataChanged(snapshot: snapshot)
            }
            
            
            pageMarks.child(String(aya)).setValue( -Utils.timeStamp() ) //store current timestamp in negative for reverse sorting
            return true
        }
        return false // not authenticated
    }
    
    static func deleteBookmark( aya: Int, block: @escaping( DataSnapshot? ) -> Void )->Bool{
        if let pageMarks = userData("aya_marks") {
            pageMarks.keepSynced(true)//update remote data if connected
            
            pageMarks.observeSingleEvent(of: .childRemoved) { (snapshot) in
                block(snapshot)
                AppDelegate.notifyDataChanged(snapshot: snapshot)
            }
            
            pageMarks.child(String(aya)).removeValue()
            
            return true
        }
        return false // not authenticated
    }

    static func publicDataValue(_ key: String, block: @escaping(String?)->Void )->Void{
        let ref = Database.database().reference().child("public/\(key)")
        ref.observeSingleEvent(of: .value){ snapshot in
            if let val = snapshot.value as? String{
                block(val)
            }else{
                block(nil)
            }
        }
    }
    
    static func userData(_ key:String)->DatabaseReference?{
        if let userID = Auth.auth().currentUser?.uid  {
            let userData = Database.database().reference().child("data/\(userID)")
            return userData.child(key)
        }
        return nil
    }

    // MARK: - Hifz data methods
    
    static var cachedHifzList:HifzList?
    static var cachedSortedHifzList:HifzList?

    static func hifzColor( range: HifzRange, alpha: CGFloat = 0.12 )->UIColor{
        if range.age < 0{
            return .clear
        }
        if range.age < 7{
            return UIColor(red: 0.1, green: 1, blue: 0.1, alpha: alpha)
        }
        else if range.age < 14 {
            return UIColor(red: 0.6, green: 0.4, blue: 0.0, alpha: alpha)
        }
        return UIColor(red: 1, green: 0.1, blue: 0.1, alpha: alpha)
    }

    static func promoteHifz(_ hifzRange: HifzRange,_ block: @escaping(HifzRange)->Void )->Bool{

        let promtedHifz = HifzRange (
            sura: hifzRange.sura,
            page: hifzRange.page,
            count: hifzRange.count,
            age: 0,
            revs: hifzRange.revs + 1
        )

        return updateHifz( promtedHifz, block )
    }
    
    static func deleteHifz( _ hifzList: HifzList,_ notify: Bool = true,_ block: @escaping(DataSnapshot?)->Void ){
        if let hifz = userData("hifz"){
            hifz.keepSynced(true)
            
            hifz.observeSingleEvent(of: .childRemoved){
                snapshot in
                block(snapshot)
                AppDelegate.notifyDataChanged(snapshot: snapshot)
            }
            
            var dict:[AnyHashable:Any] = [:]
            
            hifzList.forEach{
                hifzRange in
                let hifzID = String(format:"%03d%03d",hifzRange.page,hifzRange.sura)
                dict[hifzID] = NSNull()
            }
            
            hifz.updateChildValues(dict)
        }
    }
    
    //Update or create new Hifz
    static func updateHifz(_ hifzRange: HifzRange,_ block: @escaping(HifzRange)->Void )->Bool{

        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd"
        df.locale = Locale.init(identifier: "en-us")
        let today = df.string(from:Date())
        
        if let hifz = userData("hifz"), let activity = userData("activity/\(today)") {
            hifz.keepSynced(true)

            let hifzPage = String(format:"%03d",hifzRange.page)
            let hifzSura = String(format:"%03d",hifzRange.sura)
            let hifzID = "\(hifzPage)\(hifzSura)"

            //To solve the difference between .childAdded vs .childChanged
            let removeOld:[AnyHashable:Any] = [hifzID:NSNull()]
            hifz.updateChildValues(removeOld)

            hifz.observeSingleEvent(of: .childAdded) { (snapshot) in
                //Check if snapshot.key matchs hifzID, it always returns the first item in the list
//                if(snapshot.key == hifzID){
//                    print("Hifz: got the right node \(snapshot.key) = \(hifzID) ")
//                }else{
//                    print("Hifz:Error: got the wrong node \(snapshot.key) instead of \(hifzID) ")
//                }
                block(hifzRange)
                AppDelegate.notifyDataChanged(snapshot: snapshot)
            }
            
            let dict : NSDictionary = [
                "pages": hifzRange.count,
                "revs": hifzRange.revs,
                "ts": Utils.timeStamp(-hifzRange.age)
            ]
            
            hifz.child( "\(hifzID)" ).setValue(dict)

            if hifzRange.revs > 0 { //make sure it is not first creation
                activity.child("pages").observeSingleEvent(of: .value){ (snapshot) in
                    let pages = snapshot.value as? Int ?? 0
                    activity.child("pages").setValue(pages+hifzRange.count)
                }
            }

            cachedHifzList = nil // reset the cache
            
            return true
        }
        return false
    }
    
    static func hifzRange( snapshot: DataSnapshot )->HifzRange?{
        if let info = snapshot.value as? NSDictionary {
            let pageAndSura = snapshot.key
            let page = Int(pageAndSura.prefix(3))!
            let sura = Int(pageAndSura.suffix(3))!
            let ts = info["ts"] as! Double / 1000 //seconds since 1970
            let dt = Date(timeIntervalSince1970: ts)
            let age = (Date().timeIntervalSince(dt)/60/60/24).rounded(.down) //days since last review
            let pages = info["pages"] as! Int
            let revs = info["revs"] as! Int
            return HifzRange(sura:sura, page:page, count:pages, age:age, revs:revs)
        }
        return nil
    }
    
    static func cachedHifz( sortByAge: Bool )->HifzList?{
        return sortByAge ? cachedSortedHifzList : cachedHifzList
    }
    
    static func setHifzCache( sortByAge: Bool, hifzList: HifzList ){
        if sortByAge {
            cachedSortedHifzList = hifzList
        }
        else{
            cachedHifzList = hifzList
        }
    }
    
    
    static var signedIn:Bool{
        if let _ = Auth.auth().currentUser?.uid {
            return true
        }
        return false
    }
    
    //Read hifz ranges from Firebase
    static func hifzList( sortByAge:Bool, sync:Bool, _ block: @escaping(HifzList?)->Void ){
        
        if !sync , let cached = cachedHifzList{
            DispatchQueue.main.async{
                block(cached)
            }
        }
        
        if let userID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("data/\(userID)/hifz")
            
            if sync {
                ref.keepSynced(true)
            }
            
            let hifzRanges = ref.queryOrdered(byChild: "ts")
            
            hifzRanges.observeSingleEvent(of: .value, with: {(snapshot) in
                if let snapshots = snapshot.children.allObjects as? [DataSnapshot]{
                    var list:HifzList = []
                    for child in snapshots{
                        if let range = QData.hifzRange(snapshot: child){
                            list.append(range)
                        }
                    }
                    setHifzCache(sortByAge: sortByAge, hifzList: list)
                    block(list)
                }
            }) { (error) in
                print( error )
                block(nil)
            }
        }
        else{
            //print( "Not authenticated" )
            block(nil)
        }
    }
    
    static func pageHifzRanges(_ pageIndex: Int, _ block: @escaping(HifzList?)->Void ){
        hifzList(sortByAge: true, sync:false){ (hifzRanges) in
            if let hifzRanges = hifzRanges {
                //filter ranges containing the designated page
                let pageHifzRanges = hifzRanges.filter{ hifzRange in
                    return pageIndex>=hifzRange.page && pageIndex<hifzRange.page+hifzRange.count
                }
                //sort by .sura
                let sortedHifzRanges = pageHifzRanges.sorted(by: {(range1, range2) in
                    return range1.sura < range2.sura
                })
                
                block(sortedHifzRanges)
                return
            }
            
            block(nil)
        }
    }
    
    static func suraHifzList(_ sura: Int, _ block: @escaping(HifzList?)->Void ){
        hifzList(sortByAge: false, sync: false){ hifzList in
            if let hifzList = hifzList {
                let suraHifz = hifzList.filter{ hifzRange in
                    return sura == hifzRange.sura
                }
                block( suraHifz )
            }
            else{
                block(nil)
            }
        }
    }
    
    static func addHifz(params:AddHifzParams, _ block: @escaping(HifzRange)->Void ){
        //read all exiting ranges for the selected sura
        //to check if we need to merge with or purge existing ranges
        var firstPage = params.firstPage()
        var lastPage = params.lastPage()
        var pagesCount = lastPage - firstPage + 1
        var hifzListToRemove = HifzList()
        var newRange = HifzRange(sura:params.sura, page:firstPage, count:pagesCount, age:7, revs:0)

        suraHifzList(params.sura){
            hifzList in
            hifzList?.forEach{
                oldRange in
                let oldRangeLastPage = oldRange.page + oldRange.count - 1
                if oldRange.page == firstPage && oldRangeLastPage == lastPage{
                    //totally matching ..|*******|..
                    newRange.revs = oldRange.revs
                    newRange.age = oldRange.age
                }
                else if oldRange.page > firstPage && oldRangeLastPage <= lastPage {
                    //if totally inside, swallowed ..nnOnnnnOn..
                    hifzListToRemove.append(oldRange)
                }
                else if oldRange.page > firstPage && oldRange.page <= lastPage+1 {
                    //intersects or attaches from start    ..nnnnnOnnOOO..
                    //expand the new range and remove the old
                    hifzListToRemove.append(oldRange)
                    pagesCount = oldRange.page + oldRange.count - firstPage
                    newRange.count = pagesCount
                    lastPage = firstPage + pagesCount - 1
                }
                else if oldRangeLastPage >= firstPage-1 && oldRange.page <= lastPage+1 {
                    //intersects or attaches at end ..OOOnnOnnnnn..
                    //Expand the old range hifzListToRemove.append(hifzRange)
                    pagesCount = firstPage + pagesCount - oldRange.page
                    firstPage = oldRange.page
                    newRange.page = firstPage
                    newRange.count = pagesCount
                }
            }
            
            if hifzListToRemove.count > 0{
                //TODO: read the revs of the deleted hifz and factor it in to the new hifz based on the
                QData.deleteHifz(hifzListToRemove, false){snapshot in
                    let _ = QData.updateHifz(newRange){hifzRange in
                        block(hifzRange)
                    }
                }
            }else{
                let _ = QData.updateHifz(newRange){hifzRange in
                    block(hifzRange)
                }
            }
        }
    }
    
    private static var _pageImagesBaseURL:String?
    
    static func pageImagesBaseURL(_ block: @escaping(String?)->Void ){
        if let cached = QData._pageImagesBaseURL {
            DispatchQueue.main.async{
                block( cached )
            }
        }
        
        Database.database().reference().child("public/images_url").observeSingleEvent(of: .value){
            (snapshot) in
            _pageImagesBaseURL = snapshot.value as? String
            block( _pageImagesBaseURL )
        }
    }
    
    static func signIn(_ vc: UIViewController){
        //TODO: implement different sign in providers
        //GIDSignIn.sharedInstance().signIn()
        if let authViewController = FUIAuth.defaultAuthUI()?.authViewController(){
            vc.present(authViewController, animated: true)
        }
    }
    
    static func checkSignedIn(_ vc: UIViewController,_ msg:String? = nil)->Bool{
        if QData.signedIn{
            return true
        }
        Utils.confirmMessage( vc, msg ?? AStr.signInRequired, AStr.signInRequiredDesc, .yes){
            isYes in
            if isYes{
                QData.signIn( vc )
            }
        }
        return false
    }
    
    static func signOut(_ vc: UIViewController){
        let email = Auth.auth().currentUser?.email ?? "current user"
        
        Utils.confirmMessage(vc, AStr.signOutS(s: email), AStr.areYouSure, .yes){  isYes in
            if isYes {
                do {
                    try Auth.auth().signOut() //signout from Firebase
                    try FUIAuth.defaultAuthUI()?.signOut()
                    //GIDSignIn.sharedInstance().disconnect()
                }
                catch let error as NSError{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    static var cachedTafseer:(name:String,data:[String]?) = (name:"none",data:nil)
    
    static func getTafseer(_ aya:Int,_ source:String? = nil)->String?{
        let tafSource = source ?? "ar.muyassar"
        
        if cachedTafseer.name == tafSource, let data = cachedTafseer.data{
            return data[aya]
        }
        
        do{
            if let path = Bundle.main.url(forResource: "tafseer/\(tafSource)", withExtension: "txt") {
                let tdata = try Data(contentsOf: path) //TODO: cache this data for next calls
                if let tafText = String(data: tdata, encoding: .utf8){
                    let list = tafText.components(separatedBy: "\n")
                    cachedTafseer = (name:tafSource,data:list)
                    return list[aya]
                }
            }
        }
        catch let err as NSError {
            print (err)
        }
        return nil
    }
    
    static func describe(hifzAge hRange: HifzRange)->String{
        if hRange.revs == 0{
            return "--"
        }
        
        let days = Int(hRange.age)
        switch(days){
        case 0:
            return AStr.today
        case 1:
            return AStr.yesterday
        default:
            return AStr.nDaysAgo(n: days)
        }
    }

    static func describe(hifzTitle hRange: HifzRange)->String{
        if let suraInfo = QData.instance.suraInfo(hRange.sura){
            let page_offset = hRange.page - suraInfo.page
            let total_sura_pages = suraInfo.endPage - suraInfo.page + 1

            if hRange.count == total_sura_pages{//whole sura
                return AStr.allPagesN(n: hRange.count)
            }
            
            if page_offset == 0{//start sura
                if hRange.count == 1{
                    return AStr.firstPage
                }
                return AStr.nOfyPages(n: hRange.count, y: total_sura_pages)
                //return "\(hRange.count) of \(total_sura_pages) pages" // from start
            }
            
            if hRange.page + hRange.count == suraInfo.endPage + 1{ // end range
                if hRange.count == 1{
                    return AStr.lastPage
                }
                return AStr.lastNpages(n: hRange.count)
            }
            
            // mid range
            if hRange.count == 1{
                return AStr.thePageN(n: page_offset+1)
                //return "the page: \(page_offset)"
            }
            return AStr.nPagesFromY(n: hRange.count, y: page_offset+1)
            //return "from: \(page_offset) - pages: \(hRange.count)"
        }

        return AStr.nPagesFromY(n: hRange.count, y: hRange.page) //fail safe
    }

    
}

struct AddHifzParams {
    var sura:Int
    var page:Int
    var select:SelectAddHifz
    
    init( sura:Int=0, page:Int=0, select:SelectAddHifz = .all){
        self.sura = sura
        self.page = page
        self.select = select
    }
    
    func fromSelect(_ select: SelectAddHifz)->AddHifzParams{
        return AddHifzParams(sura:self.sura,page:self.page,select:select)
    }
    
    func firstPage()->Int{
        var ret = self.page
        if select == .all || select == .fromStart {
            if let suraInfo = QData.instance.suraInfo(self.sura){
                ret = suraInfo.page
            }
        }
        return ret
    }

    func lastPage()->Int{
        var ret = self.page
        if select == .all || select == .toEnd {
            if let suraInfo = QData.instance.suraInfo(self.sura){
                ret = suraInfo.endPage
            }
        }
        return ret
    }

    func allPages()->[Int]{
        
        if self.select == .page {
            return [self.page]
        }
        
        var ret = [Int]()
        let first = firstPage()
        let last = lastPage()

        for p in first...last{
            ret.append(p)
        }
        return ret
    }
    
}
