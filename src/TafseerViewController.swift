//
//  TafseerViewController.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 9/29/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

let TafseerSources = [
    "ar.muyassar",//Muyassar
    "ar.jalalayn",//Jalalayn
    "en.yusufali",//English
    "id.indonesian",//Indonesian
    "ms.basmeih", //Malay
    "ta.tamil",//Tamil
    "ur.maududi",//Urdu
    "tr.golpinarli",//Turkish
    "fr.hamidullah",//French
    "de.aburida"//Deutch
]

class TafseerViewController: UIViewController,
    UIPageViewControllerDelegate,
    UIPageViewControllerDataSource,
    UIPickerViewDelegate,
    UIPickerViewDataSource
{
    static var selectedTafseer = 0
    
    @IBOutlet weak var PageViewFrame: UIView!
    @IBOutlet weak var tafseerSourceSelector: UIPickerView!

    var firstAya = 0
    var lastAya = 6236
    var pageViewController:UIPageViewController?
    var ayaPosition:Int = 0

    // MARK: UIViewController delegate methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Create horizontal pager
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical,
            options: nil
        )
        
        //Setup the pager delegate and dataSource
        if let pvc = pageViewController,
            let pvframe = PageViewFrame
        {
            pvc.delegate = self
            pvc.dataSource = self
            pvc.view.semanticContentAttribute = .forceRightToLeft

            //make it child of the current controller for UIViewController.parent to work
            self.addChildViewController(pvc)

            //locate the pager inside a dedicated frame
            pvframe.addSubview(pvc.view)
            pvc.view.frame = pvframe.bounds
        }

        //Show initial pager page
        gotoAya(ayaPosition)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //navigationController?.setNavigationBarHidden(false, animated: true)
        Utils.showNavBar(self)
    }

    // MARK: Class methods
    func gotoAya(_ ayaPosition: Int ){
        //TODO: support two pages
        let viewControllers = [ createAyaView(ayaPosition) ]
        
        pageViewController!.setViewControllers(
           viewControllers,
           direction: (self.ayaPosition >= ayaPosition) ? .reverse : .forward,
            //direction: .forward
           animated: true,
           completion: nil)
        
        self.ayaPosition = ayaPosition
        
        updatePicker()
    }
    
    func createAyaView(_ ayaIndex: Int)->UIViewController{
        let viewController = storyboard!.instantiateViewController(withIdentifier: "TafseerAyaView")
        if let tafseerAyaView = viewController as? TafseerAyaView{
            tafseerAyaView.ayaPosition = ayaIndex
            tafseerAyaView.selectedTafseer = TafseerSources[TafseerViewController.selectedTafseer]
        }
        return viewController
    }

    func updatePicker(){
        tafseerSourceSelector.selectRow(TafseerViewController.selectedTafseer, inComponent: 0, animated: true)
        let qData = QData.instance
        if let tafseerView = pageViewController!.viewControllers![0] as? TafseerAyaView{
            let (cSuraIndex, _) = qData.ayaLocation( ayaPosition )
            ayaPosition = tafseerView.ayaPosition!
            let (suraIndex,ayaIndex) = qData.ayaLocation( ayaPosition )
            tafseerSourceSelector.selectRow(suraIndex, inComponent: 1, animated: true)
            if cSuraIndex != suraIndex {
                tafseerSourceSelector.reloadComponent(2)//reload verse list
            }
            tafseerSourceSelector.selectRow(ayaIndex, inComponent: 2, animated: true)
        }
    }

    func updateAyaPosition( sura:Int ){
        let qData = QData.instance
        let ayaPosition = qData.ayaPosition(sura: sura, aya: 0)
        gotoAya(ayaPosition)
        tafseerSourceSelector.reloadComponent(2)//refresh Ayat
    }
    
    func updateAyaPosition( aya:Int ){
        let qData = QData.instance
        let (sIndex,_) = qData.ayaLocation(self.ayaPosition) //read current sura
        let ayaPosition = qData.ayaPosition(sura: sIndex, aya: aya)//create new position
        gotoAya(ayaPosition)//update current position
    }

    // MARK: Action handlers
    
    @IBAction func clickNext(_ sender: Any) {
        if ayaPosition+1 < lastAya {
            gotoAya( ayaPosition + 1 )
        }
    }
    @IBAction func clickPrevious(_ sender: Any) {
        if ayaPosition > 0 {
            gotoAya( ayaPosition - 1 )
        }
    }

    @IBAction func clickSelect(_ sender: Any) {
        //navigationController?.removeQPageBrowser()
        SelectStart = ayaPosition
        SelectEnd = ayaPosition
        navigationController?.popViewController(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: AppNotifications.searchOpenAya,
                object: self
            )
        }
    }
    
    // MARK: pageViewController delegate methods

    func pageViewController(
        _ pageViewController: UIPageViewController,
        spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation
    {
        return .min
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool)
    {
        updatePicker()
    }
    

    // MARK: pageViewController data source methods
    
    func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        if let ayaView = viewController as? TafseerAyaView,
            let ayaIndex = ayaView.ayaPosition {
            if ayaIndex < lastAya {
                return createAyaView(ayaIndex+1)
            }
        }
        return nil
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        if let ayaView = viewController as? TafseerAyaView, let ayaIndex = ayaView.ayaPosition {
            if ayaIndex > firstAya {
                return createAyaView(ayaIndex-1)
            }
        }
        return nil
    }

    // MARK: UIPickerView data source methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component{
        case 0:
            return TafseerSources.count
        case 1:
            return 114
        default:
            let qData = QData.instance
            let (suraIndex, _) = qData.ayaLocation( ayaPosition )
            return qData.ayaCount(suraIndex: suraIndex)!
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component{
        case 0:
            return NSLocalizedString(TafseerSources[row], comment: "")
        case 1:
            return QData.instance.suraName(suraIndex: row)?.name
        default:
            return "\(row+1)"
        }
    }
    
    // MARK: pickerView delegate methods
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component{
        case 0:// tafseer
            TafseerViewController.selectedTafseer = row
            gotoAya( ayaPosition )
        case 1://sura
            updateAyaPosition( sura: row )
        default://aya
            updateAyaPosition( aya: row )
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
