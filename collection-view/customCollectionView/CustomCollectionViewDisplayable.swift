//
//  CustomCollectionViewDisplayable.swift
//  collection-view
//
//  Created by lauren.c on 2023/01/02.
//

import UIKit

protocol CustomCollectionViewDisplayable: AnyObject {
    associatedtype SectionType: Hashable
    
    typealias SectionIdentifier = CustomCollectionViewSection<SectionType>
    typealias Item = AnyHashable
    
    typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, Item>
    
    var collectionView: UICollectionView? { get set }
    var sections: [SectionIdentifier] { get set }
    var dataSource: DataSource? { get set }
    
    var delegate: CustomCollectionViewDelegate?{ get set }
}

extension CustomCollectionViewDisplayable {
    
    @discardableResult
    func createCollectionView(with delegate: CustomCollectionViewDelegate) -> UICollectionView {
        self.delegate = delegate
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        self.collectionView = collectionView
        
        // Registration
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "default")
        delegate.registerCells(collectionView)
        delegate.registerSupplementaryViews(collectionView)
        
        // DataSource Configuration
        dataSource = createDataSource(with: collectionView)
        collectionView.dataSource = dataSource
        
        return collectionView
    }
    
    // collectionView에 data를 반영하기 위한 함수.
    func apply(sections: [SectionIdentifier]) {
        guard let dataSource = dataSource else {
            fatalError("should be called after `createCollectionView()`")
        }
        self.sections = sections
        
        var snapshot = Snapshot()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    private func createDataSource(with collectionView: UICollectionView) -> DataSource {
        let dataSource = DataSource(collectionView: collectionView) { [unowned self] collectionView, indexPath, item in
            if let sectionIdentifier = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section],
               let cell = delegate?.collectionViewCell(collectionView, itemCellAt: indexPath, item: item, section: sectionIdentifier) {
                return cell
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: "default", for: indexPath)
        }
        
        dataSource.supplementaryViewProvider = { [unowned self] collectionView, kind, indexPath in
            if let sectionIdentifier = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section],
               let kind = CollectionViewElementKind(rawValue: kind),
               let supplementaryView = self.delegate?.collectionViewSupplementaryView(collectionView, indexPath: indexPath, section: sectionIdentifier, elementKind: kind) {
                return supplementaryView
            }
            return nil
        }
        
        return dataSource
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            guard let delegate = self.delegate else {
                fatalError("should called after `createCollectionView(with:)`")
            }
            let sectionIdentifier = self.sections[sectionIndex]
            let section = delegate.collectionViewItemLayout(sectionIndex: sectionIndex, section: sectionIdentifier).layout()
            
            var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
            if let headerLayout = delegate.collectionViewSupplementaryViewLayout(sectionIndex: sectionIndex, section: sectionIdentifier, elementKind: .sectionHeader) {
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerLayout, elementKind: CollectionViewElementKind.sectionHeader, alignment: .top)
                supplementaryItems.append(header)
            }
            if let footerLayout = delegate.collectionViewSupplementaryViewLayout(sectionIndex: sectionIndex, section: sectionIdentifier, elementKind: .sectionFooter) {
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerLayout, elementKind: CollectionViewElementKind.sectionFooter, alignment: .bottom)
                supplementaryItems.append(footer)
            }
            section.boundarySupplementaryItems = supplementaryItems
            return section
        }
    }
}

extension NSCollectionLayoutBoundarySupplementaryItem {
    convenience init(layoutSize: NSCollectionLayoutSize, elementKind: CollectionViewElementKind, alignment: NSRectAlignment) {
        self.init(layoutSize: layoutSize, elementKind: elementKind.rawValue, alignment: alignment)
    }
}


struct CustomCollectionViewItemLayout {
    enum Style {
        case grid(layoutSize: NSCollectionLayoutSize)
        case scroll(layoutSize: NSCollectionLayoutSize)
        case groupPaging(layoutSize: NSCollectionLayoutSize)
        case columnWithRatio(count: Int, widthHeightRatio: CGFloat)
        case columnWithHeight(count: Int, heightSize: CGFloat)
        case custom(layoutGroup: NSCollectionLayoutGroup)
    }
    let style: Style
    let itemInset: NSDirectionalEdgeInsets?
    
    init(style: Style, itemInset: NSDirectionalEdgeInsets? = nil) {
        self.style = style
        self.itemInset = itemInset
    }
}

extension CustomCollectionViewItemLayout {
    func layout() -> NSCollectionLayoutSection {
        switch style {
        case .grid(let layoutSize):
            let item = NSCollectionLayoutItem(layoutSize: layoutSize)
            if let itemInset = itemInset {
                item.contentInsets = itemInset
            }
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: layoutSize.heightDimension)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            return NSCollectionLayoutSection(group: group)
        case .scroll(let layoutSize):
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1.0)))
            if let itemInset = itemInset {
                item.contentInsets = itemInset
            }
            let groupSize = layoutSize
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            return section
        case .groupPaging(let layoutSize):
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1.0)))
            if let itemInset = itemInset {
                item.contentInsets = itemInset
            }
            let groupSize = layoutSize
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging
            return section
        case .columnWithRatio(var count, let widthHeightRatio):
            count = max(1, count)
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0/CGFloat(count)), heightDimension: .fractionalHeight(1.0)))
            if let itemInset = itemInset {
                item.contentInsets = itemInset
            }
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1.0/CGFloat(count)*widthHeightRatio))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            return NSCollectionLayoutSection(group: group)
        case .columnWithHeight(var count, let heightSize):
            count = max(1, count)
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0/CGFloat(count)), heightDimension: .fractionalHeight(1.0)))
            if let itemInset = itemInset {
                item.contentInsets = itemInset
            }
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(heightSize))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            return NSCollectionLayoutSection(group: group)
        case .custom(let layoutGroup):
            return NSCollectionLayoutSection(group: layoutGroup)
        }
    }
}

class CustomCollectionViewSection<SectionType: Hashable>: NSObject {
    var type: SectionType
    var items: [AnyHashable]
    
    init(type: SectionType, items: [AnyHashable]) {
        self.type = type
        self.items = items
    }
}
