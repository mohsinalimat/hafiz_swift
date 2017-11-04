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
    var pageIndex:Int {
        get{
            if pageNumber != nil {
                return pageNumber! - 1
            }
            return -1
        }
    }

    // MARK: - Linked vars and functions
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var lineMask: UIView!
    @IBOutlet weak var ayaMask: UIView!
    @IBOutlet weak var lineMaskWidth: NSLayoutConstraint!
    @IBOutlet weak var lineMaskHeight: NSLayoutConstraint!
    @IBOutlet weak var ayaMaskHeight: NSLayoutConstraint!
    
    @IBAction func pageImageTapped(_ sender: UIGestureRecognizer) {
        //retreatMask()
        
        if QPageView.maskStart != -1 {
            let qData = QData.instance()
            let pageImageView = sender.view!
            let location = sender.location(in: pageImageView)
            let imageFrame = pageImageView.frame
            if let ayaInfo = qData.locateAya(pageMap: self.pageMap!, pageSize: imageFrame.size, location: location) {
                QPageView.maskStart = qData.ayaPosition( sura: ayaInfo.sura, aya: ayaInfo.aya )
                positionMask(false)
            }
        }
    }
    
    @IBAction func AyaMaskTapped(_ sender: Any) {
        moveMaskToCurrentPage()
        advanceMask(false)
    }

    @IBAction func PageLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            return
        }
        let qData = QData.instance()
        let pageImageView = sender.view!
        let location = sender.location(in: pageImageView)
        let imageFrame = pageImageView.frame
        if let ayaInfo = qData.locateAya(pageMap: self.pageMap!, pageSize: imageFrame.size, location: location) {
            let ayaPosition = qData.ayaPosition( sura: ayaInfo.sura, aya: ayaInfo.aya )
            if let ayaButton = pageImageView.viewWithTag(ayaPosition) {
                showAyaMenu(ayaView: ayaButton)
            }
        }
    }
    
    @IBAction func MaskLongPressed(_ sender: Any) {
        self.hideMask()
    }
    // MARK: - selector functions
    
    @objc func showTafseer(){
        performSegue(withIdentifier: "ShowTafseer", sender: clickedAya)
    }
    
    @objc func maskSelectedAya(){
        let ayaPosition = clickedAya!.tag
        QPageView.maskStart = ayaPosition
        positionMask(false)
    }
    
    @objc func onClickAyaButton(tapGestureRecognizer: UITapGestureRecognizer){
        clickedAya = tapGestureRecognizer.view
        clickedAya!.backgroundColor = .blue
        showAyaMenu(ayaView: clickedAya!)
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
        if( action == #selector(showTafseer) || action == #selector(maskSelectedAya) ){
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
        
        positionMask(false)
    }
    
    func positionMask(_ followPage: Bool ){
        let maskPageIndex = positionMask()
        if followPage && maskPageIndex != self.pageIndex {
            gotoPage(maskPageIndex)
        }else{
            self.updateViewConstraints()
        }
    }
    
    func positionMask()->Int{
        let maskAyaPosition = QPageView.maskStart
        ayaMask.isHidden = true
        lineMask.isHidden = true

        if maskAyaPosition != -1 {
            let qData = QData.instance()
            let maskStartPage = qData.pageIndex(ayaPosition: maskAyaPosition)
            let currPageIndex = self.pageIndex
            if  currPageIndex < maskStartPage {
                return maskStartPage// before masked page
            }
            ayaMask.isHidden = false
            lineMask.isHidden = false
            let imageRect = pageImage.frame
            if( currPageIndex > maskStartPage ){
                lineMask.isHidden = true
                ayaMask.frame = imageRect
                return maskStartPage
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
            return maskStartPage
        }
        return -1
    }

    func parentBrowserView()->QPagesBrowser?{
        if let parent = self.parent, let pagesBrowser = parent.parent as? QPagesBrowser {
            return pagesBrowser
        }
        return nil
    }
    
    func gotoPage(_ pageIndex: Int ){
        if pageIndex == self.pageIndex{
            return
        }
        
        if let parent = parentBrowserView(){
            parent.gotoPage( pageIndex+1 )
            return
        }
    }
    
    func advanceMask(_ followPage: Bool){
        
        switch QPageView.maskStart {
            case -1, QData.totalAyat-1:
                return
            
            default:
                let qData = QData.instance()
                if followPage {
                    //if maskStart is at first Aya of a page different than current page, goto that page and return
                    let pageLocation = qData.ayaPagePosition(QPageView.maskStart)
                    let currPageIndex = self.pageIndex
                    
                    gotoPage(pageLocation.page)

                    if pageLocation.position == .first && pageLocation.page != currPageIndex {
                        return// no need to advance the mask
                    }
                }
                QPageView.maskStart += 1
                positionMask(false)
        }
    }
    
    func retreatMask(_ followPage: Bool){
        if QPageView.maskStart != -1 && QPageView.maskStart > 0{
            let qData = QData.instance()
            if followPage {
                //if maskStart is at first Aya that is not the prior page, goto prior page and return
                let currPageIndex = self.pageIndex
                let pageLocation = qData.ayaPagePosition(QPageView.maskStart)
                
                if pageLocation.position == .first && pageLocation.page-1 != currPageIndex {
                    gotoPage(pageLocation.page-1)
                    return
                }
            }
            QPageView.maskStart -= 1
            positionMask( followPage )
        }
    }
    
    func hideMask(){
        if QPageView.maskStart != -1 {
            QPageView.maskStart = -1
            positionMask(false)
        }
    }
    
    func moveMaskToCurrentPage(){
        if QPageView.maskStart == -1 {
            return
        }
        let qData = QData.instance()
        let maskPageIndex = qData.pageIndex(ayaPosition:QPageView.maskStart)
        let currPageIndex = self.pageIndex
        if maskPageIndex > currPageIndex {
            //backward, mark top of next page
            QPageView.maskStart = qData.ayaPosition(pageIndex: currPageIndex+1)
        }else if maskPageIndex < currPageIndex {
            //forward, mark top of current page
            QPageView.maskStart = qData.ayaPosition(pageIndex: currPageIndex)
        }
    }
    
    func showAyaMenu(ayaView:UIView){
        becomeFirstResponder()
        clickedAya = ayaView
        let menuRect = CGRect(x:0, y:0, width:ayaView.frame.size.width, height:ayaView.frame.size.height)
        let mnuController = UIMenuController.shared
        mnuController.setTargetRect(menuRect, in: ayaView)
        
        mnuController.menuItems = [
            UIMenuItem(title: "Tafseer", action: #selector(showTafseer)),
            UIMenuItem(title: "Review", action: #selector(maskSelectedAya))
        ]
        
        // This makes the menu item visible.
        mnuController.setMenuVisible(true, animated: true)
        
        var hideMenuObserver:Any?
        
        hideMenuObserver = NotificationCenter.default.addObserver(forName: .UIMenuControllerDidHideMenu, object: nil, queue: nil){_ in
            //print( "onHideMenu" )
            ayaView.backgroundColor = .brown
            NotificationCenter.default.removeObserver( hideMenuObserver! )
        }
    }
}
