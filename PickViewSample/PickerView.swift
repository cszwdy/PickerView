//
//  PickerView.swift
//  PickViewSample
//
//  Created by Emiaostein on 6/3/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

// TODO: base horizontal pickerView expend to horizontal & vertical pickerView -- EMIAOSTEIN, 3/06/16, 23:37
private let pickerViewCompnentCellIdentifier = "PickerViewComponentCell"
private let PickerViewRowCellIdentifier = "PickerViewRowCell"
final class PickerView: UIView {
    
    weak var dataSource: PickerViewDataSource?
    weak var delegate: PickerViewDelegate?
    var didSelectedHandler: ((component: Int, row: Int) -> ())?
    private var scrollDirection: UICollectionViewScrollDirection = .Horizontal
    private var collectionView: UICollectionView!
    private var componentIndexCache = PickerViewIndexCache()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let layout = PickerViewLayout()
        layout.scrollDirection = .Horizontal
        let c = UICollectionView(frame: bounds, collectionViewLayout: layout)
        c.decelerationRate = UIScrollViewDecelerationRateFast
        c.showsVerticalScrollIndicator = false
        c.showsHorizontalScrollIndicator = false
        c.backgroundColor = UIColor.clearColor()
        c.autoresizingMask = [
            .FlexibleLeftMargin,
            .FlexibleRightMargin,
            .FlexibleTopMargin,
            .FlexibleBottomMargin]
        c.registerClass(PickerViewComponentCell.self, forCellWithReuseIdentifier: pickerViewCompnentCellIdentifier)
        c.delegate = self
        c.dataSource = self
        addSubview(c)
        collectionView = c
    }
}

// MARK: - Public Methods
extension PickerView {
    // began from component & index
    func beganFrom(component comp: Int, row: Int) {
        componentIndexCache.changeAt(component: comp, row: row)
        if let attribute = collectionView.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: comp, inSection: 0)) {
            let center = attribute.center
            collectionView.setContentOffset(CGPoint(x: center.x - collectionView.bounds.width / 2, y: 0), animated: false)
        }
    }
}

// MARK: - CollectionViewDataSource
extension PickerView: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.collectionView {
            return dataSource?.numberOfComponentsInPickerView(self) ?? 0
            
        } else if
            let dataSource = dataSource,
            let componentCell = collectionView.superview?.superview as?PickerViewComponentCell,
            let component = self.collectionView.indexPathForCell(componentCell)?.item  {
                return dataSource.pickerView(self, numberOfRowsInComponent:component)
            
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if collectionView == self.collectionView {
            
            if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(pickerViewCompnentCellIdentifier, forIndexPath: indexPath) as? PickerViewComponentCell {
                
                if componentIndexCache.indexAt(component: indexPath.item) == nil {
                    componentIndexCache.changeAt(component: indexPath.item, row: 0)
                }
                
                if cell.collectionView.dataSource == nil {
                    cell.collectionView.dataSource = self
                }
                
                if cell.collectionView.delegate == nil {
                    cell.collectionView.delegate = self
                }
                
                if cell.selector == nil {
                    cell.selector = {[weak self] (comp, row, reusedView, actived, componentActived, rowActived) in
                        guard let sf = self else {return}
                        sf.dataSource?.pickerView(sf, viewForRow: row, forComponent: comp, reusingView: reusedView, actived: actived, componentActived: componentActived, rowActived: rowActived)
                        if actived {
                            sf.delegate?.pickerView(sf, didSelectRow: row, inComponent: comp)
                        }
                    }
                }
                return cell
                
            } else {
                fatalError()
            }
        } else if
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PickerViewRowCellIdentifier, forIndexPath: indexPath) as? PickerViewRowCell,
            let componentCell = collectionView.superview?.superview as? PickerViewComponentCell {
            if let component = self.collectionView.indexPathForCell(componentCell)?.item {
                let row = indexPath.item
                let ca = componentCell.actived
                let ra = cell.actived
                let actived = componentCell.actived && cell.actived
                if let v = cell.contentView.viewWithTag(1000) {
                        if cell.selector == nil {
                            cell.selector = {[weak self] (comp, row, reusedView, actived, componentActived, rowActived) in
                                guard let sf = self else {return}
                                sf.dataSource?.pickerView(sf, viewForRow: row, forComponent: comp, reusingView: reusedView, actived: actived, componentActived: componentActived, rowActived: rowActived)
                                if actived {
                                    sf.delegate?.pickerView(sf, didSelectRow: row, inComponent: comp)
                                }
                            }
                            dataSource?.pickerView(self, viewForRow: row, forComponent: component, reusingView: v, actived: actived, componentActived: ca, rowActived: ra)
                        }

                } else if let v = dataSource?.pickerView(self, viewForRow: indexPath.item, forComponent: component, reusingView: nil, actived: actived, componentActived: ca, rowActived: ra) {
                        cell.contentView.addSubview(v)
                        v.translatesAutoresizingMaskIntoConstraints = false
                        v.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor).active = true
                        v.bottomAnchor.constraintEqualToAnchor(cell.contentView.bottomAnchor).active = true
                        v.leftAnchor.constraintEqualToAnchor(cell.contentView.leftAnchor).active = true
                        v.rightAnchor.constraintEqualToAnchor(cell.contentView.rightAnchor).active = true
                        v.tag = 1000
                }
            }
            
            return cell
            
        } else {
            fatalError()
        }
    }
}

