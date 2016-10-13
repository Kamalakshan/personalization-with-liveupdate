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

import Foundation
import Koloda
import pop

class CardsAnimator: KolodaViewAnimator {
    
    override func applyScaleAnimation(card: DraggableCardView, scale: CGSize, frame: CGRect, duration: NSTimeInterval, completion: AnimationCompletionBlock) {
        
        let scaleAnimation = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation.springBounciness = 9
        scaleAnimation.springSpeed = 16
        scaleAnimation.toValue = NSValue(CGSize: scale)
        card.layer.pop_addAnimation(scaleAnimation, forKey: "scaleAnimation")
        
        let frameAnimation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        frameAnimation.springBounciness = 9
        frameAnimation.springSpeed = 16
        frameAnimation.toValue = NSValue(CGRect: frame)
        if let completion = completion {
            frameAnimation.completionBlock = { _, finished in
                completion(finished)
            }
        }
        card.pop_addAnimation(frameAnimation, forKey: "frameAnimation")
    }
    
}
