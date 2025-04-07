//
//  OSCAPressReleasesMainWidgetViewController.swift
//  OSCAPressReleasesUI
//
//  Created by Ömer Kurutay on 25.04.23.
//

import OSCAEssentials
import OSCAPressReleases
import UIKit
import Combine

public final class OSCAPressReleasesMainWidgetViewController: UIViewController, Alertable, ActivityIndicatable, WidgetExtender {
  
  public var activityIndicatorView: ActivityIndicatorView = ActivityIndicatorView(style: .large)
  
  @IBOutlet private var collectionView: UICollectionView!
  
  @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
  
  private typealias DataSource = UICollectionViewDiffableDataSource<OSCAPressReleasesMainWidgetViewModel.Section, OSCAPressRelease>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAPressReleasesMainWidgetViewModel.Section, OSCAPressRelease>
  
  private var viewModel: OSCAPressReleasesMainWidgetViewModel!
  private var bindings = Set<AnyCancellable>()
  
  private var dataSource: DataSource!
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.setupBindings()
    self.viewModel.viewDidLoad()
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let colorConfig = self.viewModel.colorConfig
    self.navigationController?.setup(
      largeTitles: false,
      tintColor: colorConfig.navigationTintColor,
      titleTextColor: colorConfig.navigationTitleTextColor,
      barColor: colorConfig.navigationBarColor)
  }
  
  private func setupViews() {
    self.view.backgroundColor = .clear
    
    self.navigationItem.title = self.viewModel.screenTitle
    
    self.setupActivityIndicator()
    self.setupCollectionView()
  }
  
  private func setupCollectionView() {
    self.collectionView.delegate = self
    self.collectionView.backgroundColor = .clear
    let nib = UINib(
      nibName: OSCAPressReleasesMainCollectionViewCell.identifier,
      bundle: OSCAPressReleasesUI.bundle)
    self.collectionView.register(
      nib,
      forCellWithReuseIdentifier: OSCAPressReleasesMainCollectionViewCell.identifier)
    self.collectionView.collectionViewLayout = self.createLayout()
    self.collectionViewHeightConstraint.constant = 150
  }
  
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
      top: 0,
      leading: 0,
      bottom: 0,
      trailing: 0)
    section.interGroupSpacing = 8
    
    return UICollectionViewCompositionalLayout(section: section)
  }
  
  // MARK: - View Model Binding
  private func setupBindings() {
    self.viewModel.$pressReleases
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] pressReleases in
        guard let `self` = self else { return }
        self.configureDataSource()
        self.updateSections(pressReleases)
      })
      .store(in: &self.bindings)
    
    let startLoading = {
      self.collectionView.isUserInteractionEnabled = false
      self.showActivityIndicator()
    }
    
    let finishLoading = {
      self.collectionView.isUserInteractionEnabled = true
      self.hideActivityIndicator()
      self.view.layoutIfNeeded()
      let height = self.viewModel.pressReleases.count == 0
        ? 100
        : self.collectionView.collectionViewLayout.collectionViewContentSize.height
      self.collectionViewHeightConstraint.constant = height
      
      guard let didLoadContent = self.didLoadContent
      else { return }
      didLoadContent(self.viewModel.pressReleases.count)
    }
    
    let stateValueHandler: (OSCAPressReleasesMainWidgetViewModel.State) -> Void = { [weak self] state in
      guard let `self` = self else { return }
      switch state {
      case .loading:
        startLoading()
      case .finishedLoading:
        finishLoading()
      case let .error(error):
        finishLoading()
        self.showAlert(
          title: self.viewModel.alertTitleError,
          error: error,
          actionTitle: self.viewModel.alertActionConfirm)
      }
    }
    
    self.viewModel.$state
      .receive(on: RunLoop.main)
      .sink(receiveValue: stateValueHandler)
      .store(in: &self.bindings)
  }
  
  private func updateSections(_ pressReleases: [OSCAPressRelease]) {
    var snapshot = Snapshot()
    snapshot.appendSections([.pressReleases])
    snapshot.appendItems(pressReleases)
    self.dataSource.apply(snapshot, animatingDifferences: true)
  }
  
  // MARK: WidgetExtender
  /// Closure parameter sends the number of press releases
  public var didLoadContent   : ((Int) -> Void)?
  /// Closure parameter sends a deeplink of type __URL__
  public var performNavigation: ((Any) -> Void)?
  
  public func refreshContent() {
    self.viewModel.refreshContent()
  }
}

extension OSCAPressReleasesMainWidgetViewController {
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
      })
  }
}

// MARK: - Collection View Delegate
extension OSCAPressReleasesMainWidgetViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let deeplink = self.viewModel.pressReleases[indexPath.row].deepLink,
          let url = URL(string: deeplink),
          let performNavigation = self.performNavigation
    else { return }
    performNavigation(url)
  }
}

// MARK: - instantiate view conroller
extension OSCAPressReleasesMainWidgetViewController: StoryboardInstantiable {
  public static func create(with viewModel: OSCAPressReleasesMainWidgetViewModel) -> OSCAPressReleasesMainWidgetViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let vc: Self = Self.instantiateViewController(OSCAPressReleasesUI.bundle)
    vc.viewModel = viewModel
    return vc
  }
}
