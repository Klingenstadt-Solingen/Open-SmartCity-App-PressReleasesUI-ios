//
//  OSCAPressReleasesDetailViewController.swift
//  OSCAPressReleasesUI
//
//  Created by Mammut Nithammer on 19.01.22.
//

import OSCAEssentials
import UIKit
import Combine

public final class OSCAPressReleasesDetailViewController: UIViewController, Alertable {
  
  @IBOutlet private var categoryLabel: UILabel!
  @IBOutlet private var contentInfoStackView: UIStackView!
  @IBOutlet private var titleLabel: UILabel!
  @IBOutlet private var shareButton: UIButton!
  @IBOutlet private var seperatorLineView: UIView!
  @IBOutlet private var seperatorLineViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet private var scrollView: UIScrollView!
  @IBOutlet private var scrollStackView: UIStackView!
  @IBOutlet private var imageView: UIImageView!
  @IBOutlet private var imageViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet private var timeIconImageView: UIImageView!
  @IBOutlet private var contentInfoLabel: UILabel!
  @IBOutlet private var contentTextView: UITextView!
  @IBOutlet private var linkStackView: UIStackView!
  @IBOutlet private var linkImageView: UIImageView!
  @IBOutlet private var linkButton: UIButton!
  
  private var viewModel: OSCAPressReleasesDetailViewModel!
  private var bindings = Set<AnyCancellable>()
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.setupBindings()
    self.viewModel.viewDidLoad()
  }
  
  private func setupViews() {
    view.backgroundColor = OSCAPressReleasesUI.configuration.colorConfig.backgroundColor
    
    scrollView.delegate = self
    
    categoryLabel.text = viewModel.category
    categoryLabel.font = OSCAPressReleasesUI.configuration.fontConfig.bodyLight
    categoryLabel.textColor = OSCAPressReleasesUI.configuration.detailTextColor
    categoryLabel.numberOfLines = 1
    
    contentInfoStackView.axis = .horizontal
    contentInfoStackView.spacing = 5
    
    titleLabel.text = viewModel.title
    titleLabel.font = OSCAPressReleasesUI.configuration.fontConfig.subheaderHeavy
    titleLabel.textColor = OSCAPressReleasesUI.configuration.colorConfig.textColor
    titleLabel.numberOfLines = 2
    
    let image = UIImage(systemName: "square.and.arrow.up")
    image?.withRenderingMode(.alwaysTemplate)
    shareButton.setImage(image, for: .normal)
    shareButton.tintColor = OSCAPressReleasesUI.configuration.colorConfig.primaryColor
    
    seperatorLineView.isHidden = true
    seperatorLineView.backgroundColor = OSCAPressReleasesUI.configuration.colorConfig.grayDarker
    seperatorLineViewHeightConstraint.constant = 0.5
    
    scrollView.showsHorizontalScrollIndicator = false
    
    if let imageData = self.viewModel.imageDataFromCache {
      imageView.image = UIImage(data: imageData)
      imageView.layoutIfNeeded()
      adjustImageViewHeight()
      
    } else if let placeholderImage = OSCAPressReleasesUI.configuration.placeholderImage {
      imageView.image = placeholderImage.image
      imageView.tintColor = placeholderImage.color
    }
    imageView.isHidden = !OSCAPressReleasesUI.configuration.showImage
    imageView.contentMode = .scaleAspectFit
    imageView.layer.cornerRadius = OSCAPressReleasesUI.configuration.cornerRadius
    imageView.layer.masksToBounds = true
    
    scrollStackView.axis = .vertical
    scrollStackView.spacing = 8
    
    timeIconImageView.isHidden = !OSCAPressReleasesUI.configuration.showReadingTime
    timeIconImageView.image = UIImage(systemName: "clock")
    timeIconImageView.tintColor = OSCAPressReleasesUI.configuration.detailTextColor
    
    contentInfoLabel.text = viewModel.contentInfo
    contentInfoLabel.font = OSCAPressReleasesUI.configuration.fontConfig.bodyLight
    contentInfoLabel.textColor = OSCAPressReleasesUI.configuration.detailTextColor
    contentInfoLabel.numberOfLines = 1
    
    var attributedString: NSMutableAttributedString? = nil
    do {
      let size = OSCAPressReleasesUI.configuration.fontConfig.bodyLight.pointSize
      let fontSize = "\(size)"
      let css = "<style> body {font-stretch: normal; font-size: \(fontSize)px; line-height: normal; font-family: 'Helvetica Neue'} </style>"
      let htmlString = "\(css)\(self.viewModel.content)"
      attributedString = try NSMutableAttributedString(HTMLString: htmlString)
    } catch {
      print(error)
    }
    contentTextView.attributedText = attributedString
    contentTextView.font = OSCAPressReleasesUI.configuration.fontConfig.bodyLight
    contentTextView.textColor = OSCAPressReleasesUI.configuration.colorConfig.textColor
    contentTextView.tintColor = OSCAPressReleasesUI.configuration.colorConfig.primaryColor
    contentTextView.backgroundColor = .clear
    contentTextView.isEditable = false
    contentTextView.isScrollEnabled = false
    
    linkStackView.axis = .horizontal
    linkStackView.spacing = 8
    
    let linkImage = UIImage(systemName: "globe")
    linkImageView.image = linkImage
    linkImageView.tintColor = OSCAPressReleasesUI.configuration.colorConfig.grayDark
    
    linkButton.setTitle(viewModel.url, for: .normal)
    linkButton.titleLabel?.font = OSCAPressReleasesUI.configuration.fontConfig.bodyLight
    linkButton.setTitleColor(
      OSCAPressReleasesUI.configuration.colorConfig.primaryColor,
      for: .normal)
    linkButton.contentHorizontalAlignment = .leading
  }
  
  private func setupBindings() {
    self.viewModel.$imageData
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] imageData in
        guard let `self` = self,
              let imageData = imageData
        else { return }
        
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.image = UIImage(data: imageData)
      })
      .store(in: &self.bindings)
  }
  
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if self.viewModel.imageData != nil {
      self.adjustImageViewHeight()
    }
  }
  
  @IBAction private func shareTouch(_ sender: UIButton) {
    var items: [Any] = viewModel.shareContent
    if !items.isEmpty {
      self.showActivity(activityItems: items)
    }// end if
  }// end @IBAction private func shareTouch
  
  @IBAction func linkButtonTouch(_ sender: UIButton) {
    guard let url = URL(string: viewModel.url) else { return }
    if UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:])
    }
  }
  
  private func adjustImageViewHeight() {
    guard let image = imageView.image else { return }
    let aspectRatio = image.size.height / image.size.width
    imageViewHeightConstraint.constant = imageView.frame.width * (aspectRatio)
  }
}

