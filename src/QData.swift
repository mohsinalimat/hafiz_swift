//
//  QData.swift
//  test
//
//  Created by Ramy Eldesoky on 8/4/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

typealias AyaInfo = (sura:Int, aya:Int, page:Int)
typealias AyaFullInfo = (sura:Int, aya: Int,page: Int, sline:Int, spos:CGFloat, eline:Int, epos:CGFloat)
typealias AyaRecord = (sura:String,aya: String, aya_text: String, page: String)


class QData{
    var suraInfo:[[String:Int]]?
    var partInfo:[[String:Int]]?
    var pagesInfo:[[String:Int]]?
    var suraNames:NSDictionary?
    var quranData:NSArray?
    var normalizedText:NSArray?
    var normalizedSuraNames:[String]?
    var quranText:NSArray?
    
    let totalAyat = 6236
    let lastPage = 603
    
    enum Direction {
        case forward
        case backward
    }
    enum Position {
        case first
        case inside
        case last
    }

    typealias PageInfo = (suraIndex:Int, ayaIndex:Int, ayaPos:Int, ayaCount:Int)
    typealias AyaPagePosition = (page:Int, position:Position)

    init(){
        do{
            if let path = Bundle.main.url(forResource: "qdata", withExtension: "json")
            {
                let jsonData = try Data(contentsOf: path)
                
                let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])
                
                if let object = json as? [String: Any] {
                    // json is a dictionary
                    if let suraInfo = object["sura_info"] {
                        self.suraInfo = suraInfo as? [[String : Int]]
                    }
                    if let partInfo = object["parts"]{
                        self.partInfo = partInfo as? [[String : Int]]
                    }
                    if let pagesInfo = object["pagesInfo"]{
                        self.pagesInfo = pagesInfo as? [[String : Int]]
                    }
                }
            }
        }
        catch{
            print ("JSON load error")
        }
        
    }
    
    static var qData: QData?
    
    class func instance()->QData{
        if let inst = qData {
            return inst
        }
        qData = QData()
        return qData!
    }
    
    class func pageMap(_ pageIndex:Int)->[[String:String]]{
        do{
            if let path = Bundle.main.url(forResource: "pg_map/pm_\(pageIndex+1)", withExtension: "json")
            {
                let jsonData = try Data(contentsOf: path)
                let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])

                if let object = json as? [String: Any] {
                    // json is a dictionary
                    if let suraInfo = object["child_list"] {
                        return (suraInfo as? [[String : String]])!
                    }
                }
            }
        }
        catch{
            print ("JSON load error")
        }
        return []
    }
    
    func ayaMapInfo(_ ayaPosition:Int, pageMap: [[String:String]])->AyaFullInfo?{
        let (suraIndex,ayaIndex) = self.ayaLocation(ayaPosition)
        for ayaInfo in pageMap{
            let (s,a) = ( Int(ayaInfo["sura"]!)! - 1, Int(ayaInfo["aya"]!)! - 1 )
            if s == suraIndex  && a == ayaIndex {
                return QData.ayaFullInfo(ayaInfo)
            }
        }
        return nil
    }
    
    func pageInfo(_ pageIndex: Int )->QData.PageInfo? {
        if self.pagesInfo == nil || pageIndex < 0 || pageIndex > self.lastPage{
            return nil
        }
        let info = self.pagesInfo![pageIndex]
        let suraIndex = info["s"]! - 1
        let ayaIndex = info["a"]! - 1
        let startAya = ayaPosition(sura: suraIndex, aya: ayaIndex)
        let nextPageStartAya = pageIndex < self.lastPage ? ayaPosition(pageIndex: pageIndex+1) : self.totalAyat

        return (
            suraIndex:suraIndex,
            ayaIndex:ayaIndex,
            ayaPos:startAya,
            ayaCount:nextPageStartAya-startAya
        )
    }
    
    func ayaMapInfo(_ ayaPosition:Int, pageIndex: Int )->AyaFullInfo?{
        let pageMap = QData.pageMap( pageIndex )
        return ayaMapInfo(ayaPosition, pageMap: pageMap)
    }
    
    func ayaPosition( pageIndex: Int )->Int{
        let pageInfo = self.pagesInfo![pageIndex]
        return ayaPosition(sura: pageInfo["s"]!-1, aya: pageInfo["a"]!-1)
    }
    
    func ayaPosition( sura:Int, aya:Int )->Int{
        var index = 0
        for suraIndex in 0..<sura{
            if let suraInfo = self.suraInfo(suraIndex:suraIndex) {
                index += suraInfo["ac"]!
            }
        }
        return index+aya
    }
    
    func ayaLocation(_ index:Int )->(sura:Int,aya:Int){
        var suraStartIndex = 0
        if let suras = self.suraInfo {
            for suraIndex in 0..<114{
                let suraInfo = suras[suraIndex]
                if suraStartIndex + suraInfo["ac"]! > index {
                    return (suraIndex, index-suraStartIndex)
                }
                suraStartIndex+=suraInfo["ac"]!
            }
        }
        return (0,0)
    }
    
    func suraIndex( pageIndex: Int, direction: Direction = .forward )->Int{
        if let suraInfoList = self.suraInfo {
            //let seq = suraInfoList.enumerated()
            let seq = (direction == .backward) ? suraInfoList.reversed().enumerated() : suraInfoList.enumerated()
            for (suraIndex, suraInfo) in seq  {
                if let ep = suraInfo["ep"], let sp = suraInfo["sp"]{
                    if(direction == .backward){
                        if sp <= pageIndex{
                            return suraInfoList.count - suraIndex
                        }
                    }else{
                        if ep > pageIndex{
                            return suraIndex
                        }
                    }
                }
            }
            return direction == .backward ? 0 : suraInfoList.count - 1 //return first or last sura
        }
        return 0
    }
    
    func partIndex(pageIndex: Int) -> Int{
        
        for (n,pInfo) in self.partInfo!.enumerated() {
            if let pNumber = pInfo["p"] {
                if pNumber-1 >= pageIndex {
                    return n
                }
            }
        }
        return 0
    }
    
    func suraIndex(partIndex: Int) -> Int{
        if let partInfo = self.partInfo(partIndex:partIndex){
            return partInfo["s"]! - 1
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
//                for pos in 0..<quranData!.count{
//                    if var ayaInfo = quranData![pos] as? [String:String]{
//                        normalizedText.append(ayaInfo["aya_text"]!.normalizeAya())
//                    }
//                }
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
            return suraNames[String(suraIndex+1)] as? String
            //return suraNames.value( forKey: String(suraIndex+1) ) as? String
        }

        return nil
    }
    
    func readSuraNames() -> NSDictionary?{
        if suraNames == nil {
            if let path = Bundle.main.path(forResource: "SuraNames", ofType: "plist") {
                suraNames = NSDictionary(contentsOfFile: path) //cache suraNames NSDictionary
            }
        }
        return suraNames
    }
    
    func readNormalizedSuraNames()-> [String]?{
        if normalizedSuraNames == nil {
            if let suraNames = readSuraNames(){
                normalizedSuraNames = []

                for i in 0..<suraNames.count {
                    if let name = suraNames[String(i+1)] as? String {
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
            return partInfo["p"]! - 1
        }
        return 0
    }
    
    func pageIndex( suraIndex: Int )-> Int{
        if let suraInfo = self.suraInfo(suraIndex:suraIndex){
            return suraInfo["sp"]! - 1
        }
        return 0
    }
    
    func pageIndex( ayaPosition: Int )->Int{
        let (suraIndex,ayaIndex) = self.ayaLocation(ayaPosition)
        let pageIndex = self.pageIndex(suraIndex: suraIndex)
        for p in pageIndex...lastPage {
            let pageInfo = pagesInfo![p]
            let pageSuraIndex = pageInfo["s"]! - 1
            let pageStartAyaIndex = pageInfo["a"]! - 1
            if ( pageSuraIndex > suraIndex )
                || ( pageSuraIndex == suraIndex && pageStartAyaIndex > ayaIndex )
            {
                return p-1
            }
        }
        return lastPage
    }
    
    func partInfo( partIndex: Int ) -> [String:Int]?{
        if let parts = self.partInfo{
            if(partIndex<parts.count){
                return parts[partIndex]
            }
        }
        return nil
    }
    
    func suraInfo( suraIndex: Int ) -> [String:Int]?{
        if let suras = self.suraInfo{
            if(suraIndex<suras.count){
                return suras[suraIndex]
            }
        }
        return nil
    }
    
    func ayaCount( suraIndex: Int ) -> Int?{
        if let suraInfo = suraInfo(suraIndex:suraIndex) {
            return suraInfo["ac"]
        }
        return nil
    }

    func locateAya( pageMap:[[String:String]], pageSize: CGSize, location: CGPoint )->AyaFullInfo?{
        let line = Int(location.y * 15 / pageSize.height)
        let line_pos = 1000 - (location.x * 1000) / pageSize.width
        for ayaMap in pageMap {
            let ayaInfo = QData.ayaFullInfo(ayaMap)
            
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
    
    func pageAya( at: Position, pageMap: [[String:String]] ) -> Int {
        var ayaMapInfo:[String:String]?
        
        if at == .first {
            ayaMapInfo = pageMap.first
        }
        if at == .last {
            ayaMapInfo = pageMap.last
        }
        if let ayaMapInfo = ayaMapInfo {
            return self.ayaPosition(sura: Int(ayaMapInfo["sura"]!)!-1, aya: Int(ayaMapInfo["aya"]!)!-1)
        }
        return -1
    }
    
    func ayaPagePosition(_ ayaPosition : Int )-> AyaPagePosition{
        let (sura,aya) = self.ayaLocation(ayaPosition)
        let pageIndex = self.pageIndex(ayaPosition: ayaPosition)
        let pageMap = QData.pageMap(pageIndex)
        let firstPageAya = pageMap.first!
        
        if sura == Int(firstPageAya["sura"]!)!-1 && aya == Int(firstPageAya["aya"]!)!-1 {
            return (page: pageIndex, position: .first)
        }

        let lastPageAya = pageMap.last!
        if sura == Int(lastPageAya["sura"]!)!-1 && aya == Int(lastPageAya["aya"]!)!-1 {
            return (page: pageIndex, position: .last)
        }
        return (page: pageIndex, position: .inside)
    }
}
