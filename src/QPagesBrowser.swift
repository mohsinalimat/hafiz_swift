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
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var nextSura: UIButton!
    @IBOutlet weak var prevSura: UIButton!
    @IBOutlet weak var pagesContainer: UIView!
    @IBOutlet weak var suraName: UILabel!
    @IBOutlet weak var nextPageButton: UIButton!
    
    let firstPage = 1
    let lastPage = 604
    
    var pageViewController: UIPageViewController?
    var startingPage:Int?
    //var closeBtn: UIBarButtonItem?


    
    // MARK: - UIViewController delegate methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        menuItems.addGestureRecognizer(UITapGestureRecognizer(target:self,action:#selector(hideMenu)))
        menuItems.frame = self.view.frame

//        closeBtn = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(hideMask))

        // Configure the page view controller and add it as a child view controller.
//        self.pageViewController = UIPageViewController(transitionStyle: .scroll,
//                                                       navigationOrientation: .horizontal,
//                                                       options: nil)
        // set this object as a delegate
        self.pageViewController = self.childViewControllers[0] as? UIPageViewController
        self.pageViewController!.delegate = self
        self.pageViewController!.dataSource = self
        
//
//
//        self.addChildViewController(self.pageViewController!)//TODO: required?
//        self.view.addSubview(self.pageViewController!.view)
//        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
//        var pageViewRect = self.view.bounds
//        pageViewRect.size.height = pageViewRect.height - 30
//
//        //If IPad, add 40 pixel padding around the view
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
//        }
       
