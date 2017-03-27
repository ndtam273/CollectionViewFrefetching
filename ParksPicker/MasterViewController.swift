//
//  MasterViewController.swift
//  ParksPicker
/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */  


import UIKit

class MasterViewController: UICollectionViewController {
  
  var parksDataSource = ParksDataSource()
  
  let loadingQueue = OperationQueue()
  var loadingOperations = [IndexPath : DataLoadOperation]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let width = collectionView!.frame.width / 2
    let layout = collectionViewLayout as! UICollectionViewFlowLayout
    layout.itemSize = CGSize(width: width, height: width)
    
    collectionView?.prefetchDataSource = self
    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "MasterToDetail" {
      let detailViewController = segue.destination as! DetailViewController
      detailViewController.park = sender as? Park
    }
  }
  
}

// MARK: UICollectionViewDataSource
extension MasterViewController {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return parksDataSource.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ParkCell", for: indexPath) as! ParkCell

    cell.updateAppearanceFor(nil, animated: false)

    return cell
  }
  
  // Moving Cells
  override func collectionView(_ collectionView: UICollectionView,moveItemAt sourceIndexPath: IndexPath,
                               to destinationIndexPath: IndexPath) {
    parksDataSource.moveParkAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
  }
}

// MARK: UICollectionViewDelegate
extension MasterViewController {
  
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    
    guard let cell = cell as? ParkCell else { return }
    
    // How should the operation update the cell once the data has been loaded?
    let updateCellClosure: (Park?) -> () = { [unowned self] (nationalPark) in
      cell.updateAppearanceFor(nationalPark, animated: true)
      self.loadingOperations.removeValue(forKey: indexPath)
    }
    
    // Try to find an existing data loader
    if let dataLoader = loadingOperations[indexPath] {
      // Has the data already been loaded?
      if let thePark = dataLoader.nationalPark {
        cell.updateAppearanceFor(thePark, animated: false)
        loadingOperations.removeValue(forKey: indexPath)
      } else {
        // No data loaded yet, so add the completion closure to update the cell once the data arrives
        dataLoader.loadingCompleteHandler = updateCellClosure
      }
    } else {
      // Need to create a data loaded for this index path
      if let thePark = parksDataSource.parkForItemAtIndexPath(indexPath) {
        let dataLoader = DataLoadOperation(thePark)
        // Provide the completion closure, and kick off the loading operation
        dataLoader.loadingCompleteHandler = updateCellClosure
        loadingQueue.addOperation(dataLoader)
        loadingOperations[indexPath] = dataLoader
      }
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    // If there's a data loader for this index path we don't need it any more. Cancel and dispose
    if let dataLoader = loadingOperations[indexPath] {
      dataLoader.cancel()
      loadingOperations.removeValue(forKey: indexPath)
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let nationalPark = parksDataSource.parkForItemAtIndexPath(indexPath) {
      performSegue(withIdentifier: "MasterToDetail", sender: nationalPark)
    }
  }
  
}

// MARK : UICollectionViewDataSourcePrefetching
extension MasterViewController : UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let _ = loadingOperations[indexPath] {
                return
            }
            if let thePark = parksDataSource.parkForItemAtIndexPath(indexPath) {
                let dataLoader = DataLoadOperation(thePark)
                loadingQueue.addOperation(dataLoader)
                loadingOperations[indexPath] = dataLoader
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("Cancel Prefetch")
        for indexPath in indexPaths {
            if let dataLoader = loadingOperations[indexPath] {
                dataLoader.cancel()
                loadingOperations.removeValue(forKey: indexPath)
            }
        }
    }
}
