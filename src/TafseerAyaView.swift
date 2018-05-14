//
//  TafseerAyaView.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 10/24/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class TafseerAyaView: UIViewController
{

    //@IBOutlet weak var AyaView: UITextView!
    @IBOutlet weak var tafseerTextView: UITextView!
    
    var ayaPosition:Int?
    var selectedTafseer:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let aya = ayaPosition,
            let ayaText = QData.instance.ayaText(ayaPosition: aya){
            let coloredAyaText = NSMutableAttributedString(
                string: "\n\(ayaText)\n\n",
                attributes: [
                    NSAttributedStringKey.foregroundColor: UIColor.blue,
                    NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 17)
                ]
            )
            let tafseerText = QData.getTafseer( aya, selectedTafseer ) ?? "Tafseer not found"
            let coloredTafseerText = NSAttributedString(
                string: tafseerText,
                attributes:[
                    NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)
                ]
            )
            
            coloredAyaText.append( coloredTafseerText )
            
            tafseerTextView.attributedText = coloredAyaText
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tafseerTextView.isScrollEnabled = true
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
