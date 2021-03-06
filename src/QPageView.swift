//
//  DataViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
import Firebase

class QPageView: UIViewController{

   
    var newMask = true
    var isBookmarked: Bool?
    var pageNumber: Int? //will be set by the creator ViewController
    var pageMap: PageMap?
    var hifzList: HifzList? // cached hifz ranges
    var _pageInfo: PageInfo?
    
    var pageInfo: PageInfo? { //lazy loading
        get{
            if _pageInfo == nil && pageIndex != -1{
                self._pageInfo = QData.instance.pageInfo(pageIndex)
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
    var hifzColorsConstraints : [NSLayoutConstraint] = []


    // MARK: - Linked vars and functions
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var pageLoadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var btnCloseMask: UIButton!
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

    @IBOutlet weak var hifzColors: UIStackView!
    @IBOutlet weak var selectBodyBottomY: NSLayoutConstraint!
    @IBOutlet weak var selectEndHeight: NSLayoutConstraint!
    @IBOutlet weak var selectEndX: NSLayoutConstraint!
    
    @IBOutlet var pageTapGesture: UITapGestureRecognizer!
    @IBOutlet weak var buttonsView: LayerView!
    @IBOutlet weak var pageScroller: UIScrollView!
    @IBOutlet weak var pageBackground: UIImageView!
    @IBOutlet var downloadErrorView: UIView!
    @IBOutlet var readingStop: UIView!
    @IBOutlet weak var readingStopIndicator: UIImageView!
    
    @IBAction func pageImageTapped(_ sender: UIGestureRecognizer) {
        //retreatMask()
        
        if MaskStart != -1 {
            let qData = QData.instance
            let pageImageView = sender.view!
            let location = sender.location(in: pageImageView)
            let imageFrame = pageImageView.frame
            if let pageMap = self.pageMap,
                let ayaInfo = qData.locateAya(pageMap: pageMap, pageSize: imageFrame.size, location: location) {
                setMaskStart( qData.ayaPosition( sura: ayaInfo.sura, aya: ayaInfo.aya ) )
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.scrollToMaskStart()
                }
            }
        }
    }
    
    @IBAction func AyaMaskTapped(_ sender: Any) {
        moveMaskToCurrentPage()
        advanceMask(false)
    }

    @IBAction func PageLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            //print( "Press state is:\(sender.state.rawValue)")
            let qData = QData.instance
            let pageImageView = sender.view!
            let location = sender.location(in: pageImageView)
            let imageFrame = pageImageView.frame
            if let ayaInfo = qData.locateAya(pageMap: self.pageMap!, pageSize: imageFrame.size, location: location) {
                let ayaPosition = qData.ayaPosition( sura: ayaInfo.sura, aya: ayaInfo.aya )
                selectAya( aya: ayaPosition )
                showAyaMenu(onView: self.selectHead)
            }
        }
    }
    
    @IBAction func MaskLongPressed(_ sender: Any) {
        //self.hideMask()
        //TODO: if maskhead, sneek preview, else uncover that pressed aya
        
    }
    
    @IBAction func clickedCloseMask(_ sender: Any) {
        setMaskStart(-1)
    }
    
    @IBAction func retryDownloadImage(_ sender: Any) {
        downloadErrorView.removeFromSuperview()
        downloadPageImage()
    }
    
    // MARK: - selector functions
    
    @objc func showTafseer(){
        navigationController?.removeTafseer()//only allow one instance in the stack
        performSegue(withIdentifier: "ShowTafseer", sender: clickedAya)
    }
    
    @objc func maskSelectedAya(){
        setMaskStart( clickedAya!.tag )
    }
    
    @objc func bookmark(){
        QData.bookmark(self, SelectStart)
    }
    
