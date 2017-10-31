//
//  QData.swift
//  test
//
//  Created by Ramy Eldesoky on 8/4/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import Foundation

class QData{
    var suraInfo:[[String:Int]]?
    var partInfo:[[String:Int]]?
    var pagesInfo:[[String:Int]]?
    
    static let totalAyat = 6236
    let lastPage = 603
    
    enum Direction {
        case forward
        case backward
    }
    
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
    
    static func instance()->QData{
        if let inst = qData {
            return inst
        }
        qData = QData()
        return qData!
    }
    
    static func pageMap(_ pageIndex:Int)->[[String:String]]{
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
    
    func ayaMapInfo(_ ayaPosition:Int, pageMap: [[String:String]])->[String:String]?{
        let (suraIndex,ayaIndex) = self.ayaLocation(ayaPosition)
        for ayaInfo in pageMap{
            let (s,a) = ( Int(ayaInfo["sura"]!)! - 1, Int(ayaInfo["aya"]!)! - 1 )
            if s == suraIndex  && a == ayaIndex {
                return ayaInfo
            }
        }
        return nil
    }
    
    func ayaMapInfo(_ ayaPosition:Int, pageIndex: Int )->[String:String]?{
        let pageMap = QData.pageMap( pageIndex )
        return ayaMapInfo(ayaPosition, pageMap: pageMap)
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
    
    
    func suraName( suraIndex: Int ) -> String? {
        if let path = Bundle.main.path(forResource: "SuraNames", ofType: "plist") {
            if let suraNames = NSDictionary(contentsOfFile: path){
                //return suraNames.value( forKey: String(suraIndex+1) ) as? String
                return suraNames[String(suraIndex+1)] as? String
            }
        }
        return nil
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
            if pageInfo["s"]! > (suraIndex+1) || pageInfo["a"]! > (ayaIndex+1) {
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
    
}
