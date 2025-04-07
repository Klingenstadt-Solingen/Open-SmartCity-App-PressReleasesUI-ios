//
//  OSCAPressReleasesMainCollectionViewCell.swift
//  OSCAPressReleasesUI
//
//  Created by Mammut Nithammer on 19.01.22.
//

import OSCAEssentials
import UIKit
import Combine

public final class OSCAPressReleasesMainCollectionViewCell: UICollectionViewCell {
  public static let identifier = String(describing: OSCAPressReleasesMainCollectionViewCell.self)
  
  @IBOutlet public var contenStackView: UIStackView!
  @IBOutlet public var imageView: UIImageView!
  @IBOutlet public var categoryLabel: UILabel!
  @IBOutlet public var titleLabel: UILabel!
  @IBOutlet public var timeIconImageView: UIImageView!
  @IBOutlet public var contentInfoLabel: UILabel!
  
  private var bindings = Set<AnyCancellable>()
  private var viewModel: OSCAPressReleasesMainCellViewModel!
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    let shadow = OSCAPressReleasesUI.configuration
      .shadowSettings
    self.addShadow(with: shadow)
    
    self.contentView.backgroundColor = OSCAPressReleasesUI.configuration
      .colorConfig.secondaryBackgroundColor
    self.contentView.layer.cornerRadius = OSCAPressReleasesUI.configuration
      .cornerRadius
    self.contentView.layer.masksToBounds = true
    
    self.contenStackView.spacing = 8
    
    self.imageView.isHidden = !OSCAPressReleasesUI.configuration.showImage
    self.imageView.contentMode = .scaleAspectFit
    self.imageView.layer.cornerRadius = OSCAPressReleasesUI.configuration.cornerRadius / 2
    self.imageView.layer.masksToBounds = true
    
    self.timeIconImageView.image = UIImage(systemName: "clock")
    self.timeIconImageView.isHidden = !OSCAPressReleasesUI.configuration
      .showReadingTime
    self.timeIconImageView.tintColor = OSCAPressReleasesUI.configuration
      .detailTextColor
    
    self.categoryLabel.font = OSCAPressReleasesUI.configuration
      .fontConfig.smallLight
    self.titleLabel.font = OSCAPressReleasesUI.configuration
      .fontConfig.captionHeavy
    self.contentInfoLabel.font = OSCAPressReleasesUI.configuration
      .fontConfig.smallLight
    
    self.categoryLabel.textColor = OSCAPressReleasesUI.configuration
      .detailTextColor
    self.titleLabel.textColor = OSCAPressReleasesUI.configuration
      .colorConfig.textColor
    self.contentInfoLabel.textColor = OSCAPressReleasesUI.configuration
      .detailTextColor
    
    self.categoryLabel.numberOfLines = 1
    self.titleLabel.numberOfLines = 2
    self.contentInfoLabel.numberOfLines = 1
    
    self.titleLabel.lineBreakMode = .byTruncatingTail
    self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.bounds.width
    let titleLabelMaxHeight = self.titleLabel.font.lineHeight * CGFloat(self.titleLabel.numberOfLines)
    self.titleLabel.heightAnchor.constraint(equalToConstant: titleLabelMaxHeight).isActive = true
  }
  
  public func fill(with viewModel: OSCAPressReleasesMainCellViewModel) {
    self.viewModel = viewModel
    
    if let imageData = viewModel.imageDataFromCache {
      self.imageView.image = UIImage(data: imageData)
      self.imageView.contentMode = .scaleAspectFill
      
    } else if let placeholderImage = OSCAPressReleasesUI.configuration.placeholderImage {
      self.imageView.image = placeholderImage.image
      self.imageView.tintColor = placeholderImage.color
      self.imageView.contentMode = .scaleAspectFit
    }
    
    self.categoryLabel.attributedText = NSAttributedString(string: viewModel.category)
    self.titleLabel.attributedText = NSAttributedString(string: viewModel.title)
    self.contentInfoLabel.attributedText = NSAttributedString(string: viewModel.contentInfo)
    
    self.categoryLabel.hyphenate(alignment: .left)
    self.titleLabel.hyphenate(alignment: .left)
    self.contentInfoLabel.hyphenate(alignment: .left)
    
    self.titleLabel.updateLineBreakMode(lineBreakMode: .byTruncatingTail)
    
    self.setupBindings()
    viewModel.fill()
  }
  
  private func setupBindings() {
    self.viewModel.$imageData
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] imageData in
        guard let `self` = self,
              let imageData = imageData
        else { return }
        
        self.imageView.image = UIImage(data: imageData)
        self.imageView.contentMode = .scaleAspectFill
      })
      .store(in: &self.bindings)
  }
}

private extension UILabel {
  func updateLineBreakMode(lineBreakMode: NSLineBreakMode) {
    guard let attributedText = self.attributedText?.mutableCopy() as? NSMutableAttributedString else { return }
    
    attributedText.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attributedText.length), options: []) { value, range, _ in
      if let currentParagraphStyle = value as? NSParagraphStyle,
         let updatedParagraphStyle = currentParagraphStyle.mutableCopy() as? NSMutableParagraphStyle {
        updatedParagraphStyle.lineBreakMode = lineBreakMode
        attributedText.addAttribute(.paragraphStyle, value: updatedParagraphStyle, range: range)
      }
    }
    
    self.attributedText = attributedText
  }
}
