//
//  TafseerViewController.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 9/29/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

let TafseerSources = [
    "ar.muyassar",
    "ar.jalalayn",
    "ur.maududi",
    "fa.ansarian",
    "ta.tamil",
    "hi.farooq",
    "de.aburida",
    "en.yusufali",
    "es.bornez",
    "fr.hamidullah",
    "id.indonesian",
    "tr.golpinarli",
    "ms.basmeih"
]

class TafseerViewController: UIViewController,
    UIPageViewControllerDelegate,
    UIPageViewControllerDataSource,
    UIPickerViewDelegate,
    UIPickerViewDataSource
{
    private var _selectedTafseer:String?
    
    @IBOutlet weak var bookmarkButton: UIBarButtonItem!
    
    @IBOutlet weak var PageViewFrame: UIView!
    @IBOutlet weak var tafseerSourceSelector: UIPickerView!

    var firstAya = 0
    var lastAya = 6236
    var pageViewController:UIPageViewController?
    var ayaPosition:Int?
    var isBookmarked = false
    
    var currAya:Int{
        return ayaPosition ?? SelectStart
    }

    // MARK: UIViewController delegate methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Read from defaults
        _selectedTafseer = UserDefaults.standard.object(forKey: "sel_tafseer") as? String ?? TafseerSources[2]
        
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
        gotoAya(ayaPosition ?? SelectStart)

        NotificationCenter.default.addObserver(self, selector: #selector(updateTitle), name: AppNotifications.dataUpdated, object: nil)

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func selectedTafseer()->(name:String,index:Int){
        let taf = _selectedTafseer ?? TafseerSources[0]
        if let index = TafseerSources.index(of: taf){
            return (name:taf, index:index)
        }
        return (name:TafseerSources[0], index:0)//fail safe
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
           direction: (self.currAya >= ayaPosition) ? .reverse : .forward,
            //direction: .forward
           animated: true,
           completion: nil)
        
        self.ayaPosition = ayaPosition
        
        updatePicker()
        updateTitle()
    }
    
    @objc func updateTitle(){
        let qData = QData.instance
        let (sura,aya) = qData.ayaLocation(currAya)
        if let suraName = qData.suraName(suraIndex: sura){
            self.title = "\(suraName.name) (\(aya+1))"
        }
        
        QData.isBookmarked(currAya){ is_yes in
            self.isBookmarked = is_yes
            self.bookmarkButton.image = UIImage(named: is_yes ? "Bookmark Filled" : "Bookmark Empty")
        }
    }
    
    
    func createAyaView(_ ayaIndex: Int)->UIViewController{
        let viewController = storyboard!.instantiateViewController(withIdentifier: "TafseerAyaView")
        if let tafseerAyaView = viewController as? TafseerAyaView{
            tafseerAyaView.ayaPosition = ayaIndex
            tafseerAyaView.selectedTafseer = selectedTafseer().name
        }
        return viewController
    }

    func updatePicker(){
        tafseerSourceSelector.selectRow(selectedTafseer().index, inComponent: 0, animated: true)
        let qData = QData.instance
        if let tafseerView = pageViewController!.viewControllers![0] as? TafseerAyaView{
            let (cSuraIndex, _) = qData.ayaLocation( currAya )
            ayaPosition = tafseerView.ayaPosition!
            let (suraIndex,ayaIndex) = qData.ayaLocation( currAya )
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
    
    @IBAction func clickBookmark(_ sender: UIBarButtonItem) {
        if isBookmarked{
            let _ = QData.deleteBookmark(aya: currAya){ snapshot in self.updateTitle()
            }
        }else{
            QData.bookmark(self, self.currAya)//will show a notification
        }
    }
    
    func updateAyaPosition( aya:Int ){
        let qData = QData.instance
        let (sIndex,_) = qData.ayaLocation(self.currAya) //read current sura
        let ayaPosition = qData.ayaPosition(sura: sIndex, aya: aya)//create new position
        gotoAya(ayaPosition)//update current position
    }

    // MARK: Action handlers
    
    @IBAction func clickNext(_ sender: Any) {
        if currAya+1 < lastAya {
            gotoAya( currAya + 1 )
        }
    }
    @IBAction func clickPrevious(_ sender: Any) {
        if currAya > 0 {
            gotoAya( currAya - 1 )
        }
    }

    @IBAction func clickSelect(_ sender: Any) {
        navigationController?.removeQPageBrowser()//only allow one page browser instance
        SelectStart = currAya
        SelectEnd = SelectStart
        self.performSegue(withIdentifier: "ShowPage", sender: self)
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
        updateTitle()
        
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
            let (suraIndex, _) = qData.ayaLocation( currAya )
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
            //user selects different tafseer
            //update the cached value and the UserDefaults
            _selectedTafseer = TafseerSources[row]
            UserDefaults.standard.set(_selectedTafseer, forKey: "sel_tafseer")
            gotoAya( currAya )
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
