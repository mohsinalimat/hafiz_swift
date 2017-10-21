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
                }
            }
        }
        catch{
            print ("JSON load error")
        }
        
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
    
    static func encodeAya(sura:Int?,aya:Int?)->Int{
        return sura! * 1000 + aya!
    }
    static func decodeAya(_ aya:Int)->(sura:Int,aya:Int){
        return (aya/1000,aya%1000)
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
    
}
