//
//  RLStickyHeaderFlowLayout.swift
//  RLStickyHeaderFlowLayout
//
//  Created by Roy lee on 16/7/17.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

import Foundation
import UIKit


/// RepresentedElementKind key for the parallax header, if you want to have a header on the top, you must registe this kind key with your `UICollectionReusableView`
public let RLStickyHeaderParallaxHeader = "RLStickyHeaderParallaxHeader"
let kHeaderZIndex = 1024


public class RLStickyHeaderFlowLayout: UICollectionViewFlowLayout {
    var _parallaxHeaderReferenceSize: CGSize! = CGSizeZero
    /// Properties:
    ///
    /// - Below four properties is used to config the parallax header and section header
    /// - If you want to have a header(eg.parallax header) on the top, you must registe this kind key `RLStickyHeaderParallaxHeader` with your `UICollectionReusableView`
    ///
    /// Set the default size of parallaxHeader by this property
    public var parallaxHeaderReferenceSize: CGSize! {
        get {
            return self._parallaxHeaderReferenceSize
        }
        set {
            self._parallaxHeaderReferenceSize = newValue
            // Make sure to update the layout
            invalidateLayout()
        }
    }
    /// Mininum size of parallaxHeader
    public var parallaxHeaderMinimumReferenceSize:CGSize! = CGSizeZero
    /// Set the parallax header on top or move when scroll, default is false
    public var parallaxHeaderAlwaysOnTop:Bool! = false
    /// If you set this property true the section header will not sticky, default is false
    public var disableStickyHeaders:Bool! = false
}


extension RLStickyHeaderFlowLayout {
    
    // Override layout methods
    override public func prepareLayout() {
        super.prepareLayout()
    }
    
    override public func initialLayoutAttributesForAppearingSupplementaryElementOfKind(elementKind: String, atIndexPath elementIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.initialLayoutAttributesForAppearingSupplementaryElementOfKind(elementKind, atIndexPath: elementIndexPath)
        if elementKind == RLStickyHeaderParallaxHeader {
            // sticky header do not need to offset
            return nil
        } else {
            // offset others
            var frame = attributes?.frame
            frame?.origin.y += parallaxHeaderReferenceSize.height
            attributes?.frame = frame!
            
        }
        return attributes
    }
    
