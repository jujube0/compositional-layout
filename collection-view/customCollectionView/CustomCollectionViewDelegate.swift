//
//  CustomCollectionViewDelegate.swift
//  collection-view
//
//  Created by lauren.c on 2023/01/11.
//

import UIKit

enum CollectionViewElementKind: String {
    case sectionHeader, sectionFooter
}

// weak var 로 정의하기 위해 AnyObject conformance 추가
protocol CustomCollectionViewDelegate: AnyObject {
    // Item Layout
    func collectionViewItemLayout(sectionIndex: Int, section: AnyHashable) -> CustomCollectionViewItemLayout
        
    // Item
    func registerCells(_ collectionView: UICollectionView)
    func collectionViewCell(_ collectionView: UICollectionView, itemCellAt: IndexPath, item: AnyHashable, section: AnyHashable) -> UICollectionViewCell?
    
    // Header & Footer Layout (Optional)
    func collectionViewSupplementaryViewLayout(sectionIndex: Int, section: AnyHashable, elementKind: CollectionViewElementKind) -> NSCollectionLayoutSize?
    
    // Header & Footer (Optional)
    func registerSupplementaryViews(_ collectionView: UICollectionView)
    func collectionViewSupplementaryView(_ collectionView: UICollectionView, indexPath: IndexPath, section: AnyHashable, elementKind: CollectionViewElementKind) -> UICollectionReusableView?
}

extension CustomCollectionViewDelegate {
    func collectionViewSupplementaryViewLayout(sectionIndex: Int, section: AnyHashable, elementKind: CollectionViewElementKind) -> NSCollectionLayoutSize? { nil }
    func registerSupplementaryViews(_ collectionView: UICollectionView) { }
    func collectionViewSupplementaryView(_ collectionView: UICollectionView, indexPath: IndexPath, section: AnyHashable, elementKind: CollectionViewElementKind) -> UICollectionReusableView? { nil }
}
