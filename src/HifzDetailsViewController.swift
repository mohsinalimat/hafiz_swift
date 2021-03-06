//
//  HifzDetailsViewController.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 5/3/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import UIKit
import Firebase

class HifzDetailsViewController: UIViewController {

    var hifzRange: HifzRange?
    
    @IBOutlet weak var hifzTitle: UILabel!
    @IBOutlet weak var hifzDetails: UILabel!
    @IBOutlet weak var firstAya: UILabel!
    
    @IBAction func markAsRevised(_ sender: Any) {
        if let hifzRage = self.hifzRange{
            let _ = QData.promoteHifz(hifzRage){ updatedHifzRange in
                self.setHifzRange(updatedHifzRange)
                self.updateViews()
                
                Utils.showMessage(
                    self,
                    title: AStr.revisionSaved,
                    message: AStr.goodJob
                )
            }
        }
    }
    
    @IBAction func removeFromHifz(_ sender: UIButton) {
        if let hifzRange = self.hifzRange {
            Utils.confirmMessage(
                self,
                "Confirm Remove Hifz",
                "{{hifzDescription}}", .yes_destructive
            ){ isYes in
                if isYes {
                    QData.deleteHifz([hifzRange],true){snapshot in
                        Utils.showMessage(
                            self,
                            title: "Hifz Deleted",
                            message: "This part has been deleted from your Hifz"
                        )
                    }
                }
            }

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //navigationController?.setNavigationBarHidden(false, animated: true)
        Utils.showNavBar(self)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func setHifzRange(_ hifzRange: HifzRange){
        self.hifzRange = hifzRange
    }
    
    func updateViews(){
        if let hifzRange = self.hifzRange{
            let qData = QData.instance
            let ayaPos = qData.ayaPosition(pageIndex: hifzRange.page, suraIndex: hifzRange.sura)
            hifzTitle.text = qData.suraName(suraIndex: hifzRange.sura)?.name ?? "missing"
            firstAya.text = qData.ayaText(ayaPosition: ayaPos)
            hifzDetails.text = QData.describe(hifzTitle: hifzRange)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if  let hifzRange = self.hifzRange
            //,let pageBrowser = segue.destination as? QPagesBrowser
        {
            let qData = QData.instance
            let ayaPos = qData.ayaPosition(pageIndex: hifzRange.page, suraIndex: hifzRange.sura)
            
            //pageBrowser.startingPage = hifzRange.page + 1
            
            SelectStart = ayaPos
            SelectEnd = ayaPos
            
            if segue.identifier == "ReviseHifz" {
                MaskStart = ayaPos
            }
        }
    }

}
