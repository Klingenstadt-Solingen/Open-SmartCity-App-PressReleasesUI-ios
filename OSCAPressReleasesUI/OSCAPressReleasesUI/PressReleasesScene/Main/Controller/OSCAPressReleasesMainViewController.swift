//
//  OSCAPressReleasesMainViewController.swift
//  OSCAPressReleasesUI
//
//  Created by Mammut Nithammer on 19.01.22.
//  Reviewed by Stephan Breidenbach on 16.02.23
//

import OSCAEssentials
import OSCAPressReleases
import UIKit
import Combine

public final class OSCAPressReleasesMainViewController: UIViewController, Alertable, ActivityIndicatable {
  public var activityIndicatorView: ActivityIndicatorView = ActivityIndicatorView(style: .large)
  
  @IBOutlet private var collectionView: UICollectionView!
  
  private typealias DataSource = UICollectionViewDiffableDataSource<OSCAPressReleasesMainViewModel.Section, OSCAPressRelease>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAPressReleasesMainViewModel.Section, OSCAPressRelease>
  private var viewModel: OSCAPressReleasesMainViewModel!
  private var bindings = Set<AnyCancellable>()
  
  private var dataSource: DataSource!
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    setupBindings()
    setupSelectedItemBinding()
    viewModel.viewDidLoad()
  }// end override public func viewDidLoad
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    OSCAMatomoTracker.shared.trackPath(["pressreleases"])
    self.navigationController?.setup(
      largeTitles: true,
      tintColor: OSCAPressReleasesUI.configuration.colorConfig.navigationTintColor,
      titleTextColor: OSCAPressReleasesUI.configuration.colorConfig.navigationTitleTextColor,
      barColor: OSCAPressReleasesUI.configuration.colorConfig.navigationBarColor)
  }// end public override func viewWillAppear
  
  /// setup view
  /// * color
  /// * search controller
  /// * navigation item
  /// * activity indicator
  /// * collection view
  private func setupViews() {
    view.backgroundColor = OSCAPressReleasesUI.configuration.colorConfig.backgroundColor
    // setup search controller
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = viewModel.searchPlaceholder
    self.navigationItem.searchController = searchController
    searchController.isActive = true
    
    if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
      textfield.textColor = OSCAPressReleasesUI.configuration.colorConfig.blackColor
      textfield.tintColor = OSCAPressReleasesUI.configuration.colorConfig.navigationTintColor
      textfield.backgroundColor = OSCAPressReleasesUI.configuration.colorConfig.grayLight
      textfield.leftView?.tintColor = OSCAPressReleasesUI.configuration.colorConfig.grayDarker
      textfield.returnKeyType = .done
      textfield.keyboardType = .default
      textfield.enablesReturnKeyAutomatically = false
      
      if let clearButton = textfield.value(forKey: "_clearButton") as? UIButton {
        let templateImage = clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
        clearButton.setImage(templateImage, for: .normal)
        clearButton.tintColor = OSCAPressReleasesUI.configuration.colorConfig.grayDarker
      }// end if
      
      if let label = textfield.value(forKey: "placeholderLabel") as? UILabel {
        label.attributedText = NSAttributedString(
          string: viewModel.searchPlaceholder,
          attributes: [.foregroundColor: OSCAPressReleasesUI.configuration.colorConfig.grayDarker])
      }// end if
    }// end if
    // setup navigation item
    navigationItem.title = viewModel.screenTitle
    // activity indication view
    setupActivityIndicator()
    // setup collection view
    setupCollectionView()
  }// end private func setupViews
  
  /// setup the collection view:
  /// * delegation
  /// * color
  /// * view cell
  /// * layout
  /// * [pull to refresh control](https://mobikul.com/pull-to-refresh-in-swift/)
  private func setupCollectionView() {
    collectionView.delegate = self
    collectionView.backgroundColor = OSCAPressReleasesUI.configuration.colorConfig.backgroundColor
    collectionView.register(UINib(nibName: "OSCAPressReleasesMainCollectionViewCell", bundle: OSCAPressReleasesUI.bundle), forCellWithReuseIdentifier: OSCAPressReleasesMainCollectionViewCell.identifier)
    collectionView.collectionViewLayout = createLayout()
    // pull to refresh
    collectionView.refreshControl = UIRefreshControl()
    // add target to UIRefreshControl
    collectionView.refreshControl?.addTarget(self,
                                             action: #selector(callPullToRefresh),
                                             for: .valueChanged)
  }// end private func setupCollectionView
  
  private func createLayout() -> UICollectionViewLayout {
    let height = OSCAPressReleasesUI.configuration.itemHeight
    let size = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(height))
    let item = NSCollectionLayoutItem(layoutSize: size)
    
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(height))
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: groupSize,
      subitems: [item])
    group.interItemSpacing = .fixed(8)
    
    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 16,
      leading: 16,
      bottom: 16,
      trailing: 16)
    section.interGroupSpacing = 8
    
    return UICollectionViewCompositionalLayout(section: section)
  }// end private func createLayout
  
  // MARK: - View Model Binding
  
  private func setupBindings() {
    viewModel.$pressReleases
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] pressReleases in
        guard let `self` = self else { return }
        self.configureDataSource()
        self.updateSections(pressReleases)
      })
      .store(in: &bindings)
    
    viewModel.$searchedPressReleases
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] pressReleases in
        guard let `self` = self else { return }
        self.configureDataSource()
        self.updateSections(pressReleases)
      })
      .store(in: &bindings)
    
    let startLoading = {
      self.collectionView.isUserInteractionEnabled = false
      self.showActivityIndicator()
    }// end let startLoading closure
    
    let finishLoading = {
      self.collectionView.isUserInteractionEnabled = true
      self.hideActivityIndicator()
      if let selectedItem = self.viewModel.selectedItem { self.selectItem(with: selectedItem) }
    }// ed let finishLoading
    
    let stateValueHandler: (OSCAPressReleaseMainViewModelState) -> Void = { [weak self] state in
      guard let `self` = self else { return }
      switch state {
      case .loading: // start loading
        startLoading()
      case .finishedLoading: // finished loading
        finishLoading()
      case let .error(error): // error
        finishLoading()
        self.showAlert(
          title: self.viewModel.alertTitleError,
          error: error,
          actionTitle: self.viewModel.alertActionConfirm)
      }// end switch case
    }// end stateValueHandler
    
    viewModel.$state
      .receive(on: RunLoop.main)
      .sink(receiveValue: stateValueHandler)
      .store(in: &bindings)
  }// end private func setupBindings
  
  /// [Apple documentation ui refresh control](https://developer.apple.com/documentation/uikit/uirefreshcontrol)
  @objc func callPullToRefresh(){
    viewModel.callPullToRefresh()
    DispatchQueue.main.async {
      self.collectionView.refreshControl?.endRefreshing()
    }// end
  }// end @objc func callPullToRefresh
  
  private func updateSections(_ pressReleases: [OSCAPressRelease]) {
    var snapshot = Snapshot()
    snapshot.appendSections([.pressReleases])
    snapshot.appendItems(pressReleases)
    dataSource.apply(snapshot, animatingDifferences: true)
  }// end private func updateSections
}// end public final class OSCAPressReleasesMainViewController