    override public func finalLayoutAttributesForDisappearingSupplementaryElementOfKind(elementKind: String, atIndexPath elementIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == RLStickyHeaderParallaxHeader {
            let attribute = layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: elementIndexPath) as? RLStickyHeaderFlowLayoutAttributes
            
            updateParallaxHeaderAttribute(attribute!)
            return attribute
        } else {
            return super.finalLayoutAttributesForDisappearingSupplementaryElementOfKind(elementKind, atIndexPath: elementIndexPath)
        }
    }
    
    override public func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        var attributes = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
        if (attributes == nil) && (elementKind == RLStickyHeaderParallaxHeader) {
            attributes = RLStickyHeaderFlowLayoutAttributes.init(forSupplementaryViewOfKind:elementKind, withIndexPath:indexPath)
        }
        return attributes
    }
    
    // Core function: Reutrn the attributes will be used, you can custom these attributes to fit.
    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if collectionView!.dataSource != nil {
            // The rect should compensate the header size
            var adjustedRect = rect
            adjustedRect.origin.y -= parallaxHeaderReferenceSize.height
            
            var allItems = [UICollectionViewLayoutAttributes]()
            let originalAttributes = super.layoutAttributesForElementsInRect(adjustedRect)
            //Perform a deep copy of the attributes returned from super
            for originalAttribute: UICollectionViewLayoutAttributes in originalAttributes! {
                allItems.append(originalAttribute.copy() as! UICollectionViewLayoutAttributes)
            }
            
            var headers = [Int:UICollectionViewLayoutAttributes]()
            var lastCells = [Int:UICollectionViewLayoutAttributes]()
            var visibleParallexHeader: Bool! = false
            
            for attributes in allItems {
                var frame = attributes.frame
                frame.origin.y += parallaxHeaderReferenceSize.height
                attributes.frame = frame
                
                let indexPath = attributes.indexPath
                let isHeader = attributes.representedElementKind == UICollectionElementKindSectionHeader
                let isFooter = attributes.representedElementKind == UICollectionElementKindSectionFooter
                
                if isHeader {
                    headers[indexPath.section] = attributes
                } else if isFooter {
                    // Not implemeneted
                } else {
                    let currentAttribute = lastCells[indexPath.section]
                    
                    // Get the bottom most cell of that section
                    if currentAttribute == nil || indexPath.row > currentAttribute!.indexPath.row {
                        lastCells[indexPath.section] = attributes
                    }
                    
                    if indexPath.item == 0 && indexPath.section == 0 {
                        visibleParallexHeader = true
                    }
                }
                
                if isHeader {
                    attributes.zIndex = kHeaderZIndex
                } else {
                    // For iOS 7.0, the cell zIndex should be above sticky section header
                    attributes.zIndex = 1
                }
            }
            
            
            // when the visible rect is at top of the screen, make sure we see
            // the parallex header
            if CGRectGetMinY(rect) <= 0 {
                visibleParallexHeader = true
            }
            
            if parallaxHeaderAlwaysOnTop == true {
                visibleParallexHeader = true
            }
            
            
            // This method may not be explicitly defined, default to 1
            // https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewDataSource_protocol/Reference/Reference.html#jumpTo_6
            // let numberOfSections = ((collectionView!.dataSource?.respondsToSelector(#selector(UICollectionViewDataSource.numberOfSectionsInCollectionView(_:)))) != nil) ?
            //    collectionView!.dataSource?.numberOfSectionsInCollectionView!(collectionView!):1
            
            
            
            // Create the attributes for the Parallex header
            if visibleParallexHeader && CGSizeEqualToSize(CGSizeZero, parallaxHeaderReferenceSize) == false {
                let currentAttribute = RLStickyHeaderFlowLayoutAttributes.init(forSupplementaryViewOfKind:RLStickyHeaderParallaxHeader, withIndexPath:NSIndexPath.init(index: 0))
                updateParallaxHeaderAttribute(currentAttribute)
                
                allItems.append(currentAttribute)
            }
            
            if disableStickyHeaders == false {
                for key in lastCells.keys {
                    let attributes = lastCells[key]
                    let indexPath = attributes!.indexPath
                    let indexPathKey = indexPath.section
                    
                    var header = headers[indexPathKey]
                    // CollectionView automatically removes headers not in bounds
                    if header == nil {
                        header = (layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath.init(forItem: 0, inSection: indexPath.section)))! as UICollectionViewLayoutAttributes
                        
                        if CGSizeEqualToSize(CGSizeZero, header!.frame.size) == false {
                            allItems.append(header!)
                        }
                    }
                    if CGSizeEqualToSize(CGSizeZero, header!.frame.size) == false {
                        updateHeaderAttributes(header!, lastCellAttributes:(lastCells[indexPathKey])!)
                    }
                }
                
            }
            
            // For debugging purpose
