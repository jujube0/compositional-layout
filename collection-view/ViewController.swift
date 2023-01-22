//
//  ViewController.swift
//  collection-view
//
//  Created by lauren.c on 2023/01/02.
//

import UIKit
import Combine

class ViewController: CustomCollectionViewController {
    
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
        
        delegate = self
        
        setData()
    }
    
    private func setData() {
        var sections = [CustomCollectionViewSection]()
        
        var offset = 0
        let itemPerSection = 6
        sections.append(CustomCollectionViewSection(sectionIdentifier: SectionType.grid, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(CustomCollectionViewSection(sectionIdentifier: SectionType.columnWithRatio, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(CustomCollectionViewSection(sectionIdentifier: SectionType.columnWithHeight, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(CustomCollectionViewSection(sectionIdentifier: SectionType.scrollWithFractional, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(CustomCollectionViewSection(sectionIdentifier: SectionType.scrollWithAbsolute, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(CustomCollectionViewSection(sectionIdentifier: SectionType.groupPaging, items: Array(offset..<offset+itemPerSection)))
        offset += itemPerSection
        sections.append(CustomCollectionViewSection(sectionIdentifier: SectionType.custom, items: Array(offset..<offset+itemPerSection)))
        apply(sections: sections)
    }
}
extension ViewController: CustomCollectionViewDelegate {
    func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(CustomGridCell.self, forCellWithReuseIdentifier: CustomGridCell.reuseIdentifier)
    }
    
    func collectionViewCell(_ collectionView: UICollectionView, itemCellAt indexPath: IndexPath, item: AnyHashable, sectionIdentifier: AnyHashable) -> UICollectionViewCell? {
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
    
    func collectionViewItemLayout(sectionIndex: Int, sectionIdentifier: AnyHashable) -> CustomCollectionViewItemLayout {
        guard let sectionType = sectionIdentifier as? SectionType else {
            fatalError("wrong sectionIdentifier for CustomCollectionViewController")
        }
        let layout: CustomCollectionViewItemLayout.Style
        switch sectionType {
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
    
    func collectionViewSupplementaryViewLayout(sectionIndex: Int, sectionIdentifier: AnyHashable, elementKind: CollectionViewElementKind) -> NSCollectionLayoutSize? {
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
    
    func collectionViewSupplementaryView(_ collectionView: UICollectionView, indexPath: IndexPath, sectionIdentifier: AnyHashable, elementKind: CollectionViewElementKind) -> UICollectionReusableView? {
        guard elementKind == .sectionHeader,
              let section = sectionIdentifier as? SectionType else {
            return nil
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind.rawValue, withReuseIdentifier: CustomSectionHeader.reuseIdentifier, for: indexPath) as? CustomSectionHeader
        header?.label.text = section.rawValue
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
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
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
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
