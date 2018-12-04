//
//  RxMogo+CollectionViewPlain.swift
//  Pods
//
//  Created by guanxiaobai on 24/04/2018.
//

import Foundation
import Foundation
import RxCocoa
import RxSwift

public extension Observable where Element: Collection {
  
  public func plainBind(to collectionView: UICollectionView,
                        by configCell : @escaping
    (IndexPath, E.Iterator.Element) -> UICollectionViewCell) -> Disposable {
    return self.bind(to: collectionView.rx.items) { (_, row, element: E.Iterator.Element) in
      return configCell(IndexPath(row: row, section: 0), element)
    }
  }
  
  public func plainBind<Cell: UICollectionViewCell>(to collectionView: UICollectionView,
                                                    by configCell: @escaping (IndexPath, E.Iterator.Element, Cell) -> Void )
    -> Disposable {
      return bind(to: collectionView.rx
        .items(cellIdentifier: Cell.reuseIdentifier)) {(path, item: E.Iterator.Element, cell: Cell) in
          configCell(IndexPath(row: path, section: 0), item, cell)
      }
  }
  
}
