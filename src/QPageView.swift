//
//  DataViewController.swift
//  test
//
//  Created by Ramy Eldesoky on 6/28/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class QPageView: UIViewController{

    @IBOutlet weak var pageImage: UIImageView!
    
    var pageNumber: Int? //will be set by the ModelController that creates this controller
    var pageMap: [[String:String]]?
    var hideMenuObserver: Any?
    var clickedAya : UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        loadPageImage()
        createAyaButtons()
        becomeFirstResponder()
    }
    
    func createAyaButtons(){
        if let uwPageNumber = pageNumber{
            pageMap = QData.pageMap( uwPageNumber-1 )
            let qData = QData.instance()
            if let uwPageMap = pageMap {
                for(var button) in uwPageMap{
                    let btn = UIView()
                    btn.semanticContentAttribute = .forceRightToLeft
                    btn.alpha = 0.3
//                    let ayaId = button["sura"]! + "_" + button["aya"]!
//                    btn.restorationIdentifier = "aya_\(ayaId)"
                    btn.backgroundColor = .brown
                    btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickAyaButton)))
                    btn.isUserInteractionEnabled = true
                    btn.tag = qData.ayaPosition(sura: Int(button["sura"]!)!-1, aya: Int(button["aya"]!)!-1)
                    self.pageImage.addSubview(btn)
                }
            }
        }
    }
    
    @objc func onClickAyaButton(tapGestureRecognizer: UITapGestureRecognizer){
        becomeFirstResponder()
        clickedAya = tapGestureRecognizer.view
        clickedAya!.backgroundColor = .blue
        let mnuController = UIMenuController.shared
        let menuRect = CGRect(x:0, y:0, width:clickedAya!.frame.size.width, height:clickedAya!.frame.size.height)
        mnuController.setTargetRect(menuRect, in: clickedAya!)
       
        mnuController.menuItems = [
            UIMenuItem(title: "Tafseer", action: #selector(ayaTafseer)),
            UIMenuItem(title: "Recite", action: #selector(ayaRecite))
        ]
        
        // This makes the menu item visible.
        mnuController.setMenuVisible(true, animated: true)
        
        var hideMenuObserver:Any?
        
        hideMenuObserver = NotificationCenter.default.addObserver(forName: .UIMenuControllerDidHideMenu, object: nil, queue: nil){_ in
            //print( "onHideMenu" )
            self.clickedAya!.backgroundColor = .brown
            NotificationCenter.default.removeObserver(hideMenuObserver!)
        }
    }
    
    func locateAyaButtons(){
        if let uwPageNumber = pageNumber{
            pageMap = QData.pageMap( uwPageNumber-1 )
            if let uwPageMap = pageMap {
                let imageRect = pageImage.frame
                let line_height = Float(imageRect.size.height / 15)
                let line_width = Float(imageRect.size.width)
                let button_width = Float(line_width/9.6)
                
                pageImage.removeConstraints(pageImage.constraints)//remove all constraints
                
                for(index, btn) in self.pageImage.subviews.enumerated(){
                    let button = uwPageMap[index]
                    let eline = Float(button["eline"]!)!
                    let epos = Float(button["epos"]!)!
                    let xpos = Int( epos * line_width / 1000 - button_width )
                    let ypos = Int( eline * Float(imageRect.size.height) / 15 )
                    
                    self.pageImage.addSimpleConstraints("H:|-\(xpos)-[v0(\(Int(button_width)))]", views: btn)
                    self.pageImage.addSimpleConstraints("V:|-\(ypos)-[v0(\(Int(line_height)))]", views: btn)
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        locateAyaButtons()
    }
    
    func loadPageImage(){
        
        if let uwPageNumber = pageNumber {
            //self.pageNumberLabel!.text = String(uwPageNumber)
            
            let sPageNumber = String(format: "%03d", uwPageNumber)
            
            let imageUrl = URL(string:"http://www.egylist.com/qpages_1260/page\(sPageNumber).png")!
            
            getDataFromUrl(url: imageUrl) { (data, response, error) in
                
                guard let data = data, error == nil else { return }
                
                //Apply the image data in the UI thread
                DispatchQueue.main.async() { () -> Void in
                    //Set the imageView source
                    self.pageImage.image = UIImage(data: data)
                }
            }
        }
    }

    @objc func ayaTafseer(){
        performSegue(withIdentifier: "ShowTafseer", sender: clickedAya)
    }

    @objc func ayaRecite(){
        print("Recite")
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if( action == #selector(ayaTafseer) || action == #selector(ayaRecite)){
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let ayaButton = sender as? UIView,
            let tafseerView = segue.destination as? TafseerViewController {
            
            tafseerView.ayaPosition = ayaButton.tag
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func tabQuranImage(_ sender: Any) {
        print("Tabbed Image")
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    func getDataFromUrl(
        url: URL,
        completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void
    )
    {
        
        let downloadTask = URLSession.shared.dataTask( with: url ){ (data, response, error) in
            completion(data, response, error)
        }
        
        downloadTask.resume()
    }
    
    

}
