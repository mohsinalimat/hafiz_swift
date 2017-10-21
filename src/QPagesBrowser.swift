//
//  RootViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class QPagesBrowser: UIViewController, UIPageViewControllerDelegate {

    var pageViewController: UIPageViewController?
    var startingPage:Int?

    @IBOutlet weak var actionsLabel: UIBarButtonItem!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var nextSura: UIButton!
    @IBOutlet weak var prevSura: UIButton!

    override func viewWillAppear(_ animated: Bool) {
        //self.navigationController?.navigationBar.backgroundColor = .green
    }
    
    func gotoPage(_ pageNum: Int ){

        let startingViewController: QPageView = self.modelController.viewControllerAtIndex(
            pageNum,
            storyboard: self.storyboard!
            )!
        
        //pass inital set of page viewers
        let viewControllers = [startingViewController]
        
        self.pageViewController!.setViewControllers(
            viewControllers,
            direction: .forward,
            animated: false,
            completion: {done in}
        )
        
        updateTitle()
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
        self.pageViewController!.dataSource = self.modelController
        
        let uwStartingPage = self.startingPage ?? 1

        gotoPage(uwStartingPage)
        
        self.addChildViewController(self.pageViewController!)
        
        self.view.addSubview(self.pageViewController!.view)

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = self.view.bounds
        
        pageViewRect.size.height = pageViewRect.height - 30
        
        //If IPad, add 40 pixel padding around the view
        if UIDevice.current.userInterfaceIdiom == .pad {
            pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        }
        
        self.pageViewController!.view.frame = pageViewRect

        self.pageViewController!.didMove(toParentViewController: self)
        
        self.pageViewController!.view.semanticContentAttribute = .forceLeftToRight
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var modelController: QPagesDataSource {
        // Return the model controller object, creating it if necessary.
        // In more complex implementations, the model controller may be passed to the view controller.
        if _modelController == nil {
            _modelController = QPagesDataSource()
        }
        return _modelController!
    }

    var _modelController: QPagesDataSource? = nil

  
    @IBAction func clickedActions(_ sender: Any) {

    }
    
    
    // Find the active QPageView and read its pageNumber, find the suraName and update the title
    //Note viewControllers array holds one view in case of portrait and 2 in case of landscape showing two pages
    func updateTitle(){
        //reference the first QPageView
        let pageIndex = currentPageIndx()
        
        if let uwData = qData  {
            //get suraName from pageIndex
            self.title = uwData.suraName(pageIndex: pageIndex)
            self.pageNumberLabel.text = "\(pageIndex+1)"
        }
    }
    
    func currentPageIndx()->Int{
        let qPageView = self.pageViewController!.viewControllers![0] as! QPageView
        if let uwPageNumber = qPageView.pageNumber{
            return uwPageNumber - 1
        }
        return 0
    }

    // MARK: Event Hanlders
    
    func menuAction1(){
        print("Action1")
    }
    
    @IBAction func gotoNextSura(_ sender: Any) {
        if let uwData = qData {
            gotoPage( uwData.suraFirstPageIndex(prevSuraPageIndex: currentPageIndx()) + 1 )
        }
        
    }
    
    @IBAction func gotoPrevSura(_ sender: Any) {
        if let uwData = qData {
            gotoPage( uwData.suraFirstPageIndex(nextSuraPageIndex: currentPageIndx()) + 1)
        }
    }
    
//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        return true
//    }
    
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

        let indexOfCurrentViewController = self.modelController.indexOfViewController(currentViewController)
        
        if (indexOfCurrentViewController == 0) || (indexOfCurrentViewController % 2 == 0) {
            let nextViewController = self.modelController.pageViewController(self.pageViewController!, viewControllerAfter: currentViewController)
            viewControllers = [currentViewController, nextViewController!]
        } else {
            
            let previousViewController = self.modelController.pageViewController(self.pageViewController!, viewControllerBefore: currentViewController)
            
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

