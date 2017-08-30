//
//  DataViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class QPageView: UIViewController {

   
    //@IBOutlet weak var pageSuraName: UILabel!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var pageImage: UIImageView!
    
    var pageNumber: Int? //will be set by the ModelController that creates this controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let uPageNumber = pageNumber else {
            return;
        }
        
//        if let uData = qData, let pageSuraNameLabel = self.pageSuraName {
//            pageSuraNameLabel.text = uData.suraName(pageIndex: uPageNumber-1)
//        }

        self.pageNumberLabel!.text = String(uPageNumber)
        
        let sPageNumber = String(format: "%03d", uPageNumber)
        
        let imageUrl = URL(string:"http://www.egylist.com/qpages_1260/page\(sPageNumber).png")!
        
        getDataFromUrl(url: imageUrl) { (data, response, error) in
            
            guard let data = data, error == nil else { return }
            
            //print(response?.suggestedFilename ?? url.lastPathComponent)
            //print("Downloaded \(imageUrl)")
            
            //Apply the image data in the UI thread
            DispatchQueue.main.async() { () -> Void in
                //Set the imageView source
                self.pageImage.image = UIImage(data: data)
            }
        }
        
    }

    func getDataFromUrl(
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
