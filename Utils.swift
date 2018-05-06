//
//  Utils.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 10/29/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class Utils {
    static func getDataFromUrl(
        url: URL,
        completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void
        )
    {
        
        //create the download task
        let downloadTask = URLSession.shared.dataTask( with: url ){ (data, response, error) in
            completion(data, response, error) // invoke the provided callback function
        }
        
        //start the download task
        downloadTask.resume()
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
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        host.present(alert, animated: true, completion: nil)
    }
    
    static func timeStamp()->Int64{
        return Int64(Date().timeIntervalSince1970*1000)
    }

}
