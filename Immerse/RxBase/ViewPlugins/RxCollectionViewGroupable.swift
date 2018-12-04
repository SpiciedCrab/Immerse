//
//  RxMogo+CollectionViewGroupable.swift
//  Pods
//
//  Created by guanxiaobai on 24/04/2018.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources

public typealias ConfigureCollectionCell<RowItem> = (CollectionViewSectionedDataSource<LingoSection<RowItem>>, UICollectionView, IndexPath, RowItem) -> UICollectionViewCell
public typealias ConfigureSupplementaryView<RowItem> = (CollectionViewSectionedDataSource<LingoSection<RowItem>>, UICollectionView, String, IndexPath) -> UICollectionReusableView
public typealias MoveItem<RowItem> = (CollectionViewSectionedDataSource<LingoSection<RowItem>>, _ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath) -> Void
public typealias CanMoveItemAtIndexPath<RowItem> = (CollectionViewSectionedDataSource<LingoSection<RowItem>>, IndexPath) -> Bool

public extension Observable {
  public func bind<RowItem>(collectionView: UICollectionView,
                            configCell: @escaping ConfigureCollectionCell<RowItem>,
                            configureSupplementaryView: ConfigureSupplementaryView<RowItem>? = nil,
                            moveItem: @escaping MoveItem<RowItem> = { _, _, _ in () },
                            canMoveItemAtIndexPath: @escaping CanMoveItemAtIndexPath<RowItem> = { _, _ in false }) -> Disposable where E == [LingoSection<RowItem>] {
    let dataSource = RxCollectionViewSectionedReloadDataSource<LingoSection<RowItem>>(configureCell: configCell,
                                                                                      configureSupplementaryView: configureSupplementaryView,
                                                                                      moveItem: moveItem,
                                                                                      canMoveItemAtIndexPath: canMoveItemAtIndexPath)
    return self.bind(to: collectionView.rx.items(dataSource: dataSource))
  }
}
