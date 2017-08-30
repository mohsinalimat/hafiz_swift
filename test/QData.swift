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
                }
//                else if let object = json as? [Any] {
//                    // json is an array
//                    print(object)
//                }
//                else {
//                    print("JSON is invalid")
//                }
            }
        }
        catch{
            print ("JSON load error")
        }
        
    }
    
    func suraIndex( pageIndex: Int)->Int{
        if let suraInfoList = self.suraInfo {
            for (index, suraInfo) in suraInfoList.enumerated() {
                if let ep = suraInfo["ep"]{
                    if ep > pageIndex{
                        return index
                    }
                }
            }
        }
        return 0
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
    
}
