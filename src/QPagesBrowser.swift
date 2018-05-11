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
var SelectStart = -1
var SelectEnd = -1

class QPagesBrowser: UIViewController
    ,UIPageViewControllerDelegate
    ,UIPageViewControllerDataSource
    {
    
    @IBOutlet weak var actionsLabel: UIBarButtonItem!
    @IBOutlet weak var nextSura: UIButton!
    @IBOutlet weak var prevSura: UIButton!
    @IBOutlet weak var pagesContainer: UIView! //TODO: unused
    @IBOutlet weak var suraName: UILabel!
    @IBOutlet weak var nextPageButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    //TODO: use 0 based numbering
    let firstPage = 1
    let lastPage = 604
    
    var pageViewController: UIPageViewController?
    var startingPage:Int?
    
    // MARK: - UIViewController delegate methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        menuItems.addGestureRecognizer(UITapGestureRecognizer(target:self,action:#selector(hideMenu)))
        menuItems.frame = self.view.frame

//        closeBtn = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(hideMask))

        // Create Configure the page view controller and add it as a child view controller.
//        self.pageViewController = UIPageViewController(transitionStyle: .scroll,
//                                                       navigationOrientation: .horizontal,
//                                                       options: nil)
        // create a reference to the embedded UIPageViewController
        self.pageViewController = self.childViewControllers[0] as? UIPageViewController
        // Set this object as the delegate for the page view controller
        self.pageViewController!.delegate = self
        self.pageViewController!.dataSource = self
        
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressNext))
        nextSura.addGestureRecognizer(longGesture)
        
//
//
        //self.addChildViewController(self.pageViewController!)//TODO: required?
        //self.view.addSubview(self.pageViewController!.view)
        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        //var pageViewRect = self.view.bounds
        //pageViewRect.size.height = pageViewRect.height - 30