//        self.pageViewController!.view.frame = pageViewRect
//        self.pageViewController!.didMove(toParentViewController: self)//TODO: required?
        
        gotoPage(self.startingPage ?? 1)
        //scroll to selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let curr_view = self.currentPageView() {
                curr_view.scrollToSelectedAya()
            }
        }

    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        navigationController?.navigationBar.isHidden = true
    }
    
    let searchOpenAyaNotification = NSNotification.Name(rawValue: "searchOpenAya")

    override func viewWillAppear(_ animated: Bool) {
        print("QPagesBrowser willAppear")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchOpenAya),
            name: searchOpenAyaNotification,
            object: nil
        )
        navigationController?.navigationBar.isHidden = true
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
        navigationController?.navigationBar.isHidden = true
        NotificationCenter.default.removeObserver(self)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - New class methods


    func gotoPage(_ pageNum: Int ){
        let currPageIndex = currentPageIndx()
        
        if(currPageIndex+1==pageNum){
            return
        }
        
        let startingViewController: QPageView = viewControllerAtIndex(
            pageNum,
            storyboard: self.storyboard!
            )!
        
        //pass inital set of page viewers
        let viewControllers = [startingViewController]
        
        self.pageViewController!.setViewControllers(
            viewControllers,
            direction: pageNum <= currPageIndex ? .forward : .reverse,
            animated: true,
            completion: {done in}
        )
        
        updateTitle()
    }
    
    // Creates a view controller for the given index.
    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> QPageView? {
        
        if(index < firstPage) || (index > lastPage) {
            return nil
        }
        
        // Create a new storyboard view controller and set the required data
        let dataViewController = storyboard.instantiateViewController(
            withIdentifier: "QPageView"
            ) as! QPageView
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
        let qData = QData.instance()
        //let suraNumber = qData.suraIndex( pageIndex: pageIndex ) + 1
        let partNumber = qData.partIndex( pageIndex: pageIndex ) + 1
        
        let suraName = qData.suraName(pageIndex: pageIndex)!
        self.title = suraName

        let nextPageArrow = pageIndex < lastPage - 2 ? " >>" : ""
        let pageInfo = String(format:NSLocalizedString("FooterInfo", comment: ""), partNumber,pageIndex+1)
        self.nextPageButton.setTitle("\(pageInfo)\(nextPageArrow)", for: .normal)
        
        let maskedAya = (MaskStart == -1) ? "" : ":\(qData.ayaLocation(MaskStart).aya+1)"
        //self.suraName.text = String(format:NSLocalizedString("FooterSuraName", comment: ""),suraNumber,suraName,maskedAya)
        self.suraName.text = suraName + maskedAya
    }
    
    func currentPageIndx()->Int{
        if let qPageView = currentPageView(), let pageNumber = qPageView.pageNumber{
            return pageNumber - 1
        }
        return -1
    }
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
    
    func showSearch(){
        self.performSegue(withIdentifier: "PopupSearch", sender: self)
    }

    // MARK: - Event Hanlders
    
    //Handle Navigation Bar actions
    @IBOutlet var menuItems: UIView!
    
    @IBAction func onPageTap(_ sender: Any) {
        if (navigationController?.navigationBar.isHidden)! {
            //show the navbar
            navigationController?.navigationBar.isHidden = false
        }else{
            navigationController?.navigationBar.isHidden = true
        }
    }
    
    
    @IBAction func showMenu(_ sender: Any) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let startRevise = UIAlertAction(title: "Revise", style: .default) { (action) in
            let qData = QData.instance()
            
            self.setMaskStart( qData.ayaPosition(pageIndex: self.currentPageIndx()))
        }

        let search = UIAlertAction(title: "Search", style: .default) { (action) in
            self.showSearch()
        }

        let addToHifz = UIAlertAction(title: "Add to Hifz", style: .default) { (action) in
            print(action)
        }

        let bookmark = UIAlertAction(title: "Bookmark", style: .default) { (action) in
            print(action)
        }
        
        let close = UIAlertAction(title: "Close", style: .cancel) { (action) in
            print(action)
        }
        
        alert.addAction(startRevise)
        alert.addAction(search)
        alert.addAction(addToHifz)
        alert.addAction(bookmark)
        alert.addAction(close)
        
        self.present(alert, animated: true) {
            print( "Alert Dismissed" )
        }
    }

    @objc func searchOpenAya(vc: SearchViewController){
        print("QPagesBrowser.searchOpenAya( \(SelectStart) )")
        let qData = QData.instance()
        let pageIndex = qData.pageIndex(ayaPosition: SelectStart)
        gotoPage(pageIndex+1)
        if let currPageView = currentPageView(){
            currPageView.selectAya(aya: SelectStart)
        }
        navigationController?.navigationBar.isHidden = true
    }

    @objc func hideMenu(){
        menuItems.removeFromSuperview()
    }
    
    @IBAction func clickClose(_ sender: Any) {
        if MaskStart != -1 {//If mask is On, clear it first
            setMaskStart(-1)
        }else{//go back to calling viewController ( Home )
            navigationController?.popViewController(animated: true)
        }
    }
   
    @IBAction func navigationSearchClicked(_ sender: Any) {
        showSearch()
    }
    
    @IBAction func nextPageClicked(_ sender: Any) {
        let curr_page_index = currentPageIndx() + 1
        if curr_page_index < lastPage {
            gotoPage(curr_page_index+1)
        }
    }
    
    // MARK: - Mask methods
    @objc func hideMask(){
        if MaskStart != -1 {
            setMaskStart(-1)
        }
    }

    
    func setMaskStart(_ ayaId:Int, followPage:Bool = false ){
        MaskStart = ayaId
        SelectStart = ayaId
        SelectEnd = ayaId
        positionMask(followPage)
        
        if let currPageView = currentPageView(){
            currPageView.positionSelection()
            currPageView.pageTapGesture.isEnabled = ( ayaId != -1 )
        }
        
        navigationController?.navigationBar.isHidden = true
        
        updateTitle()
        
//        cancelReview.isHidden = (ayaId == -1)
        
//        if let rightBarItems = self.navigationItem.rightBarButtonItems{
//            if( MaskStart != -1 && rightBarItems.count == 1){//show the cancel button
//                self.navigationItem.rightBarButtonItems = [rightBarItems[0], closeBtn!]
//            }else if( MaskStart == -1 && rightBarItems.count > 1){//hide the cancel button
//                self.navigationItem.rightBarButtonItems = [rightBarItems[0]]
//            }
//        }
    }
    
    func positionMask(_ followPage: Bool ){
        if let currPageView = currentPageView(){
            let maskPageIndex = currPageView.positionMask()
            if followPage && maskPageIndex != currentPageIndx() {
                gotoPage(maskPageIndex)
            }else{
                currPageView.updateViewConstraints()
            }
        }
    }
    
    
    @IBAction func gotoNextSura(_ sender: Any) {
        if MaskStart != -1 {
            if let qPageView = self.currentPageView() {
                qPageView.advanceMask(true)
            }
        }else{
            gotoPage( QData.instance().suraFirstPageIndex(prevSuraPageIndex: currentPageIndx()) + 1 )
        }
    }
    
    @IBAction func gotoPrevSura(_ sender: Any) {
        if MaskStart != -1 {
            if let qPageView = self.currentPageView() {
                qPageView.retreatMask( true )
            }
        }else{
            gotoPage( QData.instance().suraFirstPageIndex(nextSuraPageIndex: currentPageIndx()) + 1)
        }
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
        updateTitle()
        
        if (orientation == .portrait) || (orientation == .portraitUpsideDown) || (UIDevice.current.userInterfaceIdiom == .phone) {
            // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to true, so set it to false here.
            let currentViewController = self.pageViewController!.viewControllers![0]
            let viewControllers = [currentViewController]
            self.pageViewController!.setViewControllers(
                viewControllers,
                direction: .forward,
                animated: true,
                completion: {done in }
            )

            self.pageViewController!.isDoubleSided = false
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
    }
    
}

