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
        
        // force Right to Left pages direction
        func clickedAction(_ sender: UIBarButtonItem) {
        }
        //self.pageViewController.
        
        let urStartingPage = self.startingPage ?? 1

        let startingViewController: QPageView = self.modelController.viewControllerAtIndex(
            urStartingPage,
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

        self.pageViewController!.dataSource = self.modelController

        self.addChildViewController(self.pageViewController!)
        
        self.view.addSubview(self.pageViewController!.view)

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = self.view.bounds
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        }
        
        self.pageViewController!.view.frame = pageViewRect

        self.pageViewController!.didMove(toParentViewController: self)
        
        self.pageViewController!.view.semanticContentAttribute = .forceLeftToRight
        
        updateTitle()
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
        let mnuController = UIMenuController.shared
        //mnuController.setTargetRect(actionsLabel.fra, in: <#T##UIView#>)
        mnuController.setTargetRect(CGRect(x:0,y:0,width:100,height:20), in: self.view)
        
        let lookupMenu = UIMenuItem(title: "Item",
                                    action: #selector(QPagesBrowser.menuAction1))

        mnuController.menuItems = [lookupMenu]
        
        // This makes the menu item visible.
        mnuController.setMenuVisible(true, animated: true)
    }
    
    func menuAction1(){
        print("Action1")
    }
    
    func updateTitle(){
        let currentViewController = self.pageViewController!.viewControllers![0] as! QPageView
        
        let pageNumber = self.modelController.pageIndex( currentViewController )
        
        if let urData = qData {
            self.title = urData.suraName(pageIndex: pageNumber - 1)
        }
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
            return .min
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
        
        return .mid
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

