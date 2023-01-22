//
//  CustomCollectionViewController.swift
//  collection-view
//
//  Created by lauren.c on 2023/01/02.
//

import UIKit

class CustomCollectionViewSection: NSObject {
    let sectionIdentifier: AnyHashable
    var items: [AnyHashable]
    
    init(sectionIdentifier: AnyHashable, items: [AnyHashable]) {
        self.sectionIdentifier = sectionIdentifier
        self.items = items
    }
}

class CustomCollectionViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<AnyHashable, AnyHashable>
    typealias Snapshot = NSDiffableDataSourceSnapshot<AnyHashable, AnyHashable>
    
    private var sections: [CustomCollectionViewSection] = []
    private var dataSource: DataSource!
    private var collectionView: UICollectionView!
    
    var delegate: CustomCollectionViewDelegate? {
        didSet {
            delegate?.registerCells(collectionView)
            delegate?.registerSupplementaryViews(collectionView)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView = createCollectionView()
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func createCollectionView() -> UICollectionView {
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        
        // Registration
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "default")
        
        // DataSource Configuration
        dataSource = createDataSource(with: collectionView)
        collectionView.dataSource = dataSource
        
        return collectionView
    }
    
    // collectionView에 data를 반영하기 위한 함수. 각 section의 sectionIdentifier는 unique해야 함
    func apply(sections: [CustomCollectionViewSection]) {
        self.sections = sections
        
        var snapshot = Snapshot()
        snapshot.appendSections(sections.map({ $0.sectionIdentifier }))
        for section in sections {
            snapshot.appendItems(section.items, toSection: section.sectionIdentifier)
        }
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    private func createDataSource(with collectionView: UICollectionView) -> DataSource {
        let dataSource = DataSource(collectionView: collectionView) { [unowned self] collectionView, indexPath, item in
            if let sectionIdentifier = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section],
               let cell = delegate?.collectionViewCell(collectionView, itemCellAt: indexPath, item: item, sectionIdentifier: sectionIdentifier) {
                return cell
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: "default", for: indexPath)
        }
        
        dataSource.supplementaryViewProvider = { [unowned self] collectionView, kind, indexPath in
            if let sectionIdentifier = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section],
               let kind = CollectionViewElementKind(rawValue: kind),
               let supplementaryView = self.delegate?.collectionViewSupplementaryView(collectionView, indexPath: indexPath, sectionIdentifier: sectionIdentifier, elementKind: kind) {
                return supplementaryView
            }
            return nil
        }
        
        return dataSource
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            guard let delegate = self.delegate else {
                fatalError("CustomCollectionViewController should have its delegate")
            }
            let sectionIdentifier = self.sections[sectionIndex].sectionIdentifier
            let section = delegate.collectionViewItemLayout(sectionIndex: sectionIndex, sectionIdentifier: sectionIdentifier).layout()
            
            var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
            if let headerLayout = delegate.collectionViewSupplementaryViewLayout(sectionIndex: sectionIndex, sectionIdentifier: sectionIdentifier, elementKind: .sectionHeader) {
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerLayout, elementKind: CollectionViewElementKind.sectionHeader, alignment: .top)
                supplementaryItems.append(header)
            }
            if let footerLayout = delegate.collectionViewSupplementaryViewLayout(sectionIndex: sectionIndex, sectionIdentifier: sectionIdentifier, elementKind: .sectionFooter) {
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

