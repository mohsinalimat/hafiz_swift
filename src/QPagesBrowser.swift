//
//  RootViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit
import MediaPlayer

var MaskStart = -1

/// The position of the selection start aya
var SelectStart = -1
var SelectEnd = -1


class QPagesBrowser: UIViewController
    ,UIPageViewControllerDelegate
    ,UIPageViewControllerDataSource
    ,UIActionAlertsManager
    {

    //TODO: use 0 based numbering
    let firstPage = 1
    let lastPage = 604
    
    var pageViewController: UIPageViewController?
    //var startingPage:Int?
    
    var autoRotate = true
    var orientation = UIInterfaceOrientationMask.all

    // MARK: - Outlets
    
    @IBOutlet weak var goNextButton: UIButton!
    @IBOutlet weak var goPrevButton: UIButton!
    @IBOutlet weak var pagesContainer: UIView! //unused
    @IBOutlet weak var footerSuraNameLabel: UILabel!
    @IBOutlet weak var footerInfoButton: UIButton!
    @IBOutlet weak var footerFullInfoButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet var navbar: UIView!
    @IBOutlet weak var navBarTitle: UILabel!
    @IBOutlet weak var navBarBackButton: UIButton!
    
    
    // MARK: - UIViewController delegate methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // menuItems.addGestureRecognizer( UITapGestureRecognizer( target:self, action:#selector(hideMenu) ) )
        // menuItems.frame = self.view.frame

        // Create Configure the page view controller and add it as a child view controller.
        // self.pageViewController = UIPageViewController(transitionStyle: .scroll,
        //                                                navigationOrientation: .horizontal,
        //                                                options: nil)

        // create a reference to the embedded UIPageViewController
        self.pageViewController = self.childViewControllers[0] as? UIPageViewController
        // Set this object as the delegate for the page view controller
        self.pageViewController!.delegate = self
        self.pageViewController!.dataSource = self
        
        goNextButton.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(onLongPressNext))
        )

        self.goPrevButton.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(onLongPressPrev))
        )

        //self.addChildViewController(self.pageViewController!)//TODO: required?
        //self.view.addSubview(self.pageViewController!.view)
        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        //var pageViewRect = self.view.bounds
        //pageViewRect.size.height = pageViewRect.height - 30

        //If IPad, add 40 pixel padding around the view
        //if UIDevice.current.userInterfaceIdiom == .pad {
        //    pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        //}
       
        //self.pageViewController!.view.frame = pageViewRect
        //self.pageViewController!.didMove(toParentViewController: self)//TODO: required?
        
        //gotoPage(pageNum: startingPage ?? 1)
        gotoPage(ayaPos: SelectStart)
        
        //record the last navigation
        recordNavigation(new:true)
        
        setNavigationButtonsColor()//footer navigation init
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //hideNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //print("QPagesBrowser willAppear")
        navigationController?.navigationBar.isHidden = true //there should be a better way to do that
        
        let nCenter = NotificationCenter.default

        nCenter.addObserver(
            self,
            selector: #selector(searchOpenAya),
            name: AppNotifications.searchOpenAya,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchViewResults),
            name: AppNotifications.searchViewResults,
            object: nil
        )

        nCenter.addObserver(
            self,
            selector: #selector(onDeviceRotated),
            name: NSNotification.Name.UIDeviceOrientationDidChange,
            object: nil
        )

        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        
        // setting the hidesBarsOnSwift property to false
        // since it doesn't make sense in this case,
        // but is was set to true in the last VC
        //navigationController?.hidesBarsOnSwipe = false
        
        // setting hidesBarsOnTap to true
        //navigationController?.hidesBarsOnTap = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        //print("QPagesBrowser willDisappear")
        //showNavBar()
        NotificationCenter.default.removeObserver(self)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - New class methods

    
    var navBarShown = false
    
    func showNavBar(_ show:Bool = true, animated:Bool = true ){
        //Utils.showNavBar(self, !hide)
        //navigationController?.setNavigationBarHidden(hide, animated: true)
        if show{
            view.addSubview(navbar)
            navbar.frame = view.frame
            navbar.frame.size.height = (self.navigationController?.navigationBar.frame.height)! +
                (self.navigationController?.navigationBar.frame.origin.y)!

            if animated {
                navbar.frame.origin.y = -navbar.frame.size.height
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                    self.navbar.frame.origin.y = 0
                })
            }
            
        }
        else{
            if animated {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut,
                    animations: {
                        self.navbar.frame.origin.y = -self.navbar.frame.size.height
                    },
                    completion:{ finished in
                        self.navbar.removeFromSuperview()
                    }
                )
            }
            else{
                navbar.removeFromSuperview()
            }
        }
        navBarShown = show
    }

    func gotoPage(pageNum:Int){
        let _ = checkGotoPage(pageNum: pageNum)
    }

    func gotoPage(ayaPos:Int){
        let _ = checkGotoPage(ayaPos: ayaPos)
    }

    var recordNavigationEnabled = false //skip the first navigation
    
    func recordNavigation(new: Bool = false, pageNumber:Int? = nil ){
        
        if !new && !recordNavigationEnabled {
            recordNavigationEnabled = true//to skip the first gotoPage
            return
        }
        
        var hist = UserDefaults.standard.array(forKey: "nav_history") as? [Int] ?? []
        if new {
            if let old = hist.index(of: SelectStart){
                hist.remove(at: old)
            }
            hist.insert(SelectStart, at: 0)
            hist = Array(hist.prefix(3)) // only keep last 5
        }
        else if hist.count>1,
            let pageNum = pageNumber
        {//inner page navigation, only overwrite the top item
            let pageFirstAya = QData.instance.ayaPosition(pageIndex: pageNum-1)
            hist[0] = pageFirstAya
        }
        else{
            return //nothing to update
        }
    
        UserDefaults.standard.set(hist, forKey: "nav_history")
        NotificationCenter.default.post(name: AppNotifications.pageViewed, object:hist)

    }
    
    /// Navigate to a page, highlight and scroll to the selected aya
    ///
    /// - Parameter pageNum: page number (1 based)
    /// - Returns: if a navigation took place
    func checkGotoPage( pageNum: Int )->Bool{
        //TODO: create two pages if ipad landscape mode
        let currPageIndex = currentPageIndx()
        
        if  (currPageIndex+1 != pageNum),
            let pageViewController = self.pageViewController,
            let startingViewController = viewControllerAtIndex( pageNum, storyboard: self.storyboard! )
        {
            
            //pass inital set of page viewers
            //TODO: create two pages if ipad landscape mode
            let viewControllers = [startingViewController]
            
            pageViewController.setViewControllers(
                viewControllers,
                direction: pageNum <= currPageIndex ? .forward : .reverse,
                animated: true,
                completion: {done in}
            )
            
            updateTitle()
            
            if SelectStart == -1{
                if let pageInfo = QData.instance.pageInfo(currPageIndex){
                    SelectStart = pageInfo.ayaPos
                    SelectEnd = SelectStart
                }
            }
            else{
                //Scroll to selection
                //Similar to window.setTimeout()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    startingViewController.scrollToSelectedAya()
//                    if let curr_view = self.currentPageView() {
//                        curr_view.scrollToSelectedAya()
//                    }
                }
            }
            
            startingViewController.positionSelection()
            
            return true
        }
        
        return false
    }

    /// Navigate to the page containing the passed Aya if not in the current page
    ///
    /// - Parameter ayaPos: the absolute aya index
    /// - Returns: whether or not a page navigation took place
    func checkGotoPage(ayaPos:Int)->Bool{
        let qData = QData.instance
        let selectionPage = qData.pageIndex(ayaPosition: ayaPos)
        if selectionPage != self.currentPageIndx(){
            return checkGotoPage(pageNum: selectionPage+1)
        }
        return false
    }

    /// Creates (or re-use recycled object) a page viewer for a given page number and initializes it
    ///
    /// - Parameters:
    ///   - index: page index
    ///   - storyboard: a reference to storyboard object to load UI resources from
    /// - Returns: a view controller for a Quran page
    
    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> QPageView? {
        //TODO: return array of two view controllers, reuse existing view controllers if already created

        if(index < firstPage) || (index > lastPage) {
            return nil
        }
        
        // Create a new storyboard view controller and set the required data
        let dataViewController = storyboard.instantiateViewController(
            withIdentifier: "QPageView"
            ) as! QPageView
        
        //set page number
        dataViewController.pageNumber = index;
        
        return dataViewController
    }
    
    func indexOfViewController(_ viewController: QPageView ) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        
        return viewController.pageNumber!
    }

    /// Find the active QPageView and read its pageNumber, find the suraName and update the title
    /// Note: viewControllers array holds one view in case of portrait and 2 in case of landscape showing two pages
    
    func updateTitle(){
        //reference the first QPageView
        let pageIndex = currentPageIndx()
        let qData = QData.instance
        //let suraNumber = qData.suraIndex( pageIndex: pageIndex ) + 1
        let partNumber = qData.partIndex( pageIndex: pageIndex ) + 1
        
        let suraName = qData.suraName(pageIndex: pageIndex)!
        self.title = suraName.name
        
        navBarTitle.text = suraName.name
        navBarBackButton.titleLabel?.text = AStr.back
        if UIView.userInterfaceLayoutDirection(
            for: navbar.semanticContentAttribute) == .rightToLeft
        {
            navBarBackButton.setImage(UIImage(named: "Back RTL"), for: .normal)
        }

        //let nextPageArrow = pageIndex < lastPage - 2 ? " >>" : ""
        //let pageInfo = String(format:NSLocalizedString("FooterInfo", comment: ""), partNumber,pageIndex+1)
        
        let pageInfo = AStr.miniPartNPageN(part: partNumber, page: pageIndex+1)
        self.footerInfoButton.setTitle(pageInfo, for: .normal)
        self.footerFullInfoButton.setTitle(AStr.partNPageN(part: partNumber, page: pageIndex+1), for: .normal)
        
        //let maskedAya = (MaskStart == -1) ? "" : ":\(qData.ayaLocation(MaskStart).aya+1)"
        self.footerSuraNameLabel.text = suraName.name //+ maskedAya
        
        setNavigationButtonsColor()
    }
    
    func currentPageIndx()->Int{
        if let qPageView = currentPageView(), let pageNumber = qPageView.pageNumber{
            return pageNumber - 1
        }
        return -1
    }
    
    func isBookmarked()->Bool{
        if let qPageView = currentPageView(), let isBookmarked = qPageView.isBookmarked{
            return isBookmarked
        }
        return false
    }
    
    //TODO: support two pages view mode
    func currentPageView()->QPageView?{
        if  let pageViewController = self.pageViewController,
            let viewControllers = pageViewController.viewControllers
        {
            if viewControllers.count>0 {
                
                if let qPageView = viewControllers[0] as? QPageView{
                    return qPageView
                }
            }
        }
        return nil
    }
    
    //TODO: support two pages view mode