//
//        //If IPad, add 40 pixel padding around the view
        //if UIDevice.current.userInterfaceIdiom == .pad {
        //    pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        //}
       
        //self.pageViewController!.view.frame = pageViewRect
        //self.pageViewController!.didMove(toParentViewController: self)//TODO: required?
        
        gotoPage(pageNum: startingPage ?? 1)
        
        
        setNavigationButtonsColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        hideNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //print("QPagesBrowser willAppear")
        hideNavBar()
        
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
        print("QPagesBrowser willDisappear")
        hideNavBar()
        NotificationCenter.default.removeObserver(self)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - New class methods

    @objc func onLongPressNext(_ sender: UILongPressGestureRecognizer){
        if MaskStart != -1, let pageView = currentPageView() {
            if sender.state == .began {
                pageView.maskHeadStartX.constant = pageView.maskHeadStartX.constant + 60
            }
            else if sender.state == .ended{
                pageView.maskHeadStartX.constant = pageView.maskHeadStartX.constant - 60
            }
        }
    }

    func gotoPage(pageNum:Int){
        let _ = checkGotoPage(pageNum: pageNum)
    }

    func gotoPage(ayaPos:Int){
        let _ = checkGotoPage(ayaPos: ayaPos)
    }

    //TODO: create two pages if ipad landscape mode
    func checkGotoPage( pageNum: Int )->Bool{
        let currPageIndex = currentPageIndx()
        
        if  (currPageIndex+1 != pageNum),
            let pageViewController = self.pageViewController,
            let startingViewController = viewControllerAtIndex( pageNum, storyboard: self.storyboard! ){
        
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
            
            //scroll to selection
            if SelectStart != -1 {
                //Similar to window.setTimeout()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if let curr_view = self.currentPageView() {
                        curr_view.scrollToSelectedAya()
                    }
                }
            }

            return true
        }
        
        return false
    }

    func checkGotoPage(ayaPos:Int)->Bool{
        let qData = QData.instance
        let selectionPage = qData.pageIndex(ayaPosition: ayaPos)
        if selectionPage != self.currentPageIndx(){
            //TODO: scroll to ayaPos
            return checkGotoPage(pageNum: selectionPage+1)
        }
        return false
    }

    // Creates a view controller for the given page number.
    //TODO: return array of two view controllers, reuse existing view controllers if already created
    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> QPageView? {
        
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

    // Find the active QPageView and read its pageNumber, find the suraName and update the title
    //Note viewControllers array holds one view in case of portrait and 2 in case of landscape showing two pages
    func updateTitle(){
        //reference the first QPageView
        let pageIndex = currentPageIndx()
        let qData = QData.instance
        //let suraNumber = qData.suraIndex( pageIndex: pageIndex ) + 1
        let partNumber = qData.partIndex( pageIndex: pageIndex ) + 1
        
        let suraName = qData.suraName(pageIndex: pageIndex)!
        self.title = suraName.name

        //let nextPageArrow = pageIndex < lastPage - 2 ? " >>" : ""
        let pageInfo = String(format:NSLocalizedString("FooterInfo", comment: ""), partNumber,pageIndex+1)
        self.nextPageButton.setTitle(pageInfo, for: .normal)
        
        //let maskedAya = (MaskStart == -1) ? "" : ":\(qData.ayaLocation(MaskStart).aya+1)"
        self.suraName.text = suraName.name //+ maskedAya
        
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
    func currentSuras()->SuraInfoList?{
//        if let pageView = currentPageView(){
//            //return pageView.sura
//        }
        return nil
    }
    
    func showSearch(){
        self.performSegue(withIdentifier: "PopupSearch", sender: self)
    }

    // MARK: - Event Hanlders
    
    //Handle Navigation Bar actions
    @IBOutlet var menuItems: UIView!
    
    @IBAction func onPageTap(_ sender: Any) {
        hideNavBar( navigationController?.navigationBar.isHidden == false)
    }
    
    // MARK: - Actions Alert
    
    @IBAction func showMenu(_ sender: Any) {
        let qData = QData.instance
        let startRevise = MaskStart == -1 ? alertAction("revise", "Revise") : nil
        
        var addUpdateHifzTitle = "Add/Update Hifz"
        
        if let pageView = self.currentPageView(),
            let pageNumber = pageView.pageNumber,
            let hifzList = pageView.hifzList,
            let pageMap = pageView.pageMap
        {
            let suraInfoList = qData.pageSuraInfoList(pageNumber-1, pageMap: pageMap)
            //Decide whether to show "add hifz", "add/update hifz" or "update hifz"
            if hifzList.count == 0{
                addUpdateHifzTitle = "Add to Hifz"
            }else if hifzList.count == suraInfoList.count {
                addUpdateHifzTitle = "Update Hifz"
            }
        }
        
        let addToHifz = alertAction("addUpdateHifz", addUpdateHifzTitle) // check if hifzRange is active
        let bookmark = isBookmarked() ? nil : alertAction("bookmark", "Bookmark")
        
        showAlertActions([
            startRevise,
            addToHifz,
            bookmark
        ])
    }

    func handleAlertAction(_ id: String,_ selection: Any? = nil ){
        switch id {
        case "revise":
            if SelectStart != -1 {
                self.setMaskStart(SelectStart)
            }else{
                let qData = QData.instance
                self.setMaskStart( qData.ayaPosition(pageIndex: self.currentPageIndx()))
            }
            break
            
        case "bookmark":
            if false == QData.createBookmark(page: self.currentPageIndx(), block:{ (snapshot) in }) {
                Utils.showMessage(self, title: "Authentication", message: "Sign In is required for this feature")
            }
            break
            
        case "addUpdateHifz":
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
                    handleAlertAction("addHifzSelectSura", hifzRange ?? suraInfo )
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
                            return self.alertAction("addHifzSelectSura", suraName.name, hifzRange ?? suraInfo)
                        }
                        return nil
                    }
                    showAlertActions(actions, "Select Sura")
                }
            }
            //Couldn't get the map
            break
            
        case "addHifzSelectSura":
            let qData = QData.instance
            let currPage = currentPageIndx()
            
            if let suraInfo = selection as? SuraInfo {
                //suraInfo is selected
                let totalPages=suraInfo.endPage - suraInfo.page + 1
                
                let addHifzParams = AddHifzParams(sura: suraInfo.sura, page: currPage)
                
                if totalPages > 1 {//more than one page
                    let suraName = qData.suraName(suraIndex: suraInfo.sura)
                    var actions = [alertAction("addHifzSelectRange","Whole Sura",addHifzParams)]
                    
                    if currPage<suraInfo.endPage && currPage-suraInfo.page>0{
                        actions.append(alertAction("addHifzSelectRange","From Sura Start", addHifzParams.fromSelect(.fromStart) ) )
                    }
                    if currPage>suraInfo.page && suraInfo.endPage-currPage>0{
                        actions.append(alertAction("addHifzSelectRange","To Sura End", addHifzParams.fromSelect(.toEnd)))
                    }
                    
                    actions.append(alertAction("addHifzSelectRange","Current Page",addHifzParams.fromSelect(.page)))
                    
                    showAlertActions(actions, "Add \(suraName!.name) to your hifz")
                }
                else{
                    handleAlertAction("addHifzSelectRange",addHifzParams)
                }
                
            }
            else if let hifzRange = selection as? HifzRange{
                //HifzRange is selected
                //Show "Revised today" or "Remove from Hifz"
                let actions = [
                    alertAction("revisedHifz", "Revised today", hifzRange),
                    alertAction("removeHifz", "Remove from Hifz", hifzRange),
                ]
                showAlertActions(actions, "{Hifz Range Description}")
            }
            break
        case "addHifzSelectRange":
            if let addHifzParams = selection as? AddHifzParams {
                QData.addHifz(params: addHifzParams){
                    hifzRange in
                    print( "Added HifzRange \(hifzRange)")
                }
            }
            break
        case "revisedHifz":
            if let hifzRange = selection as? HifzRange{
                let _ = QData.promoteHifz(hifzRange){
                    snapshot in
                    Utils.showMessage(self, title: "Revision saved", message: "Good Job :)")
                }
            }
            break
        case "removeHifz":
            if let hifzRange = selection as? HifzRange {
                Utils.confirmMessage(
                    self,
                    "Confirm Remove Hifz",
                    "{{hifzDescription}}", .yes_destructive
                ){ isYes in
                    if isYes {
                        QData.deleteHifz([hifzRange]){
                            snapshot in
                        }
                    }
                }
            }
            break
        default:
            print( "Unknown Action \(id)" )
        }
    }
    // a utility function to create an action choice
    func alertAction(_ id:String,_ title:String,_ selection:Any? = nil)->UIAlertAction{
        return UIAlertAction(title: title, style: .default, handler: { (action) in
            self.handleAlertAction(id, selection)
        })
    }
    
    // A utility function to present a group of action items in a slid in alert
    func showAlertActions(_ actions:[UIAlertAction?],_ title:String? = nil, msg:String? = nil){
        
        //create the controller
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .actionSheet)
        
        //loop to add all actions
        actions.forEach{(action) in
            if let action = action {
                alertController.addAction(action)
            }
        }
        
        //Add the cancel action
        alertController.addAction( UIAlertAction(title: "Cancel", style: .cancel) )
        
        //show the actions
        self.present(alertController, animated: true)
    }

    
    @objc func onDeviceRotated(){
        if (SelectStart != -1), let currPageView = currentPageView(){
            currPageView.scrollToSelectedAya()
        }
    }
    
    @objc func searchOpenAya(vc: SearchViewController){
        print("QPagesBrowser.searchOpenAya( \(SelectStart) )")
        let qData = QData.instance
        let pageIndex = qData.pageIndex(ayaPosition: SelectStart)
        gotoPage(pageNum: pageIndex+1)
        if let currPageView = currentPageView(){
            currPageView.selectAya(aya: SelectStart)
        }
        hideNavBar()
    }
    
    @objc func searchViewResults(vc: SearchViewController){
        //if let navController = navigationController{
            //navController.popToRootViewController(animated: true)
            self.performSegue(withIdentifier: "OpenSearchResults", sender: self)
        //}
    }

    @objc func hideMenu(){
        menuItems.removeFromSuperview()
    }
    
    @IBAction func clickClose(_ sender: Any) {
        if MaskStart != -1 {//If mask is On, clear it first
            setMaskStart(-1)
            hideSelection()
        }
        else if SelectStart != -1 {
            if checkGotoPage(ayaPos: SelectStart){
                //If selection starts in different page, navigate to that page before hiding the selection
                if let currPageView = self.currentPageView(){
                    currPageView.scrollToSelectedAya()
                }
                return
            }
            hideSelection()
        }
        else{//go back to calling viewController ( Home )
            navigationController?.popViewController(animated: true)
        }
    }
   
    @IBAction func navigationSearchClicked(_ sender: Any) {
        showSearch()
    }
    
    @IBAction func nextPageClicked(_ sender: Any) {
//        let curr_page_index = currentPageIndx() + 1
//        if curr_page_index < lastPage {
//            gotoPage(pageNum: curr_page_index+1)
//        }
        showMenu(sender)
        
    }
    
    var autoRotate = true
    var orientation = UIInterfaceOrientationMask.all
    
    @IBAction func onPinchAction(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .ended {
            autoRotate = true

            print ("Current Portrait is \(UIDevice.current.orientation.isPortrait)")

            if sender.scale > 1 {
                //AppDelegate.orientation = .landscape
                orientation = .landscape
            }
            else{
                //AppDelegate.orientation = .portrait
                orientation = .portrait
            }
            
            //DispatchQueue.main.async {// set in the UI thread
            UIDevice.current.setValue(AppDelegate.orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            print ("New Portrait is \(UIDevice.current.orientation.isPortrait)")
            //}

            //Deprecated UIApplication.shared.setStatusBarOrientation(UIInterfaceOrientation.landscapeLeft, animated: true)
            //print( self.shouldAutorotate )
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
    
    
//    @IBAction func onSwipePageDown(_ sender: UISwipeGestureRecognizer) {
//        if sender.state == .ended {
//            hideNavBar(false)
//        }
//    }
    
    @IBOutlet var contextMenu: UIView!
    
    @IBAction func showContextMenu(_ sender: Any) {
//        self.view.addSubview(contextMenu)
//        contextMenu.frame = CGRect(x: 0, y: 0, width: 200, height: 300)
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
    func setNavigationButtonsColor(){
        var bgColor = UIColor.clear
        if MaskStart != -1 {
            bgColor = QPageView.Colors.maskNavBg
        }
        else if SelectStart != -1 {
            bgColor = QPageView.Colors.selectNavBg
        }
        nextSura.backgroundColor = bgColor
        prevSura.backgroundColor = bgColor
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
        
        hideNavBar()
        updateTitle()
    }
    
    func positionMask(_ followPage: Bool ){
        if let currPageView = currentPageView(){
            let maskPageIndex = currPageView.positionMask()
            if followPage && maskPageIndex != currentPageIndx() {
                gotoPage(pageNum: maskPageIndex+1)//TODO: check
            }else{
                currPageView.updateViewConstraints()
            }
        }
    }
    
    @IBAction func gotoNextSura(_ sender: Any) {
        hideNavBar()
        if MaskStart != -1 {
            if let qPageView = currentPageView() {
                qPageView.advanceMask(true)
            }
        }
        else if SelectStart != -1 {
            if !checkGotoPage(ayaPos: SelectStart){
                if let currPageView = currentPageView(){
                    currPageView.selectAya( aya: SelectStart+1 )
                    gotoPage(ayaPos:SelectStart)
                }
            }
        }
        else{
            let suraFirstPageIndex = QData.instance.suraFirstPageIndex(prevSuraPageIndex: currentPageIndx())
            gotoPage( pageNum: suraFirstPageIndex + 1 )
        }
    }
    
    @IBAction func gotoPrevSura(_ sender: Any) {
        hideNavBar()
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
            let prevSuraPageIndex = QData.instance.suraFirstPageIndex(nextSuraPageIndex: currentPageIndx())
            gotoPage( pageNum: prevSuraPageIndex + 1)
        }
    }
    
    func hideNavBar(_ hide:Bool = true ){
        navigationController?.navigationBar.isHidden = hide
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
        //updateTitle()
        
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
        hideNavBar()
    }
    
}

//class PageAlertAction : UIAlertAction {
//    var id:String?
//    convenience init(id:String, title: String?, style: UIAlertActionStyle, handler: ((PageAlertAction) -> Swift.Void)? = nil){
//        self.init(title:title,style:style,handler:{(action) in
//            if let handler = handler, let action = action as PageAlertAction{
//                handler( action )
//            }
//        })
//    }
//
//}
