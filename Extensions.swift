//
//  Extensions.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 10/29/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

public enum AlertActions {
    case revise, bookmark,addUpdateHifz, addHifzSelectSura, addHifzSelectRange, revisedHifz, removeHifz
    case signOut, signIn, changeLang
    case arabic, english
}


extension String {
    func extract(_ pattern: String ) -> [String]{
        let s = self
        let ns = NSString(string:self)
        let regex = try! NSRegularExpression(pattern: pattern,options:[.dotMatchesLineSeparators,.caseInsensitive])
        let results = regex.matches(in:s, options:[], range: NSMakeRange(0, s.utf16.count))
        return results.map { result in
            //result.rangeAt(idx:Int)
            //ns.substring(with: result.range)
            //TODO: Enum all ranges
            ns.substring(with: result.range(at: 1))
        }
    }
    
    func match(_ regex: String ) -> Bool {
        do{
            let regex = try NSRegularExpression(pattern: regex)
            let result = regex.matches(in:self,range:NSRange(self.startIndex..., in:self))
            //return results.map { String(text[Range($0.range, in: text)!])} //returns array of string matches
            return result.count>0
        }
        catch {
            print("Invalid RegEx:( \(regex) ) ")
        }
        return false
    }
    
    func replaceRegEx(_ find_regex: String,_ repl: String)->String{
        let regex = try! NSRegularExpression(pattern: find_regex, options:[])
        let range = NSMakeRange(0, self.utf16.count)
        let ret = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: repl)
        return ret
    }
    
    func normalizeAya()->String{
        return self.replaceRegEx("[\\u0622\\u0623\\u0625\\ufe8d\\ufe8e\\ufe81\\ufe82]" ,"ا")//Alef and Hamza
            .replaceRegEx("[\\u06d9\\ufef5\\ufef6\\ufef7\\ufef8\\ufef9\\ufefa\\ufefb\\ufefc]" ,"لا")//Lam-alef
            .replaceRegEx("[\\u0676\\u0624]" ,"و")//Waw
            .replaceRegEx("[\\u0629\\ufe93\\ufe94]","ه")//Haa
            .replaceRegEx("[\\u064a\\ufef1\\ufef2\\ufef4\\ufef3\\u0626]" ,"ى")//Yaa
            .replaceRegEx(" +"," ")//replace double space with one
            .replaceRegEx("[\\u064B\\u064C\\u064D\\u064E\\u064F\\u0650\\u0651\\u0652\\u0653\\u0654\\u0655\\u0656\\u0657\\u0658\\u0659\\u065A\\u065B\\u065C\\u065D\\u065E\\u065F\\u0670]", "")//remove tashkeel

    }
    
    func convertHtml() -> NSAttributedString{
        guard let data = data(using: .utf8)
            else {
                return NSAttributedString()
        }
        
        do{
            return try NSAttributedString(
                data: data,
                options: [
                    NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
                    NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
        }catch{
            return NSAttributedString()
        }
    }
}

extension UIView {
    func addSimpleConstraints(_ format:String, views: UIView... ){
        
        var dict = [String:UIView]()
        
        for (index,view) in views.enumerated(){
            view.translatesAutoresizingMaskIntoConstraints = false
            let key = "v\(index)"
            dict[key] = view
        }
        
        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: format,
                options: NSLayoutFormatOptions(),
                metrics: nil,
                views: dict
            )
        )
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as? UIViewController
            }
        }
        return nil
    }
}

public protocol UIActionAlertsManager {
    
    /// Delegate would implement the actions invoked by UIActionsAlert
    ///
    /// - Parameters:
    ///   - id: action ID
    ///   - selection: any associated object
    func handleAlertAction(_ id: AlertActions,_ selection: Any? )
}

extension UIViewController{
    /// A utility function to present a group of action items in a slid in alert
    ///
    /// - Parameters:
    ///   - actions: List of actions for user to select from
    ///   - title: Optional sheet text
    ///   - msg: Optional sheet message text
    func showAlertActions( _ actions:[UIAlertAction?],_ title:String? = nil, msg:String? = nil){
        
        //create the controller
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .actionSheet)
        
        //loop to add all actions
        actions.forEach{(action) in
            if let action = action {
                alertController.addAction(action)
            }
        }
        
        //Add the cancel action
        alertController.addAction( UIAlertAction(title: "Cancel", style: .cancel) )
        
        //show the actions
        self.present(alertController, animated: true)
    }
    
    /// A utility function to create an action object
    ///
    /// - Parameters:
    ///   - id: Action ID enum choice
    ///   - title: The text to display in the list
    ///   - selection: An associated data
    /// - Returns: the action item to append to UIAlertController
    func alertAction(_ id:AlertActions,_ title:String,_ selection:Any? = nil)->UIAlertAction{
        return UIAlertAction(title: title, style: .default, handler: { (action) in
            if let manager = self as? UIActionAlertsManager{
                manager.handleAlertAction(id, selection)
            }
        })
    }

}
