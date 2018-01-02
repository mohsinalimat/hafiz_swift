//
//  TafseerAyaView.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 10/24/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class TafseerAyaView: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var AyaView: UITextView!
    @IBOutlet weak var AyaWebView: UIWebView!
    @IBOutlet weak var LoadingIndicator: UIActivityIndicatorView!
    
    var AyaPosition:Int?
    var selectedTafseer = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        AyaWebView.delegate = self
        let qData = QData.instance()
        let (suraIndex,ayaIndex) = qData.ayaLocation( AyaPosition! )
        
        //let suraName = uQData.suraName(suraIndex:suraIndex)!
        //TafseerTitle.text = "Tafseer: \(suraName), Aya: \(ayaIndex+1)"
        
        let sSura = String(format: "%03d", suraIndex+1)
        let sAya = String(format: "%03d", ayaIndex+1)
        let tafseerKey = TafseerSources[selectedTafseer]
        let sURL = (selectedTafseer < 4) ? "http://www.egylist.com/quran/get_taf_utf8.pl?/quran/tafseer/\(tafseerKey)/\(sSura)\(sAya).html" : "http://www.egylist.com/quran/get_db_taf.pl?src=\(tafseerKey)&s=\(suraIndex+1)&a=\(ayaIndex+1)"
        let tafseerUrl = URL(string:sURL)!
        AyaWebView.loadRequest(URLRequest(url:tafseerUrl))
        LoadingIndicator.startAnimating()
        
//        let downloadTask = URLSession.shared.dataTask(with: tafseerUrl){ (data, response, error) in
//            if error == nil {
//                if let str = String(data: data!, encoding: .utf8) { // build a string from utf8 encoded data
//                    let str = str.replacingOccurrences(of: "=100%", with: "=\"100%\"")
//                    let matches = str.extract("<body.*?>(.*)<\\/body>")//custom string extension that extracts regex placeholders
//                    let body = matches[0]
//                    //TODO: too slow with large string, move it outside UI thread to avoid blocking
//                    //let attrText = "<style>*{font-size:20px; direction:rtl}</style>\(body)".convertHtml()
//                    let attrText = body.convertHtml()
//                    DispatchQueue.main.async(){
//                        //Also slow
//                        self.AyaView.attributedText = attrText
//                        self.LoadingIndicator.stopAnimating()
//                    }
//                }
//            }
//        }
//        downloadTask.resume()
    }
    
    // MARK: UIWebView delegate methods
    func webViewDidFinishLoad(_ webView: UIWebView) {
        LoadingIndicator.stopAnimating()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
