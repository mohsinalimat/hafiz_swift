//
//  QData.swift
//  test
//
//  Created by Ramy Eldesoky on 8/4/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
import Firebase

typealias NamedIntegers = [String:Int]
typealias PageInfo = (suraIndex:Int, ayaIndex:Int, ayaPos:Int, ayaCount:Int)
typealias SuraInfo = (page:Int, endPage:Int, totalAyat:Int, tanzeel:Int)
typealias PartInfo = (sura:Int, aya:Int, endSura:Int, endAya:Int, page:Int, endPage:Int)
typealias AyaInfo = (sura:Int, aya:Int, page:Int)//unused
typealias AyaFullInfo = (sura:Int, aya: Int,page: Int, sline:Int, spos:CGFloat, eline:Int, epos:CGFloat)
typealias AyaRecord = (sura:String,aya: String, aya_text: String, page: String)
typealias HifzRange = (sura:Int, page:Int, count:Int, age:Double, revs:Int)
typealias SuraPageLocation = (sura:Int, page:Int, fromLine:Int, toLine: Int)
typealias PageMap = [AyaFullInfo]

class QData{
    var suraInfo:[SuraInfo]?
    var partInfo:[NamedIntegers]?
    var pagesInfo:[PageInfo]?
    var suraNames:NSArray?
    var quranData:NSArray?
    var normalizedText:NSArray?
    var normalizedSuraNames:[String]?
    var quranText:NSArray?
    
    static let totalAyat = 6236
    static let lastPageIndex = 603
    
    enum Direction {
        case forward
        case backward
    }
    
    enum Position {
        case first
        case inside
        case last
    }

    typealias AyaPagePosition = (page:Int, position:Position)

