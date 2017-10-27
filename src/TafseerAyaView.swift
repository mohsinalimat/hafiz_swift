//
//  TafseerAyaView.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 10/24/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class TafseerAyaView: UIViewController {

    @IBOutlet weak var AyaView: UITextView!
    var AyaPosition:Int?
    var selectedTafseer = "KATHEER"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // Do any additional setup after loading the view.
        let qData = QData.instance()
        //let (suraIndex,ayaIndex) = QData.decodeAya(uAyaLocation)
        let (suraIndex,ayaIndex) = qData.ayaLocation( AyaPosition! )
        
        //let suraName = uQData.suraName(suraIndex:suraIndex)!
        //TafseerTitle.text = "Tafseer: \(suraName), Aya: \(ayaIndex+1)"
        
        
        let sSura = String(format: "%03d", suraIndex+1)
        let sAya = String(format: "%03d", ayaIndex+1)
        let tafseerUrl = URL(string:"http://www.egylist.com/quran/get_taf_utf8.pl?/quran/tafseer/\(selectedTafseer)/\(sSura)\(sAya).html")!
        //let tafseerUrl = URL(string:"http://www.egylist.com/quran/get_db_taf.pl?src=en_yusufali&s=\(suraIndex+1)&a=\(ayaIndex+1)")!
        
        let downloadTask = URLSession.shared.dataTask(with: tafseerUrl){ (data, response, error) in
            if error == nil {
                if let str = String(data: data!, encoding: .utf8) {
                    let str = str.replacingOccurrences(of: "=100%", with: "=\"100%\"")
                    let matches = str.extract("<body.*?>(.*)<\\/body>")
                    DispatchQueue.main.async(){
                        //TODO: too slow with large string, move it outside UI thread to avoid blocking
                        self.AyaView.attributedText = "<style>*{font-size:20px; direction:rtl}</style>\(matches[0])</div>".convertHtml()
                    }
                    //print( matches )
                }
            }
        }
        downloadTask.resume()
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
