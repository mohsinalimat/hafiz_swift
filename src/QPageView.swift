//
//  DataViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class QPageView: UIViewController{

    var pageNumber: Int? //will be set by the ModelController that creates this controller
    var pageMap: [[String:String]]?
    var _pageInfo: QData.PageInfo?
    var pageInfo: QData.PageInfo? {
        get{
            if _pageInfo == nil && pageIndex != -1{
                self._pageInfo = QData.instance().pageInfo(pageIndex)
            }
            return _pageInfo
        }
    }
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
    @IBOutlet weak var buttonsView: UIView!
    
    @IBOutlet weak var selectHead: UIView!
    @IBOutlet weak var selectBody: UIView!
    @IBOutlet weak var selectEnd: UIView!
    @IBOutlet weak var selectHeadHeight: NSLayoutConstraint!
    @IBOutlet weak var selectHeadY: NSLayoutConstraint!
    @IBOutlet weak var selectHeadSartX: NSLayoutConstraint!
    @IBOutlet weak var selectHeadEndX: NSLayoutConstraint!
    @IBOutlet weak var selectBodyHeight: NSLayoutConstraint!
    @IBOutlet weak var selectEndHeight: NSLayoutConstraint!
    @IBOutlet weak var selectEndX: NSLayoutConstraint!
    
    @IBAction func pageImageTapped(_ sender: UIGestureRecognizer) {
        //retreatMask()
        
        if MaskStart != -1 {
            let qData = QData.instance()
            let pageImageView = sender.view!
            let location = sender.location(in: pageImageView)
            let imageFrame = pageImageView.frame
            if let ayaInfo = qData.locateAya(pageMap: self.pageMap!, pageSize: imageFrame.size, location: location) {
                MaskStart = qData.ayaPosition( sura: ayaInfo.sura, aya: ayaInfo.aya )
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
            if let ayaButton = self.view.viewWithTag(ayaPosition) {
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
        MaskStart = ayaPosition
        positionMask(false)
    }
    
    @objc func shareAya(){
        
    }
    
    @objc func onClickAyaButton(tapGestureRecognizer: UITapGestureRecognizer){
        clickedAya = tapGestureRecognizer.view
        if MaskStart != -1 {
            MaskStart = clickedAya!.tag
            positionMask(false)
            return
        }
        selectAya( aya: clickedAya!.tag )
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
        buttonsView.isHidden = false
        loadPageImage()
        createAyatButtons()
        becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        positionAyatButtons()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if( action == #selector(showTafseer)
            || action == #selector(maskSelectedAya)
            || action == #selector(shareAya)
        ){
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
                    self.buttonsView.addSubview(btn)
                }
            }
        }
    }
    
    func positionAyatButtons(){
        let containerView = self.buttonsView!
        let imageRect = containerView.frame
        let line_height = Float(imageRect.size.height / 15)
        let line_width = Float(imageRect.size.width)

        if let pageMap = self.pageMap{
            let button_width = Float(line_width/9.6)
            
            containerView.removeConstraints(containerView.constraints)//remove existing constraints
            
            for(index, btn) in containerView.subviews.enumerated(){
                let button = pageMap[index]
                let eline = Float(button["eline"]!)!
                let epos = Float(button["epos"]!)!
                let xpos = Int( epos * line_width / 1000 - button_width )
                let ypos = Int( eline * Float(imageRect.size.height) / 15 )
                
                containerView.addSimpleConstraints("H:|-\(xpos)-[v0(\(Int(button_width)))]", views: btn)
                containerView.addSimpleConstraints("V:|-\(ypos)-[v0(\(Int(line_height)))]", views: btn)
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
        let maskAyaPosition = MaskStart
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
                lineMaskWidth.constant = CGFloat(1000 - ayaMapInfo.spos) * lineWidth / 1000
                let coveredLines = 15 - 1 - Int(ayaMapInfo.sline)
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
        
        switch MaskStart {
            case -1, QData.instance().totalAyat-1:
                return
            
            default:
                let qData = QData.instance()
                if followPage {
                    //if maskStart is at first Aya of a page different than current page, goto that page and return
                    let pageLocation = qData.ayaPagePosition(MaskStart)
                    let currPageIndex = self.pageIndex
                    
                    gotoPage(pageLocation.page)

                    if pageLocation.position == .first && pageLocation.page != currPageIndex {
                        return// no need to advance the mask
                    }
                }
                MaskStart += 1
                positionMask(false)
        }
    }
    
    func retreatMask(_ followPage: Bool){
        if MaskStart != -1 && MaskStart > 0{
            let qData = QData.instance()
            if followPage {
                //if maskStart is at first Aya that is not the prior page, goto prior page and return
                let currPageIndex = self.pageIndex
                let pageLocation = qData.ayaPagePosition(MaskStart)
                
                if pageLocation.position == .first && pageLocation.page-1 != currPageIndex {
                    gotoPage(pageLocation.page-1)
                    return
                }
            }
            MaskStart -= 1
            positionMask( followPage )
        }
    }
    
    func hideMask(){
        if MaskStart != -1 {
            MaskStart = -1
            positionMask(false)
        }
    }
    
    func moveMaskToCurrentPage(){
        if MaskStart == -1 {
            return
        }
        let qData = QData.instance()
        let maskPageIndex = qData.pageIndex(ayaPosition:MaskStart)
        let currPageIndex = self.pageIndex
        if maskPageIndex > currPageIndex {
            //backward, mark top of next page
            MaskStart = qData.ayaPosition(pageIndex: currPageIndex+1)
        }else if maskPageIndex < currPageIndex {
            //forward, mark top of current page
            MaskStart = qData.ayaPosition(pageIndex: currPageIndex)
        }
    }
    
    func showAyaMenu(ayaView:UIView){
        becomeFirstResponder()
        clickedAya = ayaView
        clickedAya!.backgroundColor = .blue
        let menuRect = CGRect(x:0, y:0, width:ayaView.frame.size.width, height:ayaView.frame.size.height)
        let mnuController = UIMenuController.shared
        mnuController.setTargetRect(menuRect, in: ayaView)
        
        mnuController.menuItems = [
            UIMenuItem(title: "Tafseer", action: #selector(showTafseer)),
            UIMenuItem(title: "Review", action: #selector(maskSelectedAya)),
            UIMenuItem(title: "Share", action: #selector(shareAya))
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
    
    func selectAya( aya: Int ){
        SelectStart = aya
        SelectEnd = aya
        positionSelection()
    }
    
    func positionSelection(){
//        selectHead.isHidden = true
//        selectBody.isHidden = true
//        selectEnd.isHidden = true
        if SelectStart == -1 {
            return
        }
        if let pageInfo = self.pageInfo {
            if SelectStart > pageInfo.ayaPos + pageInfo.ayaCount{
                return // beyond this
            }
            if SelectEnd < pageInfo.ayaPos{
                return // ended before this page
            }
            let imageRect = pageImage.frame
            let qData = QData.instance()
//            var startLine = 0
//            var endLine = 0
            let lineHeight = imageRect.height/15
            let pageWidth = imageRect.width
            selectHead.isHidden = false
            if SelectStart < pageInfo.ayaPos{
                selectHeadHeight.constant = 0
            }else{
                selectHeadHeight.constant = lineHeight
                let selectStartInfo = qData.ayaMapInfo(SelectStart, pageMap: self.pageMap!)!
                let selectEndInfo = SelectStart == SelectEnd ? selectStartInfo : qData.ayaMapInfo(SelectEnd, pageMap: self.pageMap!)!
                let ypos = imageRect.height * CGFloat(selectStartInfo.sline) / 15
                selectHeadY.constant = ypos
                let startX = (CGFloat(selectStartInfo.spos) * pageWidth) / 1000
                selectHeadSartX.constant = startX
                let endX = selectStartInfo.sline == selectEndInfo.eline && selectStartInfo.page == selectEndInfo.page ?
                    (CGFloat(1000 - selectEndInfo.epos) * pageWidth) / 1000 : 0
                selectHeadEndX.constant = endX
                
            }
            self.updateViewConstraints()
        }
        
    }
}
