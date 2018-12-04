//
//  RxMogo+CollectionViewAnimation.swift
//  Pods
//
//  Created by guanxiaobai on 25/04/2018.
//

import Foundation
import RxSwift
import RxDataSources
import Differentiator

extension Observable {
  
  public typealias DecideViewTransition<RowItem: SectionAnimatable> = (CollectionViewSectionedDataSource<AnimatableSection<RowItem>>, UICollectionView, [Changeset<AnimatableSection<RowItem>>]) -> ViewTransition
  public typealias ConfigureCollectionCellAni<RowItem: SectionAnimatable> = (CollectionViewSectionedDataSource<AnimatableSection<RowItem>>, UICollectionView, IndexPath, RowItem) -> UICollectionViewCell
  public typealias ConfigureSupplementaryViewAni<RowItem: SectionAnimatable> = (CollectionViewSectionedDataSource<AnimatableSection<RowItem>>, UICollectionView, String, IndexPath) -> UICollectionReusableView
  public typealias MoveItemAni<RowItem: SectionAnimatable> = (CollectionViewSectionedDataSource<AnimatableSection<RowItem>>, _ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath) -> Void
  public typealias CanMoveItemAtIndexPathAni<RowItem: SectionAnimatable> = (CollectionViewSectionedDataSource<AnimatableSection<RowItem>>, IndexPath) -> Bool
  
  public func animationBind<RowItem: SectionAnimatable>(collectionView: UICollectionView,
                                                        animationConfiguration: AnimationConfiguration = AnimationConfiguration(),
                                                        decideViewTransition: @escaping DecideViewTransition<RowItem> = { _, _, _ in .animated },
                                                        configCell: @escaping ConfigureCollectionCellAni<RowItem>,
                                                        configureSupplementaryView: @escaping ConfigureSupplementaryViewAni<RowItem>,
                                                        moveItem: @escaping MoveItemAni<RowItem> = { _, _, _ in () },
                                                        canMoveItemAtIndexPath: @escaping CanMoveItemAtIndexPathAni<RowItem> = { _, _ in false }) -> Disposable where E == [AnimatableSection<RowItem>] {
    let dataSource =  RxCollectionViewSectionedAnimatedDataSource<AnimatableSection<RowItem>>(animationConfiguration: animationConfiguration,
                                                                                              decideViewTransition: decideViewTransition,
                                                                                              configureCell: configCell,
                                                                                              configureSupplementaryView: configureSupplementaryView,
                                                                                              moveItem: moveItem,
                                                                                              canMoveItemAtIndexPath: canMoveItemAtIndexPath)
    return self.bind(to: collectionView.rx.items(dataSource: dataSource))
  }
}
