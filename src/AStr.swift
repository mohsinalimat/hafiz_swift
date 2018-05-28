//
//  Locale.swift
//  Quran Hafiz
//
//  Created by Ramy Eldesoky on 5/17/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//

import Foundation

class AStr {
    static func suraSdescS(s:String,d:String)->String{
        return String(format:"%@ (%@)",s,d)
    }

    static var tafseer:String {
        return NSLocalizedString("Tafseer", comment: "")
    }
    static var revise:String {
        return NSLocalizedString("Revise", comment: "")
    }
    static func suraName(s:String)->String{
        return String(format:NSLocalizedString("SuraName", comment: ""),s)
    }
    static func partN(n:Int)->String{
        return String(format:NSLocalizedString("Part", comment: ""),n)
    }
    static var remove:String {
        return NSLocalizedString("Remove", comment: "")
    }
    static var addHifz:String {
        return NSLocalizedString("addHifz", comment: "")
    }

    static var updateHifz:String {
        return NSLocalizedString("updateHifz", comment: "")
    }

    static var addUpdateHifz:String {
        return NSLocalizedString("addUpdateHifz", comment: "")
    }

    static var bookmark:String {
        return NSLocalizedString("Bookmark", comment: "")
    }

    static var signOut:String{
        return NSLocalizedString("signOut", comment: "")
    }
    static var signIn:String{
        return NSLocalizedString("signIn", comment: "")
    }
    static var changeLanguage:String{
        return NSLocalizedString("changeLanguage", comment: "")
    }
    static var shareQuranHafiz:String{
        return NSLocalizedString("shareQuranHafiz", comment: "")
    }
    static var rateQuranHafiz:String{
        return NSLocalizedString("rateQuranHafiz", comment: "")
    }

    ///////// Not in localizable
    static var cancel:String{
        return NSLocalizedString("Cancel", comment: "")
    }
    static var selectLanguage:String{
        return NSLocalizedString("selectLanguage", comment: "")
    }
    static var loading:String{
        return NSLocalizedString("Loading", comment: "")
    }
    static var read:String{
        return NSLocalizedString("Read", comment: "")
    }
    static var update:String{
        return NSLocalizedString("Update", comment: "")
    }
    static var firstPage:String{
        return NSLocalizedString("firstPage", comment: "")
    }
    static var lastPage:String{
        return NSLocalizedString("lastPage", comment: "")
    }
    static func allPagesN(n:Int)->String{
        return String(format:NSLocalizedString("allPagesN", comment: ""),n)
    }
    static func nOfyPages(n:Int,y:Int)->String{
        return String(format:NSLocalizedString("nOfyPages", comment: ""),n,y)
    }
    static func lastNpages(n:Int)->String{
        return String(format:NSLocalizedString("lastNpages", comment: ""),n)
    }
    static func thePageN(n:Int)->String{
        return String(format:NSLocalizedString("thePageN", comment: ""),n)
    }
    static func nPagesFromY(n:Int,y:Int)->String{
        return String(format:NSLocalizedString("nPagesFromY", comment: ""),y,n)
    }
    static func nDaysAgo(n:Int)->String{
        return String(format:NSLocalizedString("nDaysAgo", comment: ""),n)
    }
    static var today:String{
        return NSLocalizedString("Today", comment: "")
    }
    static var yesterday:String{
        return NSLocalizedString("Yesterday", comment: "")
    }
    static var lastViewed:String{
        return NSLocalizedString("lastViewed", comment: "Last Viewed Locations")
    }
    static var readingStop:String{
        return NSLocalizedString("readingStop", comment: "Reading stop")
    }
    static var setReadingStop:String{
        return NSLocalizedString("setReadingStop", comment: "Set reading stop")
    }
    static var bookmarks:String{
        return NSLocalizedString("Bookmarks", comment: "")
    }
    static var share:String{
        return NSLocalizedString("Share", comment: "")
    }
    static var revisedToday:String{
        return NSLocalizedString("revisedToday", comment: "")
    }
    static var removeFromHifz:String{
        return NSLocalizedString("removeFromHifz", comment: "")
    }
    static func removeSfromHifz(s:String)->String{
        return String(format: NSLocalizedString("removeSFromHifz", comment: "Remove %@ from your hifz"),s)
    }
    static func addStoYourHifz(s:String)->String{
        return String(format: NSLocalizedString("addStoYourHifz", comment: ""), s)
    }
    static var areYouSure:String{
        return NSLocalizedString("areYouSure", comment: "")
    }
    static var yes:String{
        return NSLocalizedString("Yes", comment: "")
    }
    static var no:String{
        return NSLocalizedString("No", comment: "")
    }
    static var mergeExistingHifz:String{
        return NSLocalizedString("mergeExistingHifz", comment: "")
    }
    static var mergeExistingHifzDesc:String{
        return NSLocalizedString("mergeExistingHifzDesc", comment: "")
    }
    static var revisionSaved:String{
        return NSLocalizedString("revisionSaved", comment: "")
    }
    static var goodJob:String{
        return NSLocalizedString("goodJob", comment: "")
    }
    static var ok:String{
        return NSLocalizedString("ok", comment: "")
    }
    static var wholeSura:String{
        return NSLocalizedString("wholeSura", comment: "Whole Sura")
    }
    static var fromSuraStart:String{
        return NSLocalizedString("fromSuraStart", comment: "From Sura Start")
    }
    static var toSuraEnd:String{
        return NSLocalizedString("toSuraEnd", comment: "To Sura End")
    }
    static var currentPage:String{
        return NSLocalizedString("currentPage", comment: "")
    }
    static var back:String{
        return NSLocalizedString("Back", comment: "")
    }
    static var textSuraPage:String{
        return NSLocalizedString("textSuraPage", comment: "text,sura or page")
    }
    static var search:String{
        return NSLocalizedString("Search", comment: "")
    }
    static func nResultsForS(ns:String,s:String)->String{
        return String(format:NSLocalizedString("nResultsForS", comment: "%@ results for %@"),ns,s)
    }
    static func miniPartNPageN(part:Int,page:Int)->String{
        return String(format: NSLocalizedString("miniPartNPageN", comment: "%d:p%d"), part, page)
    }
    static func partNPageN(part:Int,page:Int)->String{
        return String(format: NSLocalizedString("partNPageN", comment: "Part %d - Page %d"), part, page)
    }
    static func signOutS(s:String)->String{
        return String(format:NSLocalizedString("signOutS", comment: "This will sign out %@"),s)
    }
    static var appRestartRequired:String{
        return NSLocalizedString("appRestartRequired", comment: "")
    }
    static var appRestartRequiredDesc:String{
        return NSLocalizedString("appRestartRequiredDesc", comment: "")
    }
    static var tryOutThisApp:String{
        return NSLocalizedString("tryOutThisApp", comment: "")
    }
    static var bookmarkAdded:String{
        return NSLocalizedString("bookmarkAdded", comment: "")
    }
    static var bookmarkAddedDesc:String{
        return NSLocalizedString("bookmarkAddedDesc", comment: "")
    }
    static var signInRequired:String{
        return NSLocalizedString("signInRequired", comment: "")
    }
    static var signInRequiredDesc:String{
        return NSLocalizedString("signInRequiredDesc", comment: "")
    }

    static var selectSura:String{
        return NSLocalizedString("selectSura", comment: "")
    }

    static func confirmSetReadingStop(from:Int, to:Int)->String{
        return String(format:NSLocalizedString("confirmSetReadingStop", comment: "Confirm changing your reading position from page  %d to page %d"), from, to)
    }

}
