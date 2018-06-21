//
//  HomeFeedController.swift
//  Eventful
//
//  Created by Shawn Miller on 7/28/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AlamofireNetworkActivityIndicator
import SwiftLocation
import CoreLocation
import FirebaseDatabase
import SVProgressHUD
import GooglePlaces

class ImageAndTitleItem: NSObject {
    public var name:String?
    public var imageName:String?
    
    convenience init(name:String, imageName:String) {
        self.init()
        self.name = name
        self.imageName = imageName
    }
}

class HomeFeedController: UICollectionViewController {
    
    let dispatchGroup = DispatchGroup()
    var savedLocation: CLLocation?
    var userLocation: CLLocation?
    var allEvents = [Event]()
    var featuredEvents = [Event]()
    var allEvents2 = [String:[Event]]()
    var seizeTheNight = [Event]()
    var seizeTheDay = [Event]()
    var twentyOne = [Event]()
    var friendsEvents = [Event]()
    var placesClient = GMSPlacesClient()
    let dateFormatter = DateFormatter()
    var lastSelectedDate: Date?
    private let cellID = "cellID"
    private let catergoryCellID = "catergoryCellID"
    var featuredEventsHeaderString = "Featured Events"
    var categories : [String] = ["Seize The Night","Seize The Day","21 & Up"]
    lazy var sideMenuLauncher: SideMenuLauncher = {
       let launcher = SideMenuLauncher()
        launcher.homeFeedController = self
        return launcher
    }()
    let titleView = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
         self.navigationController?.navigationBar.backgroundColor = UIColor.white
        collectionView?.backgroundColor = .white
        collectionView?.showsVerticalScrollIndicator = false
        SVProgressHUD.dismiss(withDelay: 0.5)
        grabUserLoc()
        setupBarButtonItems()
        collectionView?.register(HomeFeedCell.self, forCellWithReuseIdentifier: cellID)
                collectionView?.register(CategoryCell.self, forCellWithReuseIdentifier: catergoryCellID)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("EventDetailViewController class removed from memory")
    }
    
    @objc func setupBarButtonItems(){
    let sideMenuButton = UIBarButtonItem(image: UIImage(named: "icons8-Menu-48"), style: .plain, target: self, action: #selector(presentSideMenu))
    navigationItem.leftBarButtonItem = sideMenuButton
        let calendarMenuButton = UIBarButtonItem(image: UIImage(named: "icons8-calendar-48"), style: .plain, target: self, action: #selector(presentCalendar))
        navigationItem.rightBarButtonItem = calendarMenuButton
    }
    
    @objc func presentCalendar(){
        print("calendar tapped")
        let calendar = CalendarViewController()
        if let lastDate = lastSelectedDate {
            calendar.passedDate = lastDate
        }
        calendar.homeFeedController = self
        LocationService.getUserLocation { (location) in
            calendar.savedLocation1 = location
            self.navigationController?.pushViewController(calendar, animated: false)
        }
    }
    
    @objc func presentSideMenu(){
        sideMenuLauncher.presentSideMenu()
    }
    
    @objc func showControllerForCategory(sideMenu: SideMenu){
        let categoryVC = CategoryViewController(collectionViewLayout: UICollectionViewFlowLayout())
        categoryVC.titleView.text = sideMenu.name.rawValue
        if sideMenu.name.rawValue == "Friends Events" {
            categoryVC.events = self.friendsEvents
            categoryVC.emptyLabel.text = "Sorry, Your Friends Don't Seem to Be Attending Any Events"
        }else{
            categoryVC.events = self.allEvents2[sideMenu.name.rawValue]!
            categoryVC.emptyLabel.text = "Sorry We Currently Have No Events, \n In This Category Near You"
        }
        navigationController?.pushViewController(categoryVC, animated: true)
    }
    
    @objc func updateCVWithLocation(placeID: String){
        placesClient.lookUpPlaceID(placeID) { (place, error) in
            if error != nil {
                print("lookup place id query error: \(error!.localizedDescription)")
                return
            }
            if let p = place {
                let currentLocation = CLLocation(latitude: p.coordinate.latitude, longitude: p.coordinate.longitude)
                self.userLocation = currentLocation
                ///regular events
                self.allEvents2["Seize The Night"]?.removeAll()
                self.allEvents2["Seize The Day"]?.removeAll()
                self.allEvents2["21 & Up"]?.removeAll()
                self.seizeTheNight.removeAll()
                self.seizeTheDay.removeAll()
                self.twentyOne.removeAll()
                self.featuredEvents.removeAll()

                
                PostService.showFeaturedEvent(for: currentLocation, completion: { [weak self] (event) in
                    self?.featuredEvents = event
                })
                PostService.showEvent(for: currentLocation, completion: { [unowned self](events) in
                    
                    for event in events {
                        if event.category == "Seize The Night" {
                            self.seizeTheNight.append(event)
                        }
                        if event.category == "Seize The Day"{
                            self.seizeTheDay.append(event)
                        }
                        if event.category == "21 & Up"{
                            self.twentyOne.append(event)
                        }
                    }
                    self.allEvents2["Seize The Night"] = self.seizeTheNight
                    self.allEvents2["Seize The Day"] = self.seizeTheDay
                    self.allEvents2[ "21 & Up"] = self.twentyOne
                    print("ending in cacegory events")
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                        print(self.featuredEvents.count)
                        SVProgressHUD.dismiss(withDelay: 0.5)
                    }
                    
                })
                
            }else {
                print("No place details for \(placeID)")
            }

        }
    }
    
    @objc func grabUserLoc(){
        LocationService.getUserLocation { (location) in
            guard let currentLocation = location else {
                return
            }
            self.savedLocation = currentLocation
            
            PostService.showEvent(for: currentLocation, completion: { [unowned self](events) in
                
                for event in events {
                    if event.category == "Seize The Night" {
                        self.seizeTheNight.append(event)
                    }
                    if event.category == "Seize The Day"{
                        self.seizeTheDay.append(event)
                    }
                    if event.category == "21 & Up"{
                        self.twentyOne.append(event)
                    }
                }
                self.allEvents2["Seize The Night"] = self.seizeTheNight
                self.allEvents2["Seize The Day"] = self.seizeTheDay
                self.allEvents2[ "21 & Up"] = self.twentyOne
                print("ending in cacegory events")
            })
            
            PostService.showFeaturedEvent(for: currentLocation, completion: { [weak self] (events) in
                self?.featuredEvents = events
                print("ending in Featured events")
                self?.grabFriendsEvents()

            }
            )
            print("Latitude: \(currentLocation.coordinate.latitude)")
            print("Longitude: \(currentLocation.coordinate.longitude)")
        }
    }
    
    @objc func grabFriendsEvents(){
        print("Attempting to see where your friends are going")
        UserService.following { (user) in
            let dispatchGroup = DispatchGroup()
            for following in user {
                print(following.username as Any)
                print("entering dispatch group")
                dispatchGroup.enter()

                PostService.showFollowingEvent(for: following.uid, completion: { (event) in
                    self.friendsEvents = event
                   // self.friendsEvents.append(contentsOf: event)
                    // leave here
                    self.friendsEvents = self.friendsEvents.removeDuplicates()
                    print("ending in friends events")
                    dispatchGroup.leave()
                    print("leaving dispatch group")
                })
                
            }  
            
            dispatchGroup.notify(queue: .main) {
                // dismiss the revealing view
                self.collectionView?.reloadData()
                 NotificationCenter.default.post(name: heartAttackNotificationName, object: nil)
            }
            
        }
    }
    
    @objc func getSelectedDateFromCal(from selectedDate: Date){
        lastSelectedDate = selectedDate
        print(selectedDate.description)
        dateFormatter.dateFormat = "MM/dd/yyyy"
        SVProgressHUD.show(withStatus: "Grabbing Events")
        self.allEvents2["Seize The Night"]?.removeAll()
        self.allEvents2["Seize The Day"]?.removeAll()
        self.allEvents2["21 & Up"]?.removeAll()
        self.seizeTheNight.removeAll()
        self.seizeTheDay.removeAll()
        self.twentyOne.removeAll()
        self.featuredEvents.removeAll()
        
        if let location = self.userLocation {
            fetchEvents(currentLocation: location, selectedDate: selectedDate)
        }else{
            fetchEvents(currentLocation: savedLocation!, selectedDate: selectedDate)
        }
        
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        
        if parent != nil && self.navigationItem.titleView == nil {
            initNavigationItemTitleView()
        }
    }
    private func initNavigationItemTitleView() {
        LocationService.getUserLocation { (currentLocation) in
            guard let savedLocation = currentLocation else {
                return
            }
            CLGeocoder().reverseGeocodeLocation(savedLocation, completionHandler: {(placemarks, error) -> Void in
                print(savedLocation)
                if error != nil {
                    print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                    return
                }
                if placemarks!.count > 0 {
                    let pm = placemarks![0]
                    self.titleView.text = "\(pm.locality ?? ""), \(pm.administrativeArea ?? "") ▼"
                    self.titleView.font = UIFont(name: "Avenir", size: 18)
                    self.titleView.adjustsFontSizeToFitWidth = true
                    let width = self.titleView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
                    self.titleView.frame = CGRect(origin:CGPoint.zero, size:CGSize(width: width, height: 500))
                    self.navigationItem.titleView = self.titleView
                    let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.titleWasTapped))
                    self.titleView.isUserInteractionEnabled = true
                    self.titleView.addGestureRecognizer(recognizer)
                }
                else {
                    print("Problem with the data received from geocoder")
                }
            })
        }
    }
    @objc private func titleWasTapped() {
        print("Hello, titleWasTapped!")
        let searchController = PlacesSearchController()
        searchController.homeFeedController = self
        self.navigationController?.pushViewController(searchController, animated: true)
    }


}