    @objc func shareAya(){
        let qData = QData.instance
        
        if let clickedAya=clickedAya,
            let ayaText = qData.ayaText(ayaPosition: clickedAya.tag){
            let ayaPosition = clickedAya.tag
            let (sura,aya) = qData.ayaLocation(ayaPosition)
            if let suraName = qData.suraName(suraIndex: sura){
                let sharedText = "\(ayaText) (\(suraName.name):\(aya+1))"
                //TODO: check using SKStoreProductViewController
                let activityViewController = UIActivityViewController(
                    //activityItems: ["itms-apps://itunes.com/apps/facebook"],
                    activityItems: [sharedText],
                    applicationActivities: nil
                )
                activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                
                // exclude some activity types from the list (optional)
                //activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
                
                // present the view controller
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    //TODO: not called
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
                showAyaMenu( onView: clickedAya )
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
        newMask=true
        
        // Do any additional setup after loading the view, typically from a nib.
        //print ( "QPageView viewDidLoad()" )
        downloadPageImage()
        
        //createAyatButtons()
        becomeFirstResponder()
        
        if let pageNumber = self.pageNumber{
            self.pageMap = QData.pageMap( pageNumber-1 )
        }
        
        readData()

        NotificationCenter.default.addObserver(self, selector: #selector(readData), name: AppNotifications.dataUpdated, object: nil)
        //relead data upon data change
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var readingImageView:UIImageView?
    
    //Reset cache and redraw the data
    @objc func readData(){

        self.hifzList = nil
        
        createHifzColors()

        let readingStopPage = Utils.getReadingStop()
        
        if self.pageIndex == readingStopPage{
            if self.readingImageView == nil {// already created
                let imageView = UIImageView(image: UIImage(named: "Bookmark Filled"))
                imageView.tintColor = AppColors.greenBg
                imageView.alpha = 0.4
                imageView.contentMode = .scaleToFill
                view.addSubview(imageView)

                let alignment = (readingStopPage % 2 == 0) ?
                    imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:-5) :
                    imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant:5)
                
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: 25),
                    imageView.heightAnchor.constraint(equalToConstant: 50),
                    imageView.topAnchor.constraint(equalTo:view.topAnchor),
                    alignment
                ])
                
                readingImageView = imageView // to be able to remove it
            }
        }else{
            self.readingImageView?.removeFromSuperview()
            self.readingImageView = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //print ( "QPageView viewWillAppear(pg:\(pageNumber!)) " )

        pageTapGesture.isEnabled = (MaskStart != -1)
        if let pageNumber = self.pageNumber {
            let bgImage = (pageNumber % 2 == 0) ? "left_page" : "right_page"
            pageBackground?.image = UIImage(named: bgImage)!
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let parent = parentBrowserView(){
            parent.recordNavigation(new:false, pageNumber:pageNumber)
        }
    }
    
    override func viewDidLayoutSubviews() {
        //print ( "QPageView viewDidLayoutSubviews(pg:\(pageNumber!))" )
        //positionAyatButtons()
        positionMask(followPage: false)
        positionSelection()
        positionHifzColors()
    }
    
    override func viewWillLayoutSubviews() {
        //print ( "QPageView viewWillLayoutSubviews(pg:\(pageNumber!))" )
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if( action == #selector(showTafseer)
            || action == #selector(maskSelectedAya)
            || action == #selector(shareAya)
            || action == #selector(bookmark)
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
    
    func getPageMap()->PageMap?{
        if let pageMap = self.pageMap{
            return pageMap
        }else if let pageNumber = self.pageNumber{
            self.pageMap = QData.pageMap(pageNumber-1) // cache 
        }
        return self.pageMap
    }
    
    func downloadPageImage(){
        if let pageNumber = self.pageNumber {
            let imagesDir = "qpages_1260"
            let imageName = String(format: "page%03d.png", pageNumber)
            
            pageLoadingIndicator.startAnimating()

            if let fileURL = Utils.pathURL(dir: imagesDir, file: imageName),
                let image = UIImage(contentsOfFile: fileURL.path) {
                pageImage.image = image
                self.pageLoadingIndicator.stopAnimating()
                return
            }
            
            QData.pageImagesBaseURL(){ baseURL in
                if let baseURL = baseURL{
                    let imageUrl = URL(string:"\(baseURL)/\(imagesDir)/\(imageName)")!
                    
                    Utils.getDataFromUrl(url: imageUrl) { (data, response, error) in
                        
                        guard let data = data, error == nil else {
                            //show an error and a retry button
                            //print( "Failed to download image \(imageUrl.absoluteString)" )
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                self.pageLoadingIndicator.stopAnimating()
                                self.view.addSubview(self.downloadErrorView)
                                self.downloadErrorView.frame = self.view.frame
                            }
                            return
                        }
                        
                        Utils.saveData(dir: imagesDir, file:imageName, data: data)
                        
                        if let downloadedImage = UIImage(data: data){
                            //Apply the image data in the UI thread (similar to javascript:window.setTimeout())
                            DispatchQueue.main.async {
                                //Set the imageView source
                                self.pageImage?.image = downloadedImage
                                self.pageLoadingIndicator.stopAnimating()
                            }
                        }
                    }
                }
            }
        }
    }
    
    //TODO: parent controller has the same implementation
    //Parent controller only call setMaskStart upon ending the mask from navigationBar X button
    
    func setMaskStart(_ ayaId:Int, followPage:Bool = false ){
        if let pagesBrowser = self.parentBrowserView(){
            pagesBrowser.setMaskStart( ayaId, followPage: followPage )
        }
        //Parent controller dosn't have access to pageTabGesture
        //pageTapGesture.isEnabled = ( ayaId != -1 )
        //navigationController?.navigationBar.isHidden = true
    }

    //TODO: unused
    func createAyatButtons(){
        //if let pageNumber = self.pageNumber{
            //self.pageMap = QData.pageMap( pageNumber-1 )
            if let pageMap = self.getPageMap() {
                let qData = QData.instance
                for ayaFullInfo in pageMap{
                    let btn = UIView()
                    btn.backgroundColor = AppColors.ayaBtn
                    btn.layer.cornerRadius = 5
//                    let tap = UILongPressGestureRecognizer(target: self, action: #selector(onClickAyaButton))
//                    btn.addGestureRecognizer(tap)
//                    tap.minimumPressDuration = 0
//                    btn.isUserInteractionEnabled = true
                    btn.tag = qData.ayaPosition(sura: ayaFullInfo.sura, aya: ayaFullInfo.aya)
                    self.buttonsView.addSubview(btn)
                }
                //print ("createAyatButtons-> pg:\(pageNumber) count:\(pageMap.count)")
            }
        //}
    }
    
    //TODO: Unused
    func positionAyatButtons(){
        let containerView = self.buttonsView!
        let imageRect = containerView.frame
        let lineHeight = CGFloat(imageRect.size.height / 15)
        let lineWidth = CGFloat(imageRect.size.width)
        
        //print ( "positionAyatButton-> pg: \(self.pageNumber!), h: \(line_height), w: \(line_width) " )

        if let pageMap = self.pageMap{
            let buttonWidth = CGFloat(lineWidth/9.65)
            
            containerView.removeConstraints(containerView.constraints)//remove existing constraints
            
            for(index, btn) in containerView.subviews.enumerated(){
                let btnMapInfo = pageMap[index]
                let eline = btnMapInfo.eline
                let epos = btnMapInfo.epos
                let xpos = CGFloat( epos * lineWidth / 1000 - buttonWidth )
                let ypos = CGFloat( CGFloat(eline) * CGFloat(imageRect.size.height) / 15 )
                var rect = CGRect(x: xpos, y: ypos, width: buttonWidth, height: lineHeight)
                rect = rect.insetBy(dx: 3, dy: 3)
                btn.layer.cornerRadius = rect.width * 0.1905 //trying to find the golden ratio
                
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
    func positionMask( animate: Bool = false )->Int{
        if maskHead == nil {
            return -1
        }
        
        maskBody?.isHidden = false
        maskHead?.isHidden = false

        //let maskAyaPosition = MaskStart

        if MaskStart == -1{
            maskBodyHeight?.constant = 0
            maskHeadStartX?.constant = 0
            maskHeadHeight?.constant = 0
            btnCloseMask?.isHidden = true
            return -1 // mask is hidden
        }
        
        let qData = QData.instance
        let maskStartPage = qData.pageIndex(ayaPosition: MaskStart)
        let currPageIndex = self.pageIndex
        if  currPageIndex < maskStartPage {
            maskBodyHeight?.constant = 0
            maskHeadStartX?.constant = 0
            maskHeadHeight?.constant = 0
            btnCloseMask?.isHidden = true
            return maskStartPage// active page is before masked page, nothing to show
        }
        //somthing to show
        //maskBody.isHidden = false
        let imageRect = pageImage.frame

        if( currPageIndex > maskStartPage ){
            //mask started in an earlier page, active page is totally covered
            //maskHead.isHidden = true
            //maskHeadStartX.constant = 0
            maskHeadHeight?.constant = 0
            btnCloseMask?.isHidden = true
            maskBodyHeight?.constant = imageRect.size.height
            return maskStartPage
        }
        
        btnCloseMask?.isHidden = false
        //maskHead.isHidden = false

        
        if  let pageMap = self.getPageMap(),
            let ayaMapInfo = qData.ayaMapInfo(MaskStart, pageMap: pageMap){
            let f=CGFloat(0)
            var (maskHeadHeight, maskHeadStartX,maskBodyHeight) = (f,f,f)

            let pageHeight = imageRect.size.height
            let lineHeight = CGFloat(pageHeight / 15)
            let lineWidth = CGFloat(imageRect.size.width)
            maskHeadHeight = lineHeight
            
            var headStartX = CGFloat(ayaMapInfo.spos) * lineWidth / 1000
            
            if headStartX < lineWidth / 20{
                headStartX = 0
            }
            
            //Extend the mask .1 of the lineHeight width, if sneekView is not ON
            let extensionWidth = lineHeight/10 //lineWidth/9.65/3
            let extendedMask = (self.sneekViewWidth==0) ? (headStartX > extensionWidth ? extensionWidth : 0) : 0
            
            var sneekViewAdjustedWidth = self.sneekViewWidth
            if headStartX + sneekViewAdjustedWidth > lineWidth {
                sneekViewAdjustedWidth = lineWidth - headStartX // uncover the whole line
            }
            maskHeadStartX = headStartX + sneekViewAdjustedWidth - extendedMask
            let coveredLines = 15 - 1 - Int(ayaMapInfo.sline)
            maskBodyHeight = CGFloat(CGFloat(coveredLines) * pageHeight) / 15

//            if !self.newMask {//don't animate in the first positioning, to avoid flickering
//                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
//                    self.maskHeadHeight.constant = maskHeadHeight
//                    self.maskHeadStartX.constant = maskHeadStartX
//                    self.maskBodyHeight.constant = maskBodyHeight
//                    self.view.layoutIfNeeded()
//                })
//            }else{
                self.newMask = false
                self.maskHeadHeight?.constant = maskHeadHeight
                self.maskHeadStartX?.constant = maskHeadStartX
                self.maskBodyHeight?.constant = maskBodyHeight
//            }

        }
        
        return maskStartPage
    }

    func parentBrowserView()->QPagesBrowser?{
        if let parent = self.parent, let pagesBrowser = parent.parent as? QPagesBrowser {
            return pagesBrowser
        }
        return nil
    }
    
    func gotoPage(_ pageIndex: Int ){
        if pageIndex != self.pageIndex{
            if let parent = parentBrowserView(){
                parent.gotoPage( pageNum: pageIndex+1 )
            }
        }
    }
    
    func advanceMask(_ followPage: Bool){
        
        switch MaskStart {
            case -1, QData.totalAyat-1:
                return
            
            default:
                let qData = QData.instance
                //if maskStart is at first Aya of a page different than current page, goto that page and return
                let pageLocation = qData.ayaPagePosition(MaskStart)
                let currPageIndex = self.pageIndex

                if followPage {
                    gotoPage(pageLocation.page)

                    if pageLocation.position == .first && pageLocation.page != currPageIndex {
                        //mask moved to the start of next page
                        return// no need to advance the mask
                    }
                }

                if pageLocation.position == .last && pageLocation.page == currPageIndex {
                    scrollToBottom()
                }else{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.scrollToMaskStart()
                    }
                }

                setMaskStart(MaskStart + 1, followPage: false)
        }
    }

    func scrollToBottom(){
        if let pageScroller = self.pageScroller, let pageImage = self.pageImage{
            pageScroller.contentSize = pageImage.frame.size
            let bottomOffset = CGPoint(x: 0, y: pageImage.frame.size.height - pageScroller.frame.size.height)
            pageScroller.setContentOffset(bottomOffset, animated: true)
        }
    }

    func scrollToTop(){
        let topOffset = CGPoint(x: 0, y: 0)
        pageScroller?.setContentOffset(topOffset, animated: true)
    }

    func scrollToMaskStart(){
        if let pageScroller = self.pageScroller,
            let pageImage = self.pageImage,
            let selectHead = self.selectHead
        {
            pageScroller.contentSize = pageImage.frame.size
            pageScroller.scrollRectToVisible(selectHead.frame, animated: true)
        }
    }

    func scrollToSelectedAya(){
        if selectHead?.isHidden == false {
            pageScroller?.contentSize = pageImage.frame.size
            var sel_rect = selectHead.frame
            if selectBody?.isHidden == false {
                sel_rect.size.height = sel_rect.height + selectBody.frame.height
            }
            if selectEnd?.isHidden == false {
                sel_rect.size.height = sel_rect.height + selectEnd.frame.height
            }
            if sel_rect.height > pageScroller.frame.height{
                sel_rect.size.height = pageScroller.frame.height
            }
            pageScroller?.scrollRectToVisible(sel_rect, animated: true)
        }
    }

    func retreatMask(_ followPage: Bool){
        if MaskStart != -1 && MaskStart > 0{
            let qData = QData.instance

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.scrollToMaskStart()
            }

            if followPage {
                //if maskStart is at first Aya that is not the prior page, goto prior page and return
                let currPageIndex = self.pageIndex
                let pageLocation = qData.ayaPagePosition(MaskStart)
                
                if pageLocation.position == .first && pageLocation.page-1 != currPageIndex {
                    gotoPage(pageLocation.page-1)
                    //scroll to the bottom of previous page
                    if let pageBrowser = self.parentBrowserView(){
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let qPageView = pageBrowser.currentPageView(){
                                qPageView.scrollToBottom()
                            }
                            
                        }
                    }
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
        let qData = QData.instance
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
    
    func showNavBar(show:Bool = true){
        if let parent = self.parentBrowserView(){
            parent.showNavBar(show)
        }
    }
    
    func showAyaMenu(onView:UIView){
        //print("showAyaMenu()")
        showNavBar(show: false)
        //Utils.showNavBar(self, false)
        //navigationController?.setNavigationBarHidden(true, animated: true)
        becomeFirstResponder()//required to show the menu!!
        clickedAya = onView
        let ayaPosition = onView.tag
        if let menuRect = self.ayaStartPoint(ayaPosition){
            let mnuController = UIMenuController.shared
            mnuController.setTargetRect(menuRect, in: self.pageImage)
            
            mnuController.menuItems = [
                UIMenuItem(title: AStr.tafseer, action: #selector(showTafseer)),
                UIMenuItem(title: AStr.revise, action: #selector(maskSelectedAya)),
                UIMenuItem(title: AStr.bookmark, action: #selector(bookmark)),
                UIMenuItem(title: AStr.share, action: #selector(shareAya))
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
    
    func ayaStartPoint(_ ayaPosition:Int )->CGRect?{
        let qData = QData.instance
        
        if let pageMap = getPageMap(),
            let ayaMapInfo = qData.ayaMapInfo(ayaPosition, pageMap: pageMap),
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
    
    
    /// Set the current selected Aya and highlight it in the page and scroll to it if required
    ///
    /// - Parameter aya: aya absolute position
    func selectAya( aya: Int ){
        //TODO: move this method to QPagesBrowers

        if (aya+1) > QData.totalAyat {
            return
        }
        
        SelectStart = aya
        SelectEnd = aya
        if let pagesBrowser = self.parentBrowserView(){
            pagesBrowser.setNavigationButtonsColor()
        }
        positionSelection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.scrollToSelectedAya()
        }
    }

    func appendColorHifzRow(lines:Int, bgColor: UIColor = .clear){
        let hifzRow = UIView()
        hifzRow.backgroundColor = bgColor
        //calcualte number of lines for this sura from the page map
        hifzRow.tag = lines
        self.hifzColorsConstraints.append(hifzRow.heightAnchor.constraint(equalToConstant: 1))
        self.hifzColors.addArrangedSubview(hifzRow)
    }
    
    func createHifzColors(){
        
        QData.pageHifzRanges(self.pageIndex){ ( hifzList: HifzList? ) in
            self.hifzList = hifzList // save in cache
            
            //Remove existing subviews
            for view in self.hifzColors.subviews {
                view.removeFromSuperview()
            }
            
            self.hifzColorsConstraints.removeAll()

            if let hifzList = hifzList, let pageMap = self.getPageMap() {
                var lastLine = -1
                
                hifzList.forEach{ ( range: HifzRange ) in
                    //print (range)
                    
                    if let suraPageLocation = QData.findSuraPageLocation(suraIndex: range.sura, pageMap: pageMap){
                        if lastLine + 1 < suraPageLocation.fromLine {
                            //insert blank views for gaps
                            self.appendColorHifzRow(lines: suraPageLocation.fromLine - lastLine - 1)
                        }
                        self.appendColorHifzRow(
                            lines: suraPageLocation.toLine - suraPageLocation.fromLine + 1,
                            bgColor: QData.hifzColor(range: range))
                        lastLine = suraPageLocation.toLine
                    }
                }
                NSLayoutConstraint.activate(self.hifzColorsConstraints)
                self.positionHifzColors()
            }
        }
        
        
    }

    func positionHifzColors(){
        let imageRect = pageImage.frame
        let lineHeight = imageRect.height/15
        
        if hifzColorsConstraints.count>0 && hifzColorsConstraints.count == hifzColors.subviews.count {
            for ndx in 0..<hifzColors.subviews.count {
                let view = hifzColors.subviews[ndx]
                let lines = CGFloat(view.tag)
                let height = lines * lineHeight
                hifzColorsConstraints[ndx].constant = height
            }
            //hifzColors.updateConstraints()
            self.updateViewConstraints()
            //print ("** \(hifzColorsConstraints.count) Color constraints updated **")
        }
//        else{
//            print ("** No color constraints created **")
//        }
        
    }
    
    func positionSelection(){
        if selectHead == nil {
            return
        }
        
        selectHead.isHidden = true
        selectBody.isHidden = true
        selectEnd.isHidden = true
        
        if SelectStart == -1 {
            return
        }
        
        selectHead.tag = SelectStart
        
        if let pageInfo = self.pageInfo,
            let pageMap = self.getPageMap() {
            
            if (SelectStart >= pageInfo.ayaPos + pageInfo.ayaCount) // beyond this page
                || (SelectEnd < pageInfo.ayaPos) // ended before this page
            {
                self.updateViewConstraints()
                return
            }

            let imageRect = pageImage.frame
            let qData = QData.instance
            let lineHeight = imageRect.height/15
            let pageWidth = imageRect.width
            let pageHeight = imageRect.height
            
            selectHead.isHidden = false
            
            if SelectStart < pageInfo.ayaPos{
                selectHeadHeight.constant = 0// selection started in a previous page
            }else{
                //selection started at this or the next page
                selectHeadHeight.constant = lineHeight
                
                let selectStartInfo = qData.ayaMapInfo(SelectStart, pageMap: pageMap)! //TODO: validate not nil
                let selectEndInfo = SelectStart == SelectEnd ? selectStartInfo : qData.ayaMapInfo(SelectEnd, pageMap: pageMap)!
                let ypos = pageHeight * CGFloat(selectStartInfo.sline) / 15
                selectHeadY?.constant = ypos
                var startX = (CGFloat(selectStartInfo.spos) * pageWidth) / 1000
                if startX < pageWidth/20 {
                    startX = 0
                }
                var extensionWidth = lineHeight/10
                if extensionWidth > startX{
                    extensionWidth = startX
                }
                selectHeadSartX.constant = startX - extensionWidth
                let endX = selectStartInfo.sline == selectEndInfo.eline && selectStartInfo.page == selectEndInfo.page ?
                    (CGFloat(1000 - selectEndInfo.epos) * pageWidth) / 1000 : 0
                selectHeadEndX.constant = endX
                if selectEndInfo.page > self.pageIndex{// Selection ends next page
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
