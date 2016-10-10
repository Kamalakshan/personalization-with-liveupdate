//
//  BackgroundAnimationViewController.swift
//  Koloda
//
//  Created by Eugene Andreyev on 7/11/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import UIKit
import Koloda
import pop
import IBMMobileFirstPlatformFoundationLiveUpdate
import IBMMobileFirstPlatformFoundation
import CoreLocation

private let numberOfCards: UInt = 5
private let frameAnimationSpringBounciness: CGFloat = 9
private let frameAnimationSpringSpeed: CGFloat = 16
private let kolodaCountOfVisibleCards = 2
private let kolodaAlphaValueSemiTransparent: CGFloat = 0.1

class CardsViewController: UIViewController, CLLocationManagerDelegate{

    weak var kolodaView: CustomKolodaView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    var dealsArray = NSArray()
    var cachedImages = NSMutableDictionary()
    
     private var locationManager = CLLocationManager()
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        kolodaView.alphaValueSemiTransparent = kolodaAlphaValueSemiTransparent
        kolodaView.countOfVisibleCards = kolodaCountOfVisibleCards
        kolodaView.delegate = self
        kolodaView.animator = CardsAnimator(koloda: kolodaView)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        self.modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
    }
    
    
    //MARK: IBActions
    @IBAction func leftButtonTapped() {
        kolodaView?.swipe(SwipeResultDirection.Left)
    }
    
    @IBAction func rightButtonTapped() {
        kolodaView?.swipe(SwipeResultDirection.Right)
    }
    
    @IBAction func refreshButtonTapped() {
        fetchCards()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print ("Error updating location")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func fetchCards () {
        let currentLocation = locationManager.location!
        
        print ("longitude - \(currentLocation.coordinate.longitude), latitude - \(currentLocation.coordinate.latitude)")
        LiveUpdateManager.sharedInstance.obtainConfiguration(["longitude" : "\(currentLocation.coordinate.longitude)", "latitude" : "\(currentLocation.coordinate.latitude)"]) { (configuration, error) in
            let adapterURL = configuration?.getProperty("dealsAdapterURL");
            let resourseRequest = WLResourceRequest(URL: NSURL(string:adapterURL!)!, method:"GET")
            resourseRequest.sendWithCompletionHandler({ (response, error) -> Void in
                if let json = response.responseJSON {
                    
                    self.dealsArray = response.responseJSON["deals"] as! NSArray
                    if self.kolodaView.dataSource == nil {
                        self.kolodaView.dataSource = self
                    }
                    self.kolodaView.resetCurrentCardIndex()
                    print (self.dealsArray)
                }
            })
        }
    }
}

//MARK: KolodaViewDelegate
extension CardsViewController: KolodaViewDelegate {
    
    func kolodaDidRunOutOfCards(koloda: KolodaView) {
        kolodaView.resetCurrentCardIndex()
    }
    
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {
       // UIApplication.sharedApplication().openURL(NSURL(string: "http://yalantis.com/")!)
    }
    
    func kolodaShouldApplyAppearAnimation(koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaShouldMoveBackgroundCard(koloda: KolodaView) -> Bool {
        return false
    }
    
    func kolodaShouldTransparentizeNextCard(koloda: KolodaView) -> Bool {
        self.titleLabel.text = self.dealsArray[koloda.currentCardIndex]["title"] as? String
        self.descriptionLabel.text = self.dealsArray[koloda.currentCardIndex]["description"] as? String
        return true
    }
    
    func koloda(kolodaBackgroundCardAnimation koloda: KolodaView) -> POPPropertyAnimation? {
        let animation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        animation.springBounciness = frameAnimationSpringBounciness
        animation.springSpeed = frameAnimationSpringSpeed
        return animation
    }
}

//MARK: KolodaViewDataSource
extension CardsViewController: KolodaViewDataSource {
    
    func kolodaNumberOfCards(koloda: KolodaView) -> UInt {
        return UInt(dealsArray.count);
    }
    
    func koloda(koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView {
        let index = Int(index)
        
        
        let urlString = dealsArray[index]["imageUrl"]! as! String
        var data = cachedImages.valueForKey(urlString)
        if data == nil {
            let url = NSURL(string: urlString)
            data = NSData(contentsOfURL: url!)
            cachedImages.setValue(data, forKey: urlString)
        }
        let uiImage = UIImage(data: data as! NSData)!
        return UIImageView(image: uiImage)
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        return NSBundle.mainBundle().loadNibNamed("CustomOverlayView",
            owner: self, options: nil)![0] as? OverlayView
    }
}
