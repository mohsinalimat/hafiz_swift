//
//  ModelController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */


class QPagesDataSource: NSObject, UIPageViewControllerDataSource {

    var firstPage = 1
    var lastPage = 604

    override init() {
        super.init()
        // Create the data model.
    }

    // Creates a view controller for the given index.
    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> QPageView? {

        if(index < self.firstPage) || (index > self.lastPage) {
            return nil
        }

        // Create a new view controller and pass suitable data.
        let dataViewController = storyboard.instantiateViewController(
            withIdentifier: "QPageView"
        ) as! QPageView
        dataViewController.pageNumber = index;

        return dataViewController
    }

    func indexOfViewController(_ viewController: QPageView) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.

        return viewController.pageNumber!
    }
    
    func pageIndex(_ viewController: QPageView ) -> Int {
        return self.indexOfViewController( viewController )
    }

    // MARK: - Page View Controller Data Source

    //returns a viewer prior to another one
    func pageViewController(_
        pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        var index = self.indexOfViewController(viewController as! QPageView)
        if (index == self.firstPage) || (index == NSNotFound) {
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

}

