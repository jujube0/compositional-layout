//
//  ViewController.swift
//  collection-view
//
//  Created by lauren.c on 2023/01/02.
//

import UIKit
import SnapKit
import Combine

class ViewController: UIViewController, CustomCollectionViewDisplayable {
    
    var collectionView: UICollectionView?
    var sections: [SectionIdentifier] = []
    var dataSource: DataSource?
    
    weak var delegate: CustomCollectionViewDelegate?
    
    enum SectionType: String, Hashable {
        case grid
        case columnWithRatio
        case columnWithHeight
        case scrollWithFractional
        case scrollWithAbsolute
        case groupPaging
        case custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionView = createCollectionView(with: self)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        setData()
    }
    
    private func setData() {
        var sections = [SectionIdentifier]()
        
        var offset = 0
        let itemPerSection = 6
        sections.append(SectionIdentifier(type: .grid, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(SectionIdentifier(type: .columnWithRatio, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(SectionIdentifier(type: .columnWithHeight, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(SectionIdentifier(type: .scrollWithFractional, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(SectionIdentifier(type: .scrollWithAbsolute, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(SectionIdentifier(type: .groupPaging, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(SectionIdentifier(type: .custom, items: Array(offset..<offset+itemPerSection)))
        apply(sections: sections)
    }
}
extension ViewController: CustomCollectionViewDelegate {
    func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(CustomGridCell.self, forCellWithReuseIdentifier: CustomGridCell.reuseIdentifier)
    }
    
    func collectionViewCell(_ collectionView: UICollectionView, itemCellAt indexPath: IndexPath, item: AnyHashable, section: AnyHashable) -> UICollectionViewCell? {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomGridCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? CustomGridCell,
           let item = item as? Int {
            cell.label.text = "\(item+1)"
        }
        
        if indexPath.section % 2 == 0 {
            cell.backgroundColor = .orange
        } else {
            cell.backgroundColor = .systemPink
        }
        
        return cell
    }
    
    func collectionViewItemLayout(sectionIndex: Int, section: AnyHashable) -> CustomCollectionViewItemLayout {
        guard let section = section as? SectionIdentifier else {
            fatalError("unknown section idedntifier")
        }
        let layout: CustomCollectionViewItemLayout.Style
        switch section.type {
        case .grid:
            layout = .grid(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalWidth(1/3)))
        case .columnWithRatio:
            layout = .columnWithRatio(count: 2, widthHeightRatio: 1.0)
        case .columnWithHeight:
            layout = .columnWithHeight(count: 3, heightSize: 44.0)
        case .scrollWithFractional:
            layout = .scroll(layoutSize: .init(widthDimension: .fractionalWidth(0.3), heightDimension: .fractionalWidth(0.3)))
        case .scrollWithAbsolute:
            layout = .scroll(layoutSize: .init(widthDimension: .absolute(100.0), heightDimension: .absolute(120.0)))
        case .groupPaging:
            layout = .groupPaging(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1.0)))
        case .custom:
            let leadingItem = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.7), heightDimension: .fractionalHeight(1.0)))
            leadingItem.contentInsets = .init(top: 1, leading: 1, bottom: 1, trailing: 1)
            let trailingItem = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.5)))
            trailingItem.contentInsets = .init(top: 1, leading: 1, bottom: 1, trailing: 1)
            let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(0.3), heightDimension: .fractionalHeight(1.0)), repeatingSubitem: trailingItem, count: 2)
            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.4)), subitems: [leadingItem, trailingGroup])
            layout = .custom(layoutGroup: nestedGroup)
        }
        let itemInset = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
        return CustomCollectionViewItemLayout(style: layout, itemInset: itemInset)
    }
    
    func collectionViewSupplementaryViewLayout(sectionIndex: Int, section: AnyHashable, elementKind: CollectionViewElementKind) -> NSCollectionLayoutSize? {
        switch elementKind {
        case .sectionHeader:
            return .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44.0))
        case .sectionFooter:
            return nil
        }
    }
    func registerSupplementaryViews(_ collectionView: UICollectionView) {
        collectionView.register(CustomSectionHeader.self, forSupplementaryViewOfKind: CollectionViewElementKind.sectionHeader.rawValue, withReuseIdentifier: CustomSectionHeader.reuseIdentifier)
    }
    
    func collectionViewSupplementaryView(_ collectionView: UICollectionView, indexPath: IndexPath, section: AnyHashable, elementKind: CollectionViewElementKind) -> UICollectionReusableView? {
        guard elementKind == .sectionHeader,
              let section = section as? SectionIdentifier else {
            return nil
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind.rawValue, withReuseIdentifier: CustomSectionHeader.reuseIdentifier, for: indexPath) as? CustomSectionHeader
        header?.label.text = section.type.rawValue
        return header
    }
}

final class CustomGridCell: UICollectionViewCell {
    static let reuseIdentifier = "custom-grid-cell"
    var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label = UILabel()
        label.textColor = .black
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

final class CustomSectionHeader: UICollectionReusableView {
    
    static let reuseIdentifier = "custom-section-header"
    
    var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label = UILabel()
        label.textColor = .black
        addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(5.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