extension OSCAPressReleasesMainViewController {
  private func configureDataSource() -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    self.dataSource = DataSource(
      collectionView: self.collectionView,
      cellProvider: { (collectionView, indexPath, pressRelease) -> UICollectionViewCell in
        guard let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: OSCAPressReleasesMainCollectionViewCell.identifier,
          for: indexPath) as? OSCAPressReleasesMainCollectionViewCell
        else { return UICollectionViewCell() }
        
        let cellViewModel = OSCAPressReleasesMainCellViewModel(
          dataModule: self.viewModel.dataModule,
          pressRelease: pressRelease)
        cell.fill(with: cellViewModel)
        
        return cell
      })// end data source
  }// end private func configureDataSource
}// end extension public final class OSCAPressReleasesMainViewController

// MARK: - UICollectionViewDelegate conformance
extension OSCAPressReleasesMainViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard collectionView === self.collectionView else { return }
    viewModel.didSelectItem(at: indexPath.row)
  }// end
}// end extension public final class OSCAPressReleasesMainViewController

// MARK: - UISearchResultsUpdating conformance
extension OSCAPressReleasesMainViewController: UISearchResultsUpdating {
  public func updateSearchResults(for searchController: UISearchController) {
    guard let text = searchController.searchBar.text else { return }
    viewModel.updateSearchResults(for: text)
  }// end public func updateSearchResults
}// end extension public final class OSCAPressReleasesMainViewController

// MARK: - instantiate view conroller
extension OSCAPressReleasesMainViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAPressReleaseMainViewController.create(viewModel)
  public static func create(with viewModel: OSCAPressReleasesMainViewModel) -> OSCAPressReleasesMainViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let vc: Self = Self.instantiateViewController(OSCAPressReleasesUI.bundle)
    vc.viewModel = viewModel
    return vc
  }// end public static func create
}// end extension public final class OSCAPressReleasesMainViewController

// MARK: - Deeplinking
extension OSCAPressReleasesMainViewController {
  
  private func setupSelectedItemBinding() -> Void {
    viewModel.$selectedItem
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] selectedItem in
        guard let `self` = self,
              let selectedItem = selectedItem
        else { return }
        self.selectItem(with: selectedItem)
      })
      .store(in: &bindings)
  }// end private func setupSelectedItemBinding
  
  private func selectItem(with index: Int) -> Void {
    let indexPath: IndexPath = IndexPath(row: index, section: 0)
    collectionView.selectItem(at: indexPath,
                              animated: true,
                              scrollPosition: .top)
    self.collectionView(collectionView, didSelectItemAt: indexPath)
  }// end private func selectItem with index
  
  func didReceiveDeeplinkDetail(with objectId: String) -> Void {
    viewModel.didReceiveDeeplinkDetail(with: objectId)
  }// end func didReceiveDeeplinkDetail
}// end extension public final class OSCAPressReleasesMainViewController