//    func currentSuras()->SuraInfoList?{
//        if let pageView = currentPageView(){
//            //return pageView.sura
//        }
//        return nil
//    }
    
    func showSearch(){
        self.performSegue(withIdentifier: "PopupSearch", sender: self)
    }

    // MARK: - Event and Action Handlers
    
    @IBAction func onPageTap(_ sender: Any) {
        showNavBar( navBarShown == false ) //toggle the bar
    }

    @IBAction func onClickNext(_ sender: Any) {
        showNavBar(false)
        if MaskStart != -1 {
            if let qPageView = currentPageView() {
                qPageView.advanceMask(true)
            }
        }
        else if SelectStart != -1 {
            if !checkGotoPage(ayaPos: SelectStart){
                if let currPageView = currentPageView(){
                    currPageView.selectAya( aya: SelectStart+1 )
                    gotoPage(ayaPos: SelectStart)
                }
            }
        }
        else{//goto next sura
            let qData = QData.instance
            let (sura,page) = qData.nextSura(fromPage: currentPageIndx())
            let firstAya = qData.ayaPosition(sura: sura, aya: 0)
            gotoPage( pageNum: page + 1 )
            if let currPageView = currentPageView(){
                currPageView.selectAya( aya: firstAya )
            }
        }
    }

    /// Handling "Next" navigation button long press gesture
    ///
    /// - Parameter sender: long press gesture object
    @objc func onLongPressNext(_ sender: UILongPressGestureRecognizer){
        if MaskStart != -1, let pageView = currentPageView() {
            let lineWidth = view.frame.width
            let sneekWidth = lineWidth / 6
            if sender.state == .began {
                pageView.maskHeadStartX.constant = pageView.maskHeadStartX.constant + sneekWidth
            }
            else if sender.state == .ended{
                pageView.maskHeadStartX.constant = pageView.maskHeadStartX.constant - sneekWidth
            }
        }else{
            let qData = QData.instance
            if sender.state == .began {
                let (sura,page) = qData.nextSura(fromPage: currentPageIndx())
                let firstAya = qData.ayaPosition(sura: sura, aya: 0)
                
                gotoPage( pageNum: page+1 )
                
                if let currPageView = currentPageView(){
                    currPageView.selectAya( aya: firstAya )
                }
            }
        }
    }
    
    @objc func onLongPressPrev(_ sender: UILongPressGestureRecognizer ){
        if MaskStart == -1 {//no mask
            let qData = QData.instance
            if sender.state == .began {
                let (sura,page) = qData.priorSura(fromPage: currentPageIndx())
                let firstAya = qData.ayaPosition(sura: sura, aya: 0)
                
                gotoPage( pageNum: page+1 )
                
                if let currPageView = currentPageView(){
                    currPageView.selectAya( aya: firstAya )
                }
            }
        }

    }

    @IBAction func onClickPrevious(_ sender: Any) {
        showNavBar(false)
        if MaskStart != -1 {
            if let qPageView = self.currentPageView() {
                qPageView.retreatMask( true )
            }
        }
        else if SelectStart != -1 {
            if !checkGotoPage(ayaPos: SelectStart){
                if SelectStart > 1 {
                    gotoPage(ayaPos:SelectStart-1)
                    if let currPageView = currentPageView(){
                        currPageView.selectAya( aya: SelectStart-1 )
                    }
                }
            }
        }
        else{
            let qData=QData.instance
            let (sura,page) = qData.priorSura(fromPage: currentPageIndx())
            let firstAya = qData.ayaPosition(sura: sura, aya: 0)
            
            gotoPage( pageNum: page+1 )
            
            if let currPageView = currentPageView(){
                currPageView.selectAya( aya: firstAya )
            }
        }
    }

    @IBAction func clickClose(_ sender: Any) {
        if MaskStart != -1 {//If mask is On, clear it first
            setMaskStart(-1)
            //hideSelection()
        }
//        else if SelectStart != -1 {
//            if checkGotoPage(ayaPos: SelectStart){
//                //If selection starts in different page, navigate to that page before hiding the selection
//                if let currPageView = self.currentPageView(){
//                    currPageView.scrollToSelectedAya()
//                }
//                return
//            }
//            hideSelection()
//        }
        else{//go back to calling viewController ( Home )
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func navigationSearchClicked(_ sender: Any) {
        showSearch()
    }
    
    @IBAction func onMenuButtonClick(_ sender: Any) {
        showActionsMenuAlert()
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onPinchAction(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .ended {
            autoRotate = true
            
            //print ("Current Portrait is \(UIDevice.current.orientation.isPortrait)")
            
            if sender.scale > 1 {
                //AppDelegate.orientation = .landscape
                orientation = .landscape
            }
            else{
                //AppDelegate.orientation = .portrait
                orientation = .portrait
            }
            
            UIDevice.current.setValue(AppDelegate.orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            //print ("New Portrait is \(UIDevice.current.orientation.isPortrait)")
            
            //Deprecated UIApplication.shared.setStatusBarOrientation(UIInterfaceOrientation.landscapeLeft, animated: true)
            //print( self.shouldAutorotate )
        }
    }

    // MARK: - Actions Alert
    
    func showActionsMenuAlert(){
        
        let qData = QData.instance
        let startRevise = MaskStart == -1 ? alertAction( .revise, AStr.revise ) : nil
        
        var addUpdateHifzTitle = AStr.addUpdateHifz
        
        if let pageView = self.currentPageView(),
            let pageNumber = pageView.pageNumber,
            let hifzList = pageView.hifzList,
            let pageMap = pageView.pageMap
        {
            let suraInfoList = qData.pageSuraInfoList(pageNumber-1, pageMap: pageMap)
            //Decide whether to show "add hifz", "add/update hifz" or "update hifz"
            if hifzList.count == 0{
                addUpdateHifzTitle = AStr.addHifz
            }else if hifzList.count == suraInfoList.count {
                addUpdateHifzTitle = AStr.updateHifz
            }
        }
        
        let addToHifz = alertAction(.addUpdateHifz, addUpdateHifzTitle) // check if hifzRange is active

        var actions = [
            startRevise
        ]
        
        let readingStop = Utils.getReadingStop()
        if readingStop != currentPageIndx(){
            actions.append( alertAction(.setReadingStop , AStr.setReadingStop) )
        }

        actions.append(addToHifz)
        
        if !isBookmarked(){
            actions.append( alertAction(.bookmark , AStr.bookmark) )
        }
        
        showAlertActions(actions)

    }
    
    // MARK: - UIActionAlertsManager delegate methods
    func handleAlertAction(_ id: AlertActions,_ selection: Any?){
        switch id {
        case .revise:
            if SelectStart != -1 &&
                //if SelectStart is not in the visibile paages, select page start
                QData.instance.pageIndex(ayaPosition: SelectStart) == self.currentPageIndx(){
                self.setMaskStart(SelectStart)
            }else{
                let qData = QData.instance
                self.setMaskStart( qData.ayaPosition(pageIndex: self.currentPageIndx()))
            }
            break
            
        case .search:
            self.showSearch()
            break

        case .bookmark:
            if !QData.checkSignedIn(self){
                break
            }
            let aya = QData.instance.ayaPosition( pageIndex: self.currentPageIndx() )
            
            let _ = QData.createBookmark(aya: aya){snapshot in
                Utils.showMessage(self, title: AStr.bookmarkAdded,
                                  message: AStr.bookmarkAddedDesc)
            }
            break

        case .setReadingStop:
            Utils.confirmMessage(self, AStr.confirmSetReadingStop(from: Utils.getReadingStop(), to: self.currentPageIndx()), AStr.areYouSure , .yes){ yes in
                if yes{
                    Utils.saveSetting("reading_stop", self.currentPageIndx())
                }
            }
            break
            
        case .addUpdateHifz:
            if !QData.checkSignedIn(self){
                break
            }
            if let pageView = currentPageView(),
                let pageMap = pageView.pageMap,
                let hifzList = pageView.hifzList
            {
                let qData = QData.instance
                let currPage = self.currentPageIndx()
                
                //Select all suras in the page
                let suraInfoList = qData.pageSuraInfoList(
                    currPage,
                    pageMap: pageMap)
                
                if suraInfoList.count == 1{
                    //Skip the sura selection
                    //If a hifzRange if found for the sura, send it instead of SuraInfo
                    let suraInfo = suraInfoList.first
                    let hifzRange = hifzList.first{
                        range in
                        return suraInfo?.sura == range.sura
                    }
                    handleAlertAction( .addHifzSelectSura, hifzRange ?? suraInfo )
                }
                else if suraInfoList.count > 1{
                    //show select sura alert
                    let actions = suraInfoList.map{ (suraInfo)->UIAlertAction? in
                        if let suraName = qData.suraName(suraIndex: suraInfo.sura){
                            //If a hifzRange if found for the sura, send it instead of SuraInfo
                            let hifzRange = hifzList.first{
                                range in
                                return suraInfo.sura == range.sura
                            }
                            return self.alertAction( .addHifzSelectSura, suraName.name, hifzRange ?? suraInfo)
                        }
                        return nil
                    }
                    showAlertActions(actions, AStr.selectSura)
                }
            }
            //Couldn't get the map
            break
            
        case .addHifzSelectSura:
            let qData = QData.instance
            let currPage = currentPageIndx()
            
            if let suraInfo = selection as? SuraInfo {
                //suraInfo is selected
                let totalPages=suraInfo.endPage - suraInfo.page + 1
                
                let addHifzParams = AddHifzParams(sura: suraInfo.sura, page: currPage)
                
                if totalPages > 1 {//more than one page
                    let suraName = qData.suraName(suraIndex: suraInfo.sura)
                    var actions = [alertAction(.addHifzSelectRange,AStr.wholeSura,addHifzParams)]
                    
                    if currPage<suraInfo.endPage && currPage-suraInfo.page>0{
                        actions.append(alertAction(.addHifzSelectRange,AStr.fromSuraStart, addHifzParams.fromSelect(.fromStart) ) )
                    }
                    if currPage>suraInfo.page && suraInfo.endPage-currPage>0{
                        actions.append(alertAction( .addHifzSelectRange,AStr.toSuraEnd, addHifzParams.fromSelect(.toEnd)))
                    }
                    
                    actions.append(alertAction(.addHifzSelectRange,AStr.currentPage,addHifzParams.fromSelect(.page)))
                    
                    showAlertActions(actions, AStr.addStoYourHifz(s: suraName!.name))
                }
                else{
                    handleAlertAction(.addHifzSelectRange,addHifzParams)
                }
                
            }
            else if let hifzRange = selection as? HifzRange{
                //HifzRange is selected
                //Show "Revised today" or "Remove from Hifz"
                let actions = [
                    alertAction( .revisedHifz, AStr.revisedToday, hifzRange),
                    alertAction(.removeHifz, AStr.removeFromHifz, hifzRange),
                ]
                let desc = QData.describe(hifzTitle: hifzRange)
                if let suraName = QData.instance.suraName(suraIndex: hifzRange.sura){
                    showAlertActions(actions, AStr.suraSdescS(s: suraName.name, d: desc))
                }
            }
            break

        case .addHifzSelectRange:
            if let addHifzParams = selection as? AddHifzParams {
                if addHifzParams.select == .all {
                    //prompt user if merge will happen
                    Utils.confirmAddSuraToHifz(vc: self, sura: addHifzParams.sura){ yes in
                        if yes{
                            QData.addHifz(params: addHifzParams){ hifzRange in }
                        }
                    }
                }else{
                    QData.addHifz(params: addHifzParams){ hifzRange in }
                }
            }
            break
            
        case .revisedHifz:
            //TODO: duplicate code
            if let hifzRange = selection as? HifzRange{
                let _ = QData.promoteHifz(hifzRange){
                    snapshot in
                    Utils.showMessage(self, title: AStr.revisionSaved, message: AStr.goodJob)
                }
            }
            break
            
        case .removeHifz:
            if let hifzRange = selection as? HifzRange,
                let suraName = QData.instance.suraName(suraIndex: hifzRange.sura){
                let desc = QData.describe(hifzTitle: hifzRange)
                //TODO: duplicate code
                Utils.confirmMessage(
                    self,
                    AStr.removeSfromHifz(s: AStr.suraSdescS(s: suraName.name, d: desc)), //"Remove \(suraName.name) (\(desc)) from your hifz"
                    AStr.areYouSure,
                    .yes_destructive
                ){ yes in
                    if yes {
                        QData.deleteHifz([hifzRange]){ snapshot in }
                    }
                }
            }
            break
        
        default:
            break
        }
    }

    @objc func searchOpenAya(vc: SearchViewController){
        //print("QPagesBrowser.searchOpenAya( \(SelectStart) )")
        let qData = QData.instance
        let pageIndex = qData.pageIndex(ayaPosition: SelectStart)
        gotoPage(pageNum: pageIndex+1)
        if let currPageView = currentPageView(){
            currPageView.selectAya(aya: SelectStart)
        }
        showNavBar(false)
    }
    
    @objc func searchViewResults(vc: SearchViewController){
            self.performSegue(withIdentifier: "OpenSearchResults", sender: self)
    }

    // MARK: - Mask methods
    @objc func hideMask(){
        if MaskStart != -1 {
            setMaskStart(-1)
        }
    }

    func hideSelection(){
        SelectStart = -1
        SelectEnd = -1
        setNavigationButtonsColor()
        if let currentPageViewController = currentPageView(){
            currentPageViewController.positionSelection()
        }
    }
    
    /// Update the colors of the footer navigation arrows and close buttons based on the mask status
    func setNavigationButtonsColor(){
        var bgColor = UIColor.clear
        if MaskStart != -1 {
            bgColor = AppColors.maskNavBg
        }
//        else if SelectStart != -1 {
//            bgColor = QPageView.Colors.selectNavBg
//        }
        goNextButton.backgroundColor = bgColor
        goPrevButton.backgroundColor = bgColor
        closeButton.backgroundColor = bgColor
    }
    
    func setMaskStart(_ ayaId:Int, followPage:Bool = false ){
        MaskStart = ayaId
        if(ayaId != -1){
            SelectStart = ayaId
            SelectEnd = ayaId
        }
        positionMask(followPage)
        
        if let currPageView = currentPageView(){
            currPageView.positionSelection()
            currPageView.pageTapGesture.isEnabled = ( ayaId != -1 )
        }
        
        showNavBar(false)
        updateTitle()
    }
    
    func positionMask(_ followPage: Bool ){
        if let currPageView = currentPageView(){
            let maskPageIndex = currPageView.positionMask(animate:followPage)
            if followPage && maskPageIndex != currentPageIndx() {
                gotoPage(pageNum: maskPageIndex+1)
            }else{
                currPageView.updateViewConstraints()
            }
        }
    }
    
    // MARK: - Orientation and rotation
    
    @objc func onDeviceRotated(){
        showNavBar(false)
        if (SelectStart != -1), let currPageView = currentPageView(){
            currPageView.scrollToSelectedAya()
        }
    }

    //Not called
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return orientation
    }
    
    //Not called
    override var shouldAutorotate: Bool {
        return autoRotate
    }
    
    //Not called
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        return UIInterfaceOrientation.landscapeLeft
    }

    
    // MARK: - pageViewController data source methods
    
    //returns a viewer prior to another one
    func pageViewController(_
        pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        var index = self.indexOfViewController(viewController as! QPageView)
        if (index == 1) || (index == NSNotFound) {
            return nil
        }
        
        index -= 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    
    //Returns a viewer following another one
    func pageViewController(_
        pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController ) -> UIViewController?
    {
        var index = self.indexOfViewController(viewController as! QPageView)
        if index == NSNotFound {
            return nil
        }
        
        index += 1
        if index > self.lastPage {
            return nil
        }
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

    // MARK: - UIPageViewController delegate methods

    func pageViewController(_
            pageViewController: UIPageViewController,
            spineLocationFor orientation: UIInterfaceOrientation
        ) -> UIPageViewControllerSpineLocation
    {
        
        if (orientation == .portrait)
            || (orientation == .portraitUpsideDown)
            || (UIDevice.current.userInterfaceIdiom == .phone)
        {
            // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to true, so set it to false here.
            if  let pageViewController = self.pageViewController,
                let qPageViewController = pageViewController.viewControllers!.first as? QPageView {

                pageViewController.isDoubleSided = false

                let viewControllers = [qPageViewController]
                
//                let spine : UIPageViewControllerSpineLocation =
//                    (qPageViewController.pageIndex % 2) == 0 ? .max : .min

                self.pageViewController!.setViewControllers(
                    viewControllers,
                    direction: .forward,
                    animated: true,
                    completion: {done in }
                )
            }
            
            return .min //show only one page
        }

        // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
        let currentViewController = self.pageViewController!.viewControllers![0] as! QPageView
        
        var viewControllers: [UIViewController]

        let indexOfCurrentViewController = self.indexOfViewController(currentViewController)
        
        if (indexOfCurrentViewController == 0) || (indexOfCurrentViewController % 2 == 0) {
            let nextViewController = self.pageViewController(self.pageViewController!, viewControllerAfter: currentViewController)
            viewControllers = [currentViewController, nextViewController!]
        } else {
            
            let previousViewController = self.pageViewController(self.pageViewController!, viewControllerBefore: currentViewController)
            
            viewControllers = [previousViewController!, currentViewController]
        }

        self.pageViewController!.setViewControllers(
            viewControllers,
            direction: .forward,
            animated: true,
            completion: {done in }
        )
        
        return .mid //using two view controllers with middle spine
    }
    
    
    func pageViewController(_
        pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        updateTitle()
        showNavBar(false)
    }
    
}


