/**
 * Copyright 2016 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
    @IBOutlet weak var activiityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var topView: UIView!
    
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
        locationManager.distanceFilter = 300
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
        print ("Error while updating location")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        logLocation ()
        fetchCards()
    }
    
    func logLocation () {
        let currentLocation = locationManager.location!
        print ("longitude - \(currentLocation.coordinate.longitude), latitude - \(currentLocation.coordinate.latitude)")
    }
    
    func fetchCards () {
        self.resetView()
        
        let currentLocation = locationManager.location!
        LiveUpdateManager.sharedInstance.obtainConfiguration(["longitude" : "\(currentLocation.coordinate.longitude)", "latitude" : "\(currentLocation.coordinate.latitude)"]) { (configuration, error) in
            let adapterURL = configuration?.getProperty("dealsAdapterURL")
         
            if let colorProp = configuration?.getProperty("bgColor"), viewBGColor = self.colorWithHexString (colorProp) {
                self.view.backgroundColor = viewBGColor
                self.topView.backgroundColor = viewBGColor
                self.kolodaView.backgroundColor = viewBGColor
            }
            
            let resourseRequest = WLResourceRequest(URL: NSURL(string:adapterURL!)!, method:"GET")
            resourseRequest.sendWithCompletionHandler({ (response, error) -> Void in
                if let json = response.responseJSON where error == nil{
                    self.dealsArray = json["deals"] as! NSArray
                    if self.kolodaView.dataSource == nil {
                        self.kolodaView.dataSource = self
                    }
                    self.kolodaView.resetCurrentCardIndex()
                    print (self.dealsArray)
                    self.kolodaView.hidden = false
                }
                self.activiityIndicator.hidden = true
                self.activiityIndicator.stopAnimating()
            })
        }
    }
    
    private func resetView () {
        self.kolodaView.resetCurrentCardIndex()
        activiityIndicator.hidden = false
        activiityIndicator.startAnimating()
        kolodaView.hidden = true
        self.titleLabel.text = ""
        self.descriptionLabel.text = ""
    }
    
    private func colorWithHexString (hex:String) -> UIColor? {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substringFromIndex(1)
        }
        
        if (cString.characters.count != 6) {
            return UIColor.grayColor()
        }
        
        let rString = (cString as NSString).substringToIndex(2)
        let gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
        let bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
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
