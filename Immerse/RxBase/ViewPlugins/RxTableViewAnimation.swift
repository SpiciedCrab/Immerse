//
//  RxMogo+TableViewAnimation.swift
//  Pods
//
//  Created by guanxiaobai on 25/04/2018.
//

import Foundation
import RxSwift
import RxDataSources

public typealias RxCellType =  UITableViewCell & RxCellConfigurable

extension Observable {
  public typealias DecideViewTransitionTable<RowItem: SectionAnimatable> = (TableViewSectionedDataSource<AnimatableSection<RowItem>>, UITableView, [Changeset<AnimatableSection<RowItem>>]) -> ViewTransition
  public typealias ConfigureCellTable<RowItem: SectionAnimatable> = (TableViewSectionedDataSource<AnimatableSection<RowItem>>, UITableView, IndexPath, RowItem) -> UITableViewCell
  public typealias CanEditRowAtIndexPath<RowItem: SectionAnimatable> = (TableViewSectionedDataSource<AnimatableSection<RowItem>>, IndexPath) -> Bool
  public typealias CanMoveRowAtIndexPath<RowItem: SectionAnimatable> = (TableViewSectionedDataSource<AnimatableSection<RowItem>>, IndexPath) -> Bool
  
  public func animationBind<RowItem: SectionAnimatable>(tableView: UITableView,
                                                        animationConfiguration: AnimationConfiguration = AnimationConfiguration(),
                                                        decideViewTransition: @escaping DecideViewTransitionTable<RowItem> = { _, _, _ in .animated },
                                                        configureCell: @escaping ConfigureCellTable<RowItem>,
                                                        canEditRowAtIndexPath: @escaping CanEditRowAtIndexPath<RowItem>  = { _, _ in false },
                                                        canMoveRowAtIndexPath: @escaping CanMoveRowAtIndexPath<RowItem>  = { _, _ in false }) -> Disposable where E == [AnimatableSection<RowItem>] {
    let dataSource = RxTableViewSectionedAnimatedDataSource(animationConfiguration: animationConfiguration,
                                                            decideViewTransition: decideViewTransition,
                                                            configureCell: configureCell,
                                                            titleForHeaderInSection: { (data, section) -> String? in
                                                              return data.sectionModels[section].header
    },
                                                            canEditRowAtIndexPath: canEditRowAtIndexPath,
                                                            canMoveRowAtIndexPath: canMoveRowAtIndexPath)
    return bind(to: tableView.rx.items(dataSource: dataSource))
  }
}

extension UITableView {
  func simpleBind<RowItem , Cell: RxCellType>(dataSource: Observable<[AnimatableSection<RowItem>]> ,
                                              with cell: Cell.Type,
                                              with preparation : ((UITableView, IndexPath ,RowItem , Cell)-> ())? = nil) -> Disposable where RowItem == Cell.CellModel {
    return dataSource.animationBind(tableView: self, configureCell: { (_,tableView, path, item: RowItem) -> UITableViewCell in
      let cell: Cell = tableView.smoothlyDequeueCell(forIndexPath: path)
      cell.setup(with: item)
      
      if let realPre = preparation {
        realPre(tableView , path , item, cell)
      }
      return cell
    })
  }
  
  func simpleBind<RowItem , Cell: RxCellType>(dataSource: Observable<[LingoSection<RowItem>]> ,
                                              with cell: Cell.Type,
                                              with preparation : ((UITableView, IndexPath ,RowItem, Cell)-> ())? = nil) -> Disposable where RowItem == Cell.CellModel {
    return dataSource.bind(to: self) { (dataSource, tableView, path, item: RowItem) -> UITableViewCell in
      let cell: Cell = tableView.smoothlyDequeueCell(forIndexPath: path)
      cell.setup(with: item)
      
      if let realPre = preparation {
        realPre(tableView , path , item , cell)
      }
      
      return cell
    }
  }
}