// MARK: - instantiate view conroller
extension OSCAPressReleasesDetailViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAPressReleasesDetailViewController.create(viewModel)
  public static func create(with viewModel: OSCAPressReleasesDetailViewModel) -> OSCAPressReleasesDetailViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let vc: Self = Self.instantiateViewController(OSCAPressReleasesUI.bundle)
    vc.viewModel = viewModel
    return vc
  }
}

extension OSCAPressReleasesDetailViewController: UIScrollViewDelegate {
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    seperatorLineView.isHidden = scrollView.contentOffset.y > 0
    ? false
    : true
  }
}

extension Alertable where Self == OSCAPressReleasesDetailViewController {
  func showActivity(activityItems: [Any],
                    applicationActivities: [UIActivity]? = nil) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    var excludedActivities: [UIActivity.ActivityType] = [.airDrop,
                                                         .assignToContact,
                                                         .openInIBooks,
                                                         .saveToCameraRoll,
                                                         .addToReadingList]
    if #available(iOS 15.4, *) {
      excludedActivities.append(.sharePlay)
    }// end if
    if #available(iOS 16.0, *) {
      excludedActivities.append(.collaborationInviteWithLink)
      excludedActivities.append(.collaborationCopyLink)
    }// end if
    if #available(iOS 16.4, *) {
      excludedActivities.append(.addToHomeScreen)
    }// end if
    let activityViewController = UIActivityViewController(activityItems: activityItems,
                                                          applicationActivities: applicationActivities)
    activityViewController.excludedActivityTypes = excludedActivities
    
    activityViewController.popoverPresentationController?.sourceView = self.view
    let rect = CGRect(origin: .zero,
                      size: CGSize(width: self.view.bounds.width / 2,
                                   height: self.view.frame.height / 2))
    activityViewController.popoverPresentationController?.sourceRect = rect
    
    self.present(activityViewController,
                 animated: true) {
#if DEBUG
      print("\(String(describing: self)): \(#function): completion closure")
#endif
    }// end completion closure
  }// end func showActivity
}// end extension Alertable