// MARK: - CollectionViewDelegate
extension PickerView: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = cell as? PickerViewComponentCell, let c = cell.collectionView { // row collectionView
            let component = indexPath.item
            dispatch_async(dispatch_get_main_queue(), {
                let i = self.componentIndexCache.indexAt(component: component) ?? 0
                if let attribute = c.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) {
                    let center = attribute.center
                    c.setContentOffset(CGPoint(x: 0, y: center.y - c.bounds.height / 2), animated: false)
                }
            })
            
        } else if let _ = cell as? PickerViewRowCell {
            
        }
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = cell as? PickerViewComponentCell, let c = cell.collectionView {
            let point = CGPoint(x: c.bounds.width / 2.0, y: c.contentOffset.y + bounds.height / 2.0)
            if let i = c.indexPathForItemAtPoint(point)?.item {
                let component = indexPath.item
                componentIndexCache.changeAt(component: component, row: i)
            }
            
        } else if let _ = cell as? PickerViewRowCell {
            
        }
    }
}

// MARK: ---------- PickerView DataSource ----------
protocol PickerViewDataSource: NSObjectProtocol {
    
    // Identifier
    // Register Vertical Cell Subclass
    // Horizontal Count
    // Vertical Count at Horizontal Index
    // Vertical Index at horizontal Index
    // Vertical Cell at (Horizontal Index & Vertical Index)
    func numberOfComponentsInPickerView(pickerView: PickerView) -> Int
    func pickerView(pickerView: PickerView, numberOfRowsInComponent component: Int) -> Int
    func pickerView(pickerView: PickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?, actived: Bool, componentActived: Bool, rowActived: Bool) -> UIView
}

// MARK: ---------- PickerView Delegate ----------
protocol PickerViewDelegate: NSObjectProtocol {
    // Vertical Index at Horizontal Index Did Changed to Index
    // Horizontal Index Did Changed to Index
//    func pickerView(pickerView: PickerView, rowHeightForComponent component: Int) -> CGFloat
//    func pickerView(pickerView: PickerView, widthForComponent component: Int) -> CGFloat
    func pickerView(pickerView: PickerView, didSelectRow row: Int, inComponent component: Int)
    
}

// MARK: ---------- PickerViewIndexCache ----------
final class PickerViewIndexCache {
    private var indexs = [Int: Int]()
    private let lock = NSLock()
    
    func changeAt(component com: Int, row: Int?) {
        lock.lock()
        indexs[com] = row
        lock.unlock()
    }
    func indexAt(component com: Int) -> Int? {
        lock.lock()
        let i = indexs[com]
        lock.unlock()
        return i
    }
}

// MARK: ---------- PickerView Vertical & Horzital Layout ----------
final class PickerViewAttributes: UICollectionViewLayoutAttributes {
    
    var actived: Bool = false
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let object = object as? PickerViewAttributes else {
            return false
        }
        return super.isEqual(object) && actived == object.actived
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! PickerViewAttributes
        copy.actived = actived
        return copy
    }
}
final class PickerViewLayout: UICollectionViewFlowLayout {
    
