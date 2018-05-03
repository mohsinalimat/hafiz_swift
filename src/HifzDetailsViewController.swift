//
//  HifzDetailsViewController.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 5/3/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit

class HifzDetailsViewController: UIViewController {

    var hifzRange: HifzRange?
    
    @IBOutlet weak var hifzTitle: UILabel!
    @IBOutlet weak var hifzDetails: UILabel!
    @IBOutlet weak var firstAya: UILabel!
    
    @IBAction func markAsRevised(_ sender: Any) {
        //can't test before figuring out how to signout from my main account
//        if let hifzRage = self.hifzRange{
//            let _ = QData.promoteHifz(hifzRage){ (info:NSDictionary?) in
//                if let info = info {
//                    print( info )
//                }
//            }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let hifzRange = self.hifzRange{
            let qData = QData.instance()
            let ayaPos = qData.ayaPosition(pageIndex: hifzRange.page, suraIndex: hifzRange.sura)
            hifzTitle.text = qData.suraName(suraIndex: hifzRange.sura)
            firstAya.text = qData.ayaText(ayaPosition: ayaPos)
            hifzDetails.text = "\(hifzRange.count) pages from page \(hifzRange.page)\n\(hifzRange.age) days"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }
    
    func setHifzRange(_ hifzRange: HifzRange){
        self.hifzRange = hifzRange
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if  let hifzRange = self.hifzRange,
            let pageBrowser = segue.destination as? QPagesBrowser
        {
            let qData = QData.instance()
            let ayaPos = qData.ayaPosition(pageIndex: hifzRange.page, suraIndex: hifzRange.sura)
            
            pageBrowser.startingPage = hifzRange.page + 1
            
            SelectStart = ayaPos
            SelectEnd = ayaPos
            
            if segue.identifier == "ReviseHifz" {
                MaskStart = ayaPos
            }
        }
    }

}
