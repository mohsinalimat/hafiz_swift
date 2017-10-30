//
//  Utils.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 10/29/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import Foundation

class Utils {
    static func getDataFromUrl(
        url: URL,
        completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void
        )
    {
        
        let downloadTask = URLSession.shared.dataTask( with: url ){ (data, response, error) in
            completion(data, response, error)
        }
        
        downloadTask.resume()
    }
}
