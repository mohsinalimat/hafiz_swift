//
//  Utils.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 10/29/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

enum ConfirmationAlertType{
    case yes, yes_destructive, ok
}

class Utils {

    static func saveSetting(_ id: String, _ val: Any ){
        let settings = UserDefaults.standard
        settings.set(val, forKey:id)
        NotificationCenter.default.post(name: AppNotifications.dataUpdated, object:nil)
    }

    static func readSetting(_ id: String )->Any?{
        let settings = UserDefaults.standard
        return settings.value(forKey: id)
    }
    
    static func getReadingStop()->Int{
        return Utils.readSetting("reading_stop") as? Int ?? 0
    }
    
    static func addToSearchHistory(_ text:String,_ results: Int = 1000 ){
        if text.count > 1 && results > 0{
            let settings = UserDefaults.standard
            var hist = settings.value(forKey: "search_history") as? [String] ?? []
            if let old = hist.index(of: text){
                hist.remove(at: old)
            }
            hist.insert(text, at: 0)
            hist = Array(hist.prefix(30))// maximum records
            //save in history
            settings.set(hist,forKey: "search_history")
        }
    }

    static func removeSearchHistory(_ text:String )->[String]{
        let settings = UserDefaults.standard
        var hist = settings.value(forKey: "search_history") as? [String] ?? []
        if let old = hist.index(of: text){
            hist.remove(at: old)
        }
        //save in history
        settings.set(hist,forKey: "search_history")
        
        return hist
    }

    static func getDataFromUrl(
        url: URL,
        block: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void
        )
    {
        
        //create the download task
        let downloadTask = URLSession.shared.dataTask( with: url ){ (data, response, error) in
            block(data, response, error) // invoke the provided callback function
        }
        
        //start the download task
        downloadTask.resume()
    }
    
    static func showNavBar(_ vc:UIViewController,_ show:Bool = true ){
        //vc.navigationController?.setNavigationBarHidden(!show, animated: true)
        vc.navigationController?.navigationBar.isHidden = !show
    }
    
    static func pathURL(dir :String, file: String?)->URL?{
        
        do{
            let fileManager = FileManager.default
            let userFolder = try fileManager.url(for: .documentDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: false)
            var pathURL = userFolder.appendingPathComponent(dir, isDirectory:true)
            if file != nil {
                pathURL = pathURL.appendingPathComponent(file!, isDirectory:false)
            }
            return pathURL
        }catch {
            print(error)
        }
        
        return nil
    }
    
    //Not working as expected, not detecting missing files
    static func fileExists(dir:String, file:String)->URL?{
        if let fileURL = pathURL(dir: dir, file:file){
            
            if FileManager.default.fileExists(atPath: fileURL.path){
                return fileURL
            }
        }
        return nil
    }
    
    static func saveData(dir:String, file:String, data:Data){
        let fileManager = FileManager.default
        if let dirURL = pathURL(dir:dir, file: nil), let fileURL = pathURL(dir:dir, file:file) {
            do{
                if !fileManager.fileExists(atPath: dirURL.path){
                    try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
                }
                try data.write(to: fileURL)
            }catch {
                print( "Failed to write the data of \(dir)/\(file)")
                print(error)
            }
        }
    }
    
    static func readData(dir:String, file:String)->Data?{
        if let fileURL = fileExists(dir: dir, file:file){
            
            do{
                let data = try Data(contentsOf: fileURL)
                return data
            }catch {
                print( "Failed to read the data of \(dir)/\(file)")
                print(error)
            }
        }
        return nil
    }
    
    static func showMessage(_ host: UIViewController, title:String,message:String){
        let alert = UIAlertController(
                        title: title,
                        message: message,
                        preferredStyle:UIAlertControllerStyle.alert
        )
        
        alert.addAction(UIAlertAction(title: AStr.ok, style: UIAlertActionStyle.default, handler: nil))
        
        host.present(alert, animated: true, completion: nil)
    }

    static func confirmMessage(
        _ host: UIViewController,
        _ title:String,
        _ message:String,
        _ type:ConfirmationAlertType,
        block: @escaping(Bool)->Void
    )
    {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle:UIAlertControllerStyle.alert
        )
        let yesTitle = (type == .yes || type == .yes_destructive ) ? AStr.yes : AStr.ok
        let noTitle = (type == .yes || type == .yes_destructive ) ? AStr.no : AStr.cancel
        let yesStyle:UIAlertActionStyle = (type == .yes_destructive) ? .destructive : .default

        alert.addAction(UIAlertAction(title: yesTitle, style: yesStyle, handler: { _ in
            block(true)
        }))

        alert.addAction(UIAlertAction(title: noTitle, style: .cancel, handler: { _ in
            block(false)
        }))

        host.present(alert, animated: true, completion: nil)
    }
    
    static func timeStamp(_ daysOffset: Double = 0)->Int64{
        let dayLength:Double = 24*60*60*1000
        return Int64( Date().timeIntervalSince1970*1000 + daysOffset * dayLength )
    }
    
    static func confirmAddSuraToHifz( vc: UIViewController, sura:Int, block: @escaping(Bool)->Void ){
        let qData = QData.instance
        
        if let suraInfo = qData.suraInfo(sura)
        {
            QData.suraHifzList(suraInfo.sura){ hifzList in
                if let hifzList = hifzList,
                    hifzList.count > 0
                {
                    //Existing partial hifz would be overwritten
                    Utils.confirmMessage(
                        vc,
                        AStr.mergeExistingHifz,
                        AStr.mergeExistingHifzDesc,
                        .yes_destructive
                    ){ yes in
                        if yes{
                            block(true)
                        }
                    }
                }
                else{
                    let isSignedIn =  QData.checkSignedIn(vc)
                    block(isSignedIn)
                }
            }
        }

    }

}
