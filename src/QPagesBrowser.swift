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

    let firstPage = 1
    let lastPage = 604
    
    var pageViewController: UIPageViewController?
    var startingPage:Int?
    var closeBtn: UIBarButtonItem?


    // MARK: - UIViewController delegate methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        menuItems.addGestureRecognizer(UITapGestureRecognizer(target:self,action:#selector(hideMenu)))
        menuItems.frame = self.view.frame

        closeBtn = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(hideMask))

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
//        self.pageViewController!.view.semanticContentAttribute = .forceLeftToRight
        
        gotoPage(self.startingPage ?? 1)
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

        
        // setting the hidesBarsOnSwift property to false
        // since it doesn't make sense in this case,
        // but is was set to true in the last VC
        //navigationController?.hidesBarsOnSwipe = false
        
        // setting hidesBarsOnTap to true
        //navigationController?.hidesBarsOnTap = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("QPagesBrowser willDisappear")
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
        //get suraName from pageIndex
        self.title = qData.suraName(pageIndex: pageIndex)
        self.pageNumberLabel.text = "\(pageIndex+1)"
    }
    
    func currentPageIndx()->Int{
        if let qPageView = currentPageView(), let pageNumber = qPageView.pageNumber{
            return pageNumber - 1
        }
        return 0
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

    // MARK: - Event Hanlders
    
    //Handle Navigation Bar actions
    @IBOutlet var menuItems: UIView!
    
    @IBAction func onSwipePageUp(_ sender: Any) {
        if navigationController?.navigationBar.isHidden == false{
            navigationController?.navigationBar.isHidden = true
        }else{
            showMenu(sender)
        }
    }

    @IBAction func onSwipePageDown(_ sender: Any) {
        navigationController?.navigationBar.isHidden = false
    }

    @IBAction func showMenu(_ sender: Any) {
//        if let menuItems = self.menuItems{
//            if menuItems.superview == nil {
//                self.view.addSubview(menuItems)
//                menuItems.frame = self.view.frame
//            }else{
//                hideMenu()
//            }
//        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let addToHifz = UIAlertAction(title: "Add to Hifz", style: .default) { (action) in
            print(action)
        }

        let bookmark = UIAlertAction(title: "Bookmark", style: .default) { (action) in
            print(action)
        }
        
        let search = UIAlertAction(title: "Search", style: .default) { (action) in
            //print(action)
            self.performSegue(withIdentifier: "PopupSearch", sender: self)
        }

        let close = UIAlertAction(title: "Close", style: .cancel) { (action) in
            print(action)
        }
        
        alert.addAction(addToHifz)
        	alert.addAction(bookmark)
        alert.addAction(search)
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
            currPageView.positionSelection()
        }
    }

    @objc func hideMenu(){
        menuItems.removeFromSuperview()
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
        }
        
        if let rightBarItems = self.navigationItem.rightBarButtonItems{
            if( MaskStart != -1 && rightBarItems.count == 1){//show the cancel button
                self.navigationItem.rightBarButtonItems = [rightBarItems[0], closeBtn!]
            }else if( MaskStart == -1 && rightBarItems.count > 1){//hide the cancel button
                self.navigationItem.rightBarButtonItems = [rightBarItems[0]]
            }
        }
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
    
    func pageViewController(_ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]) {
        for viewController in pendingViewControllers{
            if let qPageView = viewController as? QPageView {
                qPageView.positionMask( followPage: false )
                qPageView.positionSelection()
                //print ("Positioned page\(qPageView.pageNumber!)")
            }
        }
        navigationController?.navigationBar.isHidden = true
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