//DATASOURCE
extension HomeFeedController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1{
            return categories.count
        }
        return 1
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! HomeFeedCell
            cell.homeFeedController = self
            cell.sectionNameLabel.text = "Featured Events"
            cell.featuredEvents = featuredEvents
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: catergoryCellID, for: indexPath) as! CategoryCell
        cell.sectionNameLabel.text = categories[indexPath.item]
        cell.homeFeedController = self
        if allEvents2[categories[indexPath.item]]?.count != nil {
            //print(allEvents2[categories[indexPath.item]])
            cell.categoryEvents = allEvents2[categories[indexPath.item]]
        } else{
            cell.categoryEvents = allEvents
        }
        return cell
    }

}
//Delegate flow layout
extension HomeFeedController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return CGSize(width: view.frame.width, height: 450)
        }
        return CGSize(width: view.frame.width, height: 300)
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 5, left: 5, bottom: 10, right: 5)
        }
        return UIEdgeInsets(top: 10, left: 8, bottom: 0, right: 8)
    }
}


extension HomeFeedController {
    @objc func fetchEvents(currentLocation: CLLocation, selectedDate: Date){
        
        PostService.showEvent(passedDate: selectedDate,for: currentLocation, completion: { [unowned self](events) in
            for event in events {
                if event.category == "Seize The Night" {
                    self.seizeTheNight.append(event)
                }
                if event.category == "Seize The Day"{
                    self.seizeTheDay.append(event)
                }
                if event.category == "21 & Up"{
                    self.twentyOne.append(event)
                }
            }
            self.allEvents2["Seize The Night"] = self.seizeTheNight
            self.allEvents2["Seize The Day"] = self.seizeTheDay
            self.allEvents2[ "21 & Up"] = self.twentyOne
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        })
        
        PostService.showFeaturedEvent(passedDate: selectedDate,for: currentLocation, completion: { [weak self] (events) in
            self?.featuredEvents = events

            DispatchQueue.main.async {
                self?.collectionView?.reloadData()
                SVProgressHUD.dismiss(withDelay: 1)
            }
            }
        )
    }
}


