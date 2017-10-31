//
//  DataViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class QPageView: UIViewController{

    static var maskStart = -1
    
    var pageNumber: Int? //will be set by the ModelController that creates this controller
    var pageMap: [[String:String]]?
    var clickedAya : UIView?

    // MARK: - Linked vars and functions
    @IBOutlet weak var pageImage: UIImageView!

    @IBAction func tabQuranImage(_ sender: Any) {
        print("Tabbed Image")
    }
    @IBOutlet weak var lineMask: UIView!
    @IBOutlet weak var ayaMask: UIView!
    @IBOutlet weak var lineMaskWidth: NSLayoutConstraint!
    @IBOutlet weak var lineMaskHeight: NSLayoutConstraint!
    @IBOutlet weak var ayaMaskHeight: NSLayoutConstraint!
    @IBAction func LineMaskTabbed(_ sender: UITapGestureRecognizer) {
        QPageView.maskStart = -1
        positionMask()

    }
    @IBAction func AyaMaskTabbed(_ sender: Any) {
        QPageView.maskStart = -1
        positionMask()
    }
    
    // MARK: - selector functions
    
    @objc func ayaTafseer(){
        performSegue(withIdentifier: "ShowTafseer", sender: clickedAya)
    }
    
    @objc func reviewAtAya(){
        let ayaPosition = clickedAya!.tag
        //let qData = QData.instance()
        QPageView.maskStart = ayaPosition
        positionMask()
        
        //TODO: notify controller to call poistionMask() for all created QPageView instances
    }
    
    @objc func onClickAyaButton(tapGestureRecognizer: UITapGestureRecognizer){
        becomeFirstResponder()
        clickedAya = tapGestureRecognizer.view
        clickedAya!.backgroundColor = .blue
        let mnuController = UIMenuController.shared
        let menuRect = CGRect(x:0, y:0, width:clickedAya!.frame.size.width, height:clickedAya!.frame.size.height)
        mnuController.setTargetRect(menuRect, in: clickedAya!)
        
        mnuController.menuItems = [
            UIMenuItem(title: "Tafseer", action: #selector(ayaTafseer)),
            UIMenuItem(title: "Review", action: #selector(reviewAtAya))
        ]
        
        // This makes the menu item visible.
        mnuController.setMenuVisible(true, animated: true)
        
        var hideMenuObserver:Any?
        
        hideMenuObserver = NotificationCenter.default.addObserver(forName: .UIMenuControllerDidHideMenu, object: nil, queue: nil){_ in
            //print( "onHideMenu" )
            self.clickedAya!.backgroundColor = .brown
            NotificationCenter.default.removeObserver( hideMenuObserver! )
        }
    }

    
    // MARK: - UIViewController overrides
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        loadPageImage()
        createAyatButtons()
        becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        positionAyatButtons()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if( action == #selector(ayaTafseer) || action == #selector(reviewAtAya) ){
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let ayaButton = sender as? UIView,
            let tafseerView = segue.destination as? TafseerViewController
        {
            tafseerView.ayaPosition = ayaButton.tag
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - QPageView new methods

    func loadPageImage(){
        
        if let pageNumber = self.pageNumber {
            //self.pageNumberLabel!.text = String(uwPageNumber)
            
            let sPageNumber = String(format: "%03d", pageNumber)
            
            let imageUrl = URL(string:"http://www.egylist.com/qpages_1260/page\(sPageNumber).png")!
            
            Utils.getDataFromUrl(url: imageUrl) { (data, response, error) in
                
                guard let data = data, error == nil else { return }
                
                //Apply the image data in the UI thread
                DispatchQueue.main.async() { () -> Void in
                    //Set the imageView source
                    self.pageImage.image = UIImage(data: data)
                }
            }
        }
    }

    func createAyatButtons(){
        if let pageNumber = self.pageNumber{
            self.pageMap = QData.pageMap( pageNumber-1 )
            let qData = QData.instance()
            if let pageMap = self.pageMap {
                for(var button) in pageMap{
                    let btn = UIView()
                    btn.semanticContentAttribute = .forceRightToLeft
                    btn.alpha = 0.3
                    btn.backgroundColor = .brown
                    btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickAyaButton)))
                    btn.isUserInteractionEnabled = true
                    btn.tag = qData.ayaPosition(sura: Int(button["sura"]!)!-1, aya: Int(button["aya"]!)!-1)
                    self.pageImage.addSubview(btn)
                }
            }
        }
    }
    
    func positionAyatButtons(){
        let imageRect = pageImage.frame
        let line_height = Float(imageRect.size.height / 15)
        let line_width = Float(imageRect.size.width)

        if let pageMap = self.pageMap{
            let button_width = Float(line_width/9.6)
            
            pageImage.removeConstraints(pageImage.constraints)//remove existing constraints
            
            for(index, btn) in self.pageImage.subviews.enumerated(){
                let button = pageMap[index]
                let eline = Float(button["eline"]!)!
                let epos = Float(button["epos"]!)!
                let xpos = Int( epos * line_width / 1000 - button_width )
                let ypos = Int( eline * Float(imageRect.size.height) / 15 )
                
                pageImage.addSimpleConstraints("H:|-\(xpos)-[v0(\(Int(button_width)))]", views: btn)
                pageImage.addSimpleConstraints("V:|-\(ypos)-[v0(\(Int(line_height)))]", views: btn)
            }
        }
        
        positionMask()
    }
    
    func positionMask(){
        let maskAyaPosition = QPageView.maskStart
        ayaMask.isHidden = true
        lineMask.isHidden = true

        if maskAyaPosition != -1 {
            let qData = QData.instance()
            let maskStartPage = qData.pageIndex(ayaPosition: maskAyaPosition)
            let currPageIndex = self.pageNumber! - 1
            if  currPageIndex < maskStartPage {
                return // before masked page
            }
            ayaMask.isHidden = false
            lineMask.isHidden = false
            let imageRect = pageImage.frame
            if( currPageIndex > maskStartPage ){
                lineMask.isHidden = true
                ayaMask.frame = imageRect
                return
            }
            
            if let ayaMapInfo = qData.ayaMapInfo(maskAyaPosition, pageMap: self.pageMap!){
                let pageHeight = imageRect.size.height
                let lineHeight = CGFloat(pageHeight / 15)
                let lineWidth = CGFloat(imageRect.size.width)
                lineMaskHeight.constant = lineHeight
                lineMaskWidth.constant = CGFloat(1000 - Int(ayaMapInfo["spos"]!)!) * lineWidth / 1000
                let coveredLines = 15 - 1 - Int(ayaMapInfo["sline"]!)!
                //print( "Aya\(ayaMapInfo["aya"]!) - Covered Lines\(coveredLines)" )
                ayaMaskHeight.constant = CGFloat(CGFloat(coveredLines) * pageHeight) / 15
            }

        }
    }

}