    init(){
        do{
            if let path = Bundle.main.url(forResource: "qdata", withExtension: "json") {
                let jsonData = try Data(contentsOf: path)
                
                let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])
                
                if let object = json as? [String: Any] {

                    // json is a [String:Any] dictionary
                    self.suraInfo = []
                    
                    if let suras = object["sura_info"] as? [NamedIntegers] {
                        //process the data for quicker access
                        for n in 0..<suras.count{
                            self.suraInfo?.append(self.suraInfo(n, suras:suras)!)
                        }
                    }
                    if let partInfo = object["parts"]{
                        self.partInfo = partInfo as? [NamedIntegers]
                    }
                    if let pagesInfo = object["pagesInfo"] as? [NamedIntegers]{
                        self.pagesInfo = []
                        for n in 0..<pagesInfo.count{
                            self.pagesInfo?.append( self.pageInfo(n, infoList: pagesInfo)! )
                        }
                        //self.pagesInfo = pagesInfo as? [NamedIntegers]
                    }
                }
            }
        }
        catch{
            print ("JSON load error")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSignIn), name: AppNotifications.signedIn, object: nil)
    }
    
    @objc func handleSignIn(){
        //clear cached data
        QData.cachedHifzRanges = nil
    }
    
    static var qData: QData?
    
    class func instance()->QData{
        if let inst = qData {
            return inst
        }
        qData = QData()
        return qData!
    }
    
    //Synchronous!
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
    
    func pageInfo(_ pageIndex: Int )->PageInfo?{
        if let pagesInfo = self.pagesInfo, pageIndex < pagesInfo.count {
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
        if let suras = self.suraInfo {
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
        
        if let suraInfoList = self.suraInfo {
            
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
    
    func suraFirstPageIndex( prevSuraPageIndex: Int ) -> Int{
        var prevSuraIndex = suraIndex(pageIndex:prevSuraPageIndex)
        if(prevSuraIndex>=113){
            return 0
        }
        var pgIndex:Int
        
        repeat{
            prevSuraIndex += 1
            pgIndex = pageIndex ( suraIndex: prevSuraIndex )
        } while (pgIndex == prevSuraPageIndex)
        
        return pgIndex
    }

    func suraFirstPageIndex( nextSuraPageIndex: Int ) -> Int{
        var nextSuraIndex = suraIndex( pageIndex:nextSuraPageIndex, direction: .backward )
        if(nextSuraIndex==0){
            return pageIndex( suraIndex: 113 )
        }
        
        var pgIndex:Int
        
        repeat{
            nextSuraIndex -= 1
            pgIndex = pageIndex ( suraIndex: nextSuraIndex )
        } while (pgIndex == nextSuraPageIndex)
        
        return pgIndex
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
    
    func suraName( suraIndex: Int ) -> String? {
        
        if let suraNames = readSuraNames(){
            return suraNames[suraIndex] as? String
        }
        return nil
    }
    
    func readSuraNames() -> NSArray?{
        if suraNames == nil {
            if let path = Bundle.main.path(forResource: "SuraNames", ofType: "plist") {
                suraNames = NSArray(contentsOfFile: path) //cache suraNames NSDictionary
            }
        }
        return suraNames
    }
    
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
        if normalizedText == nil {
            if let path = Bundle.main.path(forResource: "normalized_quran", ofType: "plist") {
                normalizedText = NSArray(contentsOfFile: path) //cache quranData NSDictionary
            }
        }
        return normalizedText
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
    
    func suraName( pageIndex: Int ) -> String? {
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
            let pageInfo = pagesInfo![p]
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
    
    func suraInfo(_ suraIndex: Int ) -> SuraInfo?{
        if let suras = self.suraInfo, suraIndex<suras.count{
            return suras[suraIndex]
        }
        return nil
    }

    private func suraInfo(_ suraIndex: Int, suras: [NamedIntegers] ) -> SuraInfo?{
        if(suraIndex<suras.count){
            let sInfo = suras[suraIndex]
            
            return SuraInfo(
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
    
    static func bookmarks(sync: Bool,_ block: @escaping ([Int]?)->Void ) {
        if let userID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("data/\(userID)/page_marks")
            if sync {
                ref.keepSynced(true)
            }

            let bookmarks = ref.queryOrderedByValue() //value is the reversed timestamp
            
            bookmarks.observeSingleEvent(of: .value, with: {(snapshot) in
                var list:[Int] = []
                for child in snapshot.children.allObjects as! [DataSnapshot]{
                    list.append(Int(child.key)!)
                }
                block(list)
            }) { (error) in
                print( error )
                block(nil)
            }
        }
        else{
            print( "Not authenticated" )
            block(nil)
        }
    }
    static var cachedHifzRanges:[HifzRange]?
    
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
    
    static func promoteHifz(_ hifzRange: HifzRange,_ block: @escaping(DataSnapshot?)->Void )->Bool{
        if let userID = Auth.auth().currentUser?.uid {
            let hifzPage = String(format:"%03d",hifzRange.page)
            let hifzSura = String(format:"%03d",hifzRange.sura)
            let hifzID = "\(hifzPage)\(hifzSura)"
            let ref = Database.database().reference().child("data/\(userID)/hifz")
            ref.keepSynced(true)

            ref.observeSingleEvent(of: .childChanged, with: { (snapshot) in
                //TODO: check if snapshot.key matchs hifzID
                print("DB Child Changed: key=\(snapshot.key)")
                NotificationCenter.default.post(
                    name: AppNotifications.dataUpdated, object: snapshot
                )
                block(snapshot)
            })
            
            let dict : NSDictionary = [
                "pages": hifzRange.count,
                "revs": hifzRange.revs+1,
                "ts": Int64(Date().timeIntervalSince1970*1000)
            ]
            
            //TODO: increment activities

            ref.child( "\(hifzID)" ).setValue(dict)

            cachedHifzRanges = nil // reset the cache
            
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
    
    //Read hifz ranges from Firebase
    static func hifzList(_ sync:Bool, _ block: @escaping([HifzRange]?)->Void ){
        
        if !sync , let cached = cachedHifzRanges{
            block(cached)
        }
        
        if let userID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("data/\(userID)/hifz")
            
            if sync {
                ref.keepSynced(true)
            }
            
            let hifzRanges = ref.queryOrdered(byChild: "ts")
            
            hifzRanges.observeSingleEvent(of: .value, with: {(snapshot) in
                if let snapshots = snapshot.children.allObjects as? [DataSnapshot]{
                    var list:[HifzRange] = []
                    for child in snapshots{
                        if let range = QData.hifzRange(snapshot: child){
                            list.append(range)
                        }
                    }
                    cachedHifzRanges = list
                    block(list)
                }
            }) { (error) in
                print( error )
                block(nil)
            }
        }
        else{
            print( "Not authenticated" )
            block(nil)
        }
    }
    
    static func pageHifzRanges(_ pageIndex: Int, _ block: @escaping([HifzRange]?)->Void ){
        hifzList(false){ (hifzRanges) in
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
            }
        }
    }
}