//            debugLayoutAttributes(allItems)
            
            return allItems
        } else {
            return nil
        }
    }
    
    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItemAtIndexPath(indexPath)!.copy() as? UICollectionViewLayoutAttributes
        var frame = attributes!.frame
        frame.origin.y += parallaxHeaderReferenceSize.height
        attributes!.frame = frame
        return attributes
    }
    
    override public func collectionViewContentSize() -> CGSize {
        // If not part of view hierarchy then return CGSizeZero (as in docs).
        // Call super.collectionViewContentSize can cause EXC_BAD_ACCESS when collectionView has no superview.
        if collectionView!.superview == nil {
            return CGSizeZero
        }
        var size = super.collectionViewContentSize()
        size.height += parallaxHeaderReferenceSize.height
        return size
    }
    
    override public func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override class public func layoutAttributesClass() -> AnyClass {
        return RLStickyHeaderFlowLayoutAttributes.self
    }
    
    // MARK: Private Helper
    private func updateHeaderAttributes(attributes: UICollectionViewLayoutAttributes, lastCellAttributes lastAttributes: UICollectionViewLayoutAttributes) {
        let currentBounds = collectionView!.bounds
        attributes.zIndex = kHeaderZIndex
        attributes.hidden = false
        
        var origin = attributes.frame.origin
        
        let sectionMaxY = CGRectGetMaxY(lastAttributes.frame) - attributes.frame.size.height
        var y = CGRectGetMaxY(currentBounds) - currentBounds.size.height + collectionView!.contentInset.top
        
        if parallaxHeaderAlwaysOnTop! {
            y += parallaxHeaderMinimumReferenceSize.height
        }
        
        let maxY = fmin(fmax(y, attributes.frame.origin.y), sectionMaxY)
        
        origin.y = maxY
        
        attributes.frame = CGRect(origin: origin, size: attributes.frame.size)
        
    }
    
    /**
     *  Update the parallax header, reuslt is: orgin.y of header attribute will be changed to keep the positon of header always same
     *  `parallaxHeaderMinimumReferenceSize` determines the mininum size of the header, the height of the header will change when scrolling, and you parallax header is created through this characteristic.
     */
    private func updateParallaxHeaderAttribute(currentAttribute: RLStickyHeaderFlowLayoutAttributes) {
        var frame = currentAttribute.frame
        frame.size.width = parallaxHeaderReferenceSize.width
        frame.size.height = parallaxHeaderReferenceSize.height
        
        let bounds = collectionView!.bounds
        let maxY = CGRectGetMaxY(frame)
        
        // make sure the frame won't be negative values
        var y = fmin(maxY - parallaxHeaderMinimumReferenceSize.height, bounds.origin.y + collectionView!.contentInset.top)
        let height = fmax(0, -y + maxY)
        
        
        let maxHeight = parallaxHeaderReferenceSize.height
        let minHeight = parallaxHeaderMinimumReferenceSize.height
        let progressiveness = (height - minHeight)/(maxHeight - minHeight)
        currentAttribute.progressiveness = progressiveness
        
        
        // if zIndex < 0 would prevents tap from recognized right under navigation bar
        currentAttribute.zIndex = 0
        
        // When parallaxHeaderAlwaysOnTop is enabled, we will check when we should update the y position
        if parallaxHeaderAlwaysOnTop && height <= parallaxHeaderMinimumReferenceSize.height {
            let insetTop = collectionView!.contentInset.top
            // Always stick to top but under the nav bar
            y = collectionView!.contentOffset.y + insetTop
            currentAttribute.zIndex = 2000
        }
        
        currentAttribute.frame = CGRectMake(frame.origin.x, y, frame.size.width, height)
    }
    
    // MARK: Debuging
    private func debugLayoutAttributes(layoutAttributes: [UICollectionViewLayoutAttributes]) {
        var hasInvalid: Bool = false
        for attr in layoutAttributes {
            hasInvalid = !attr.isValid()
            if (hasInvalid) {
                break
            }
        }
        
        if (hasInvalid) {
            print("[Invalid] RLStickyHeaderFlowLayout: \(layoutAttributes)")
        }
    }

}


// MARK: Debuging
extension UICollectionViewLayoutAttributes {
    
    override public var description:String {

        let indexPath = valueForKey("indexPath")
        let zIndex = valueForKey("zIndex")
        let representedElementKind = valueForKey("representedElementKind")
        let frame = valueForKey("frame")
        
        
        return "RLStickyHeaderFlowLayout indexPath: \(indexPath) zIndex: \(zIndex) valid: \(isValid()) kind: \(representedElementKind) frame:\(frame)"
    }
    
    func isValid() -> Bool {
        switch (representedElementCategory) {
        case .Cell:
            if zIndex != 1 {
                return false
            }
            return true
        case .SupplementaryView:
            if representedElementKind == RLStickyHeaderParallaxHeader {
                return true
            } else if zIndex < 1024 {
                return false
            }
            return true
        default:
            return true
        }
    }
}