    private var currentIndexPath: NSIndexPath?
    
    override func prepareLayout() {
        super.prepareLayout()
        guard let collectionView = collectionView else {return}
        switch scrollDirection {
        case .Horizontal:
            let item = CGFloat(2 * 2)
            let r = (1 - 1 / item) / 2
            let width = collectionView.bounds.width
            let height = collectionView.bounds.height
            minimumLineSpacing = 0
            minimumInteritemSpacing = 0
            itemSize = CGSize(width: width / item, height: height)
            
            collectionView.contentInset = UIEdgeInsets(top: 0, left: width * r, bottom: 0, right: width * r)
            
        case .Vertical:
            let item = CGFloat(2 * 1)
            let r = (1 - 1 / item) / 2
            let width = collectionView.bounds.width
            let height = collectionView.bounds.height
            itemSize = CGSize(width: width, height: height / item)
            minimumLineSpacing = 0
            minimumInteritemSpacing = 0
            collectionView.contentInset = UIEdgeInsets(top: height * r, left: 0, bottom: height * r, right: 0)
        }
    }
    
    // attributes
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override class func layoutAttributesClass() -> AnyClass {
        return PickerViewAttributes.self
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let collectionView = collectionView, let attributes = super.layoutAttributesForElementsInRect(rect) as? [PickerViewAttributes] else { return nil }
        
        switch scrollDirection {
        case .Horizontal:
            
            let visualRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let activeDistance: CGFloat = itemSize.width / 2.0
            
            for attribute in attributes {
                if CGRectIntersectsRect(attribute.frame, rect) {
                    let distance = fabs((attribute.center.x - CGRectGetMidX(visualRect)))
                    if distance < activeDistance {
                        if currentIndexPath != attribute.indexPath {
                            if currentIndexPath != nil {
                                
                            }
                            currentIndexPath = attribute.indexPath
                        }
                        attribute.actived = true
                    } else {
                        attribute.actived = false
                    }
                }
            }
            
        case .Vertical:
            
            let visualRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let activeDistance: CGFloat = itemSize.height / 2.0
            
            for attribute in attributes {
                if CGRectIntersectsRect(attribute.frame, rect) {
                    let distance = fabs((attribute.center.y - CGRectGetMidY(visualRect)))
                    if distance < activeDistance {
                        if currentIndexPath != attribute.indexPath {
                            if currentIndexPath != nil {
                                
                            }
                            currentIndexPath = attribute.indexPath
                        }
                        attribute.actived = true
                    } else {
                        attribute.actived = false
                    }
                }
            }
        }
        return attributes
    }
    
    // target scroll
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {return proposedContentOffset}
        
