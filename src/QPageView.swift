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
    var sneekViewWidth : CGFloat = 0


    // MARK: - Linked vars and functions
    @IBOutlet weak var pageImage: UIImageView!
    
    @IBOutlet weak var maskHead: UIView!
    @IBOutlet weak var maskBody: UIView!
    @IBOutlet weak var maskHeadStartX: NSLayoutConstraint!
    @IBOutlet weak var maskHeadHeight: NSLayoutConstraint!
    @IBOutlet weak var maskBodyHeight: NSLayoutConstraint!
    
    @IBOutlet weak var selectHead: UIView!
    @IBOutlet weak var selectBody: UIView!
    @IBOutlet weak var selectEnd: UIView!
    @IBOutlet weak var selectHeadHeight: NSLayoutConstraint!
    @IBOutlet weak var selectHeadY: NSLayoutConstraint!
    @IBOutlet weak var selectHeadSartX: NSLayoutConstraint!
    @IBOutlet weak var selectHeadEndX: NSLayoutConstraint!

    @IBOutlet weak var selectBodyBottomY: NSLayoutConstraint!
    @IBOutlet weak var selectEndHeight: NSLayoutConstraint!
    @IBOutlet weak var selectEndX: NSLayoutConstraint!
    
    @IBOutlet var pageTapGesture: UITapGestureRecognizer!
    @IBOutlet weak var buttonsView: LayerView!
    
    @IBAction func pageImageTapped(_ sender: UIGestureRecognizer) {
        //retreatMask()
        
        if MaskStart != -1 {
            let qData = QData.instance()
            let pageImageView = sender.view!
            let location = sender.location(in: pageImageView)
            let imageFrame = pageImageView.frame
            if let ayaInfo = qData.locateAya(pageMap: self.pageMap!, pageSize: imageFrame.size, location: location) {
                setMaskStart( qData.ayaPosition( sura: ayaInfo.sura, aya: ayaInfo.aya ) )
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
                selectAya( aya: ayaPosition )
                showAyaMenu(ayaView: ayaButton)
            }
        }
    }
    
    @IBAction func MaskLongPressed(_ sender: Any) {
        //self.hideMask()
    }
    // MARK: - selector functions
    
    @objc func showTafseer(){
        performSegue(withIdentifier: "ShowTafseer", sender: clickedAya)
    }
    
    @objc func maskSelectedAya(){
        setMaskStart( clickedAya!.tag )
    }
    
    @objc func shareAya(){
        let qData = QData.instance()
        if let ayaText = qData.ayaText(ayaPosition: clickedAya!.tag){
            print (ayaText)
        }
    }
    
    @objc func onClickAyaButton(sender: UITapGestureRecognizer){
        clickedAya = sender.view
        if sender.state == .began {
            if let clickedAya = clickedAya {
                if MaskStart == clickedAya.tag {
                    self.sneekViewWidth = 60
                    maskHeadStartX.constant = maskHeadStartX.constant + 60
                    //self.updateViewConstraints()
                    return
                }
            }
        }else if sender.state == .ended{
            if let clickedAya = clickedAya {
                let ayaId = clickedAya.tag
                if MaskStart == ayaId {
                    maskHeadStartX.constant = maskHeadStartX.constant - 60
                    self.sneekViewWidth = 0
                    //self.updateViewConstraints()
                    return
                }
                if MaskStart != -1 {
                    if MaskStart < ayaId {//touching inside the mask
                        moveMaskToCurrentPage()
                        advanceMask(false)
                    }else{//touching above the mask
                        setMaskStart(ayaId)
                    }
                    return
                }
                selectAya( aya: ayaId )
                showAyaMenu(ayaView: clickedAya)
            }
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
        print ( "QPageView viewDidLoad()" )
        loadPageImage()
        createAyatButtons()
        becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print ( "QPageView viewWillAppear(pg:\(pageNumber!)) " )
        navigationController?.navigationBar.isHidden = true
        pageTapGesture.isEnabled = (MaskStart != -1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.positionMask(followPage: false)
            self.viewDidLayoutSubviews()
        }
    }
    
    override func viewDidLayoutSubviews() {
        print ( "QPageView viewDidLayoutSubviews(pg:\(pageNumber!))" )
        positionAyatButtons()
        positionSelection()
    }
    
    override func viewWillLayoutSubviews() {
        print ( "QPageView viewWillLayoutSubviews(pg:\(pageNumber!))" )
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
    
    //TODO: parent controller has the same implementation
    //Parent controller only call setMaskStart upon ending the mask from navigationBar X button
    
    func setMaskStart(_ ayaId:Int, followPage:Bool = false ){
        if let pageBrowser = self.parentBrowserView(){
            pageBrowser.setMaskStart( ayaId, followPage: followPage )
        }
        //Parent controller dosn't have access to pageTabGesture
        //pageTapGesture.isEnabled = ( ayaId != -1 )
        //navigationController?.navigationBar.isHidden = true
    }

    func createAyatButtons(){
        if let pageNumber = self.pageNumber{
            self.pageMap = QData.pageMap( pageNumber-1 )
            let qData = QData.instance()
            if let pageMap = self.pageMap {
                for(var button) in pageMap{
                    let btn = UIView()
                    btn.backgroundColor = .brown
                    btn.alpha = 0.20
                    btn.layer.cornerRadius = 5
                    let tap = UILongPressGestureRecognizer(target: self, action: #selector(onClickAyaButton))
                    btn.addGestureRecognizer(tap)
                    tap.minimumPressDuration = 0
                    btn.isUserInteractionEnabled = true
                    btn.tag = qData.ayaPosition(sura: Int(button["sura"]!)! - 1, aya: Int(button["aya"]!)! - 1)
                    self.buttonsView.addSubview(btn)
                }
                print ("createAyatButtons-> pg:\(pageNumber) count:\(pageMap.count)")
            }
        }
    }
    
    func positionAyatButtons(){
        let containerView = self.buttonsView!
        let imageRect = containerView.frame
        let line_height = CGFloat(imageRect.size.height / 15)
        let line_width = CGFloat(imageRect.size.width)
        
        print ( "positionAyatButton-> pg: \(self.pageNumber!), h: \(line_height), w: \(line_width) " )

        if let pageMap = self.pageMap{
            let button_width = CGFloat(line_width/9.65)
            
            containerView.removeConstraints(containerView.constraints)//remove existing constraints
            
            for(index, btn) in containerView.subviews.enumerated(){
                let button = pageMap[index]
                let eline = CGFloat(Float(button["eline"]!)!)
                let epos = CGFloat(Float(button["epos"]!)!)
                let xpos = CGFloat( epos * line_width / 1000 - button_width )
                let ypos = CGFloat( eline * CGFloat(imageRect.size.height) / 15 )
                var rect = CGRect(x: xpos, y: ypos, width: button_width, height: line_height)
                rect = rect.insetBy(dx: 3, dy: 3)
                
                containerView.addSimpleConstraints("H:|-\(rect.origin.x)-[v0(\(rect.size.width))]", views: btn)
                containerView.addSimpleConstraints("V:|-\(rect.origin.y)-[v0(\(rect.size.height))]", views: btn)
            }
        }
        
        positionMask(followPage: false)
    }
    
    //TODO: parent controller has similar method doing the same thing
    func positionMask( followPage: Bool ){
        let maskPageIndex = positionMask()
        if followPage && maskPageIndex != self.pageIndex {
            gotoPage(maskPageIndex)
        }else{
            self.updateViewConstraints()//force refreshing the current page
        }
    }

    //Rearrange the mask and aya buttons views and return the mask start page
    func positionMask()->Int{
        let maskAyaPosition = MaskStart
        maskBody.isHidden = true
        maskHead.isHidden = true

        if let buttonsView = self.buttonsView{
            for(_, btn) in buttonsView.subviews.enumerated(){
                let ayaId = btn.tag
                btn.alpha = ayaId == MaskStart ? 1 : 0.25
                if let txtBtn = btn as? UITextView{
                    txtBtn.textColor = ayaId == MaskStart ? .white : .brown
                }
            }
        }

        if maskAyaPosition != -1 {
            let qData = QData.instance()
            let maskStartPage = qData.pageIndex(ayaPosition: maskAyaPosition)
            let currPageIndex = self.pageIndex
            if  currPageIndex < maskStartPage {
                return maskStartPage// before masked page
            }
            maskBody.isHidden = false
            maskHead.isHidden = false
            let imageRect = pageImage.frame
            if( currPageIndex > maskStartPage ){
                maskHead.isHidden = true
                //maskBody.frame = imageRect
                maskBodyHeight.constant = imageRect.size.height
                return maskStartPage
            }
            
            if let ayaMapInfo = qData.ayaMapInfo(maskAyaPosition, pageMap: self.pageMap!){
                let pageHeight = imageRect.size.height
                let lineHeight = CGFloat(pageHeight / 15)
                let lineWidth = CGFloat(imageRect.size.width)
                maskHeadHeight.constant = lineHeight
                
                let headStartX = CGFloat(ayaMapInfo.spos) * lineWidth / 1000
               
                //Extend the mask .3 of the button width, if sneekView is not ON
                let extendedMask = (sneekViewWidth==0) ? (headStartX > lineWidth/9.65/3 ? lineWidth/9.65/3 : 0) : 0
                
                var sneekViewAdjustedWidth = sneekViewWidth
                if headStartX + sneekViewAdjustedWidth > lineWidth {
                    sneekViewAdjustedWidth = lineWidth - headStartX // uncover the whole line
                }
                print ("sneeKWidth=\(sneekViewWidth), sneekAdjusted=\(sneekViewAdjustedWidth)")
                maskHeadStartX.constant = headStartX + sneekViewAdjustedWidth - extendedMask
                //print("PositionMaskHead \(headStartX)")
                let coveredLines = 15 - 1 - Int(ayaMapInfo.sline)
                //print( "Aya\(ayaMapInfo["aya"]!) - Covered Lines\(coveredLines)" )
                maskBodyHeight.constant = CGFloat(CGFloat(coveredLines) * pageHeight) / 15
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
                setMaskStart(MaskStart + 1, followPage: false)
                //positionMask(false)
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
            setMaskStart(MaskStart-1, followPage: followPage)
//            MaskStart -= 1
//            positionMask( followPage )
        }
    }
    
    @objc func hideMask(){
        if MaskStart != -1 {
            setMaskStart(-1)
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
            setMaskStart( qData.ayaPosition(pageIndex: currPageIndex+1) )
        }else if maskPageIndex < currPageIndex {
            //forward, mark top of current page
            setMaskStart( qData.ayaPosition(pageIndex: currPageIndex) )
        }
    }
    
    func showAyaMenu(ayaView:UIView){
        becomeFirstResponder()
        clickedAya = ayaView
        //let menuRect = CGRect(x:0, y:0, width:ayaView.frame.size.width, height:ayaView.frame.size.height)
        if let menuRect = self.ayaStartPoint(ayaView.tag){
            let mnuController = UIMenuController.shared
            mnuController.setTargetRect(menuRect, in: self.pageImage)
            
            mnuController.menuItems = [
                UIMenuItem(title: "Tafseer", action: #selector(showTafseer)),
                UIMenuItem(title: "Revise", action: #selector(maskSelectedAya)),
                UIMenuItem(title: "Share", action: #selector(shareAya))
            ]
            
            // This makes the menu item visible.
            mnuController.setMenuVisible(true, animated: true)
        }
        
        //clickedAya!.backgroundColor = .blue
//        var hideMenuObserver:Any?
//        hideMenuObserver = NotificationCenter.default.addObserver(forName: .UIMenuControllerDidHideMenu, object: nil, queue: nil){_ in
//            //ayaView.backgroundColor = .brown
//            NotificationCenter.default.removeObserver( hideMenuObserver! )
//        }
    }
    
    func ayaStartPoint(_ ayaId:Int )->CGRect?{
        let qData = QData.instance()
        if let pageMap = self.pageMap,
            let ayaMapInfo = qData.ayaMapInfo(ayaId, pageMap: pageMap),
            let pageImage = self.pageImage
        {
            let pageHeight = pageImage.frame.height
            let pageWidth = pageImage.frame.width
            let lineHeight = pageHeight / 15
            return CGRect(
                x: pageWidth - (ayaMapInfo.spos * pageWidth)/1000,
                y: (CGFloat(ayaMapInfo.sline) * pageHeight)/15,
                width: 1,
                height: lineHeight
            )
        }
        return nil
    }
    
    func selectAya( aya: Int ){
        SelectStart = aya
        SelectEnd = aya
        positionSelection()
    }
    
    func positionSelection(){
        selectHead.isHidden = true
        selectBody.isHidden = true
        selectEnd.isHidden = true
        if SelectStart == -1 {
            return
        }
        if let pageInfo = self.pageInfo, let pageMap = self.pageMap {
            if (SelectStart >= pageInfo.ayaPos + pageInfo.ayaCount) // beyond this page
                || (SelectEnd < pageInfo.ayaPos) // ended before this page
            {
                self.updateViewConstraints()
                return
            }

            let imageRect = pageImage.frame
            let qData = QData.instance()
            let lineHeight = imageRect.height/15
            let pageWidth = imageRect.width
            let pageHeight = imageRect.height
            selectHead.isHidden = false
            if SelectStart < pageInfo.ayaPos{
                selectHeadHeight.constant = 0
            }else{
                selectHeadHeight.constant = lineHeight
                //print( lineHeight )
                let selectStartInfo = qData.ayaMapInfo(SelectStart, pageMap: pageMap)!
                let selectEndInfo = SelectStart == SelectEnd ? selectStartInfo : qData.ayaMapInfo(SelectEnd, pageMap: pageMap)!
                let ypos = pageHeight * CGFloat(selectStartInfo.sline) / 15
                selectHeadY.constant = ypos
                let startX = (CGFloat(selectStartInfo.spos) * pageWidth) / 1000
                selectHeadSartX.constant = startX
                let endX = selectStartInfo.sline == selectEndInfo.eline && selectStartInfo.page == selectEndInfo.page ?
                    (CGFloat(1000 - selectEndInfo.epos) * pageWidth) / 1000 : 0
                selectHeadEndX.constant = endX
                if selectEndInfo.page > self.pageIndex{// end next page
                    //selection body will cover the rest of the page
                    selectBody.isHidden = false
                    selectBodyBottomY.constant = 0
                }else if selectEndInfo.eline != selectStartInfo.sline{
                    //lower part of the page has uncovered lines
                    selectEnd.isHidden=false
                    selectBody.isHidden = false
                    let unselectedBottomLines = 15 - selectEndInfo.eline
                    let bodyBottomY = (pageHeight * CGFloat(unselectedBottomLines)) / 15
                    selectBodyBottomY.constant = bodyBottomY
                    selectEndHeight.constant = lineHeight
                    selectEndX.constant = (CGFloat(1000-selectEndInfo.epos) * pageWidth)/1000
                }else{//only selection head is required
                    //To avoid height constraints conflicts
                    selectBodyBottomY.constant = 0
                    selectEndHeight.constant = 0
                    selectEndX.constant = 0
                }
                
            }
            self.updateViewConstraints()
        }
        
    }
}
