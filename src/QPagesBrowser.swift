//
//  RootViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class QPagesBrowser: UIViewController
    ,UIPageViewControllerDelegate
    ,UIPageViewControllerDataSource
    {
    
    @IBOutlet weak var actionsLabel: UIBarButtonItem!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var nextSura: UIButton!
    @IBOutlet weak var prevSura: UIButton!

    let firstPage = 1
    let lastPage = 604
    
    var pageViewController: UIPageViewController?
    var startingPage:Int?


    // MARK: - UIViewController delegate methods
    override func viewWillAppear(_ animated: Bool) {
        //self.navigationController?.navigationBar.backgroundColor = .green
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Configure the page view controller and add it as a child view controller.
        self.pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                       navigationOrientation: .horizontal,
                                                       options: nil)
        // set this object as a delegate
        self.pageViewController!.delegate = self
        self.pageViewController!.dataSource = self
        
        gotoPage(self.startingPage ?? 1)
        
        self.addChildViewController(self.pageViewController!)//TODO: required?
        
        self.view.addSubview(self.pageViewController!.view)

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = self.view.bounds
        
        pageViewRect.size.height = pageViewRect.height - 30
        
        //If IPad, add 40 pixel padding around the view
        if UIDevice.current.userInterfaceIdiom == .pad {
            pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        }
        
        self.pageViewController!.view.frame = pageViewRect

        self.pageViewController!.didMove(toParentViewController: self)//TODO: required?
        
        self.pageViewController!.view.semanticContentAttribute = .forceLeftToRight
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    var _modelController: QPagesDataSource? = nil
//    var modelController: QPagesDataSource {
//        // Return the model controller object, creating it if necessary.
//        // In more complex implementations, the model controller may be passed to the view controller.
//        if _modelController == nil {
//            _modelController = QPagesDataSource()
//        }
//        return _modelController!
//    }
//

    
    // MARK: - New class methods

    func gotoPage(_ pageNum: Int ){
        let currPage = currentPageIndx()
        let startingViewController: QPageView = viewControllerAtIndex(
            pageNum,
            storyboard: self.storyboard!
            )!
        
        //pass inital set of page viewers
        let viewControllers = [startingViewController]
        
        self.pageViewController!.setViewControllers(
            viewControllers,
            direction: pageNum < currPage ? .forward : .reverse,
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
        if  let pageViewController = self.pageViewController,
            let viewControllers = pageViewController.viewControllers
        {
            if viewControllers.count>0 {
                
                if let qPageView = viewControllers[0] as? QPageView,
                    let pageNumber = qPageView.pageNumber
                {
                    return pageNumber - 1
                }
            }
        }
        return 0
    }

    // MARK: - Event Hanlders
    
    //Handle Navigation Bar actions
    @IBAction func clickedActions(_ sender: Any ) {
    }

    @IBAction func gotoNextSura(_ sender: Any) {
        gotoPage( QData.instance().suraFirstPageIndex(prevSuraPageIndex: currentPageIndx()) + 1 )
    }
    
    @IBAction func gotoPrevSura(_ sender: Any) {
        gotoPage( QData.instance().suraFirstPageIndex(nextSuraPageIndex: currentPageIndx()) + 1)
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

