//
//  Extensions.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 10/29/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

extension String {
    func extract(_ pattern: String ) -> [String]{
        let s = self
        let ns = NSString(string:self)
        let regex = try! NSRegularExpression(pattern: pattern,options:[.dotMatchesLineSeparators,.caseInsensitive])
        let results = regex.matches(in:s, options:[], range: NSMakeRange(0, s.utf16.count))
        return results.map {
            result in
            //result.rangeAt(<#T##idx: Int##Int#>)
            //ns.substring(with: result.range)
            //TODO: Enum all ranges
            ns.substring(with: result.range(at: 1))
        }
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
}