        switch scrollDirection {
        case .Horizontal:
            var adjustOffset = CGFloat.max
            let proposedContentCenter = CGPoint(
                x: proposedContentOffset.x + CGRectGetWidth(collectionView.bounds) / 2.0,
                y: proposedContentOffset.y + CGRectGetHeight(collectionView.bounds) / 2.0)
            let targetRect = CGRect(origin: proposedContentOffset, size: collectionView.bounds.size)
            
            guard let attributes = layoutAttributesForElementsInRect(targetRect) else {
                return proposedContentOffset
            }
            
            if fabs(velocity.x) == 0 {
                let centerXs = attributes.map{$0.center.x}.sort(>)
                for x in centerXs {
                    let adjust = x - proposedContentCenter.x
                    if fabs(adjust) < fabs(adjustOffset) {
                        adjustOffset = adjust
                    }
                }
            } else {
                
                if velocity.x < 0 {
                    let centerXs = attributes.map{$0.center.x}.filter{$0 - proposedContentCenter.x < 0}.sort(>)
                    adjustOffset = 0
                    for x in centerXs {
                        let adjust = x - proposedContentCenter.x
                        if adjust < adjustOffset {
                            adjustOffset = adjust
                            break
                        }
                    }
                } else {
                    let centerXs = attributes.map{$0.center.x}.filter{$0 - proposedContentCenter.x > 0}.sort(<)
                    adjustOffset = 0
                    for x in centerXs {
                        let adjust = x - proposedContentCenter.x
                        if adjust > adjustOffset {
                            adjustOffset = adjust
                            break
                        }
                    }
                }
            }
            
            let offset = adjustOffset < 0 ? adjustOffset : adjustOffset
            let point = CGPoint(x: proposedContentOffset.x + offset, y: proposedContentOffset.y)
            return point
            
        case .Vertical:
            var adjustOffset = CGFloat.max
            let visualCenter = CGPoint(
                x: proposedContentOffset.x + CGRectGetWidth(collectionView.bounds) / 2.0,
                y: proposedContentOffset.y + CGRectGetHeight(collectionView.bounds) / 2.0)
            let targetRect = CGRect(origin: proposedContentOffset, size: collectionView.bounds.size)
            
            guard let attributes = layoutAttributesForElementsInRect(targetRect) else {
                return proposedContentOffset
            }
            
            let centerYs = attributes.map{$0.center.y}
            if fabs(velocity.y) == 0 {
                for y in centerYs {
                    let adjust = y - visualCenter.y
                    if fabs(adjust) < fabs(adjustOffset) {
                        adjustOffset = adjust
                    }
                }
            } else {
                if velocity.y < 0 {
                    adjustOffset = 0
                    for y in centerYs {
                        let adjust = y - visualCenter.y
                        if adjust < adjustOffset {
                            adjustOffset = adjust
                        }
                    }
                } else {
                    adjustOffset = 0
                    for y in centerYs {
                        let adjust = y - visualCenter.y
                        if adjust > adjustOffset {
                            adjustOffset = adjust
                        }
                    }
                }
            }
            return CGPoint(x: proposedContentOffset.x, y: proposedContentOffset.y + adjustOffset)
        }
    }
}

// MARK: ---------- PickerView Cell ----------
class PickerViewCell: UICollectionViewCell {
    
}

// MARK: ---------- PickerView Component Cell ----------
final class PickerViewComponentCell: PickerViewCell {
    
    private(set) var selector:((Int, Int, UIView?, Bool, Bool, Bool) -> ())?
    private(set) var actived: Bool = false
    private(set) var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let layout = PickerViewLayout()
        layout.scrollDirection = .Vertical
        let c = UICollectionView(frame: bounds, collectionViewLayout: layout)
        c.decelerationRate = UIScrollViewDecelerationRateFast
        c.backgroundColor = UIColor.clearColor()
        c.showsVerticalScrollIndicator = false
        c.showsHorizontalScrollIndicator = false
        c.registerClass(PickerViewRowCell.self, forCellWithReuseIdentifier: PickerViewRowCellIdentifier)
        c.autoresizingMask = [
            .FlexibleLeftMargin,
            .FlexibleRightMargin,
            .FlexibleTopMargin,
            .FlexibleBottomMargin]
        contentView.addSubview(c)
        collectionView = c
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        guard let layoutAttributes = layoutAttributes as? PickerViewAttributes else {return}
        
        if actived != layoutAttributes.actived {
            actived = layoutAttributes.actived
            let component = layoutAttributes.indexPath.item
            let visualRowCells = collectionView.visibleCells()
            for c in visualRowCells {
                if let c = c as? PickerViewRowCell, let indexPath = collectionView.indexPathForCell(c) {
                    let row = indexPath.item
                    let reusedView = c.contentView.viewWithTag(1000)
                    let active = actived && c.actived
                    selector?(component, row, reusedView, active, c.actived, actived)
                }
            }
        }
    }
}

// MARK: ---------- PickerView Row Cell ----------
final class PickerViewRowCell: PickerViewCell {
    
    var selector:((Int, Int, UIView?, Bool, Bool, Bool) -> ())?
    private(set) var actived: Bool = false
    private weak var superComponentCollectionView: UICollectionView?
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        guard let layoutAttributes = layoutAttributes as? PickerViewAttributes else {return}
        
        if actived != layoutAttributes.actived {
            actived = layoutAttributes.actived
            if let c = superview?.superview?.superview as? PickerViewComponentCell, let coll = superview?.superview?.superview?.superview as? UICollectionView {
                let componentActived = c.actived
                if let component = coll.indexPathForCell(c) {
                let v = contentView.viewWithTag(1000)
                selector?(component.item, layoutAttributes.indexPath.item, v, componentActived && actived, componentActived, actived)
                }
            }
        }
    }
}