//
//  Actions.swift
//  simple-intelligence
//
//  Created by Wayne Carter on 6/13/24.
//

import UIKit

class Actions {
    static let shared = Actions()
    
    // MARK: - Pay
    
    func pay(for viewController: UIViewController, sourceItem: UIBarButtonItem, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Are you sure you want to clear the cart?", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceItem = sourceItem
        alert.addAction(UIAlertAction(title: "Clear Cart", style: .destructive, handler: { action in
            Database.shared.clearCart()
            completion?()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Info
    
    func showInfo(for viewController: UIViewController, sourceView: UIView) {
        showInfo(for: viewController, sourceView: sourceView, sourceItem: nil)
    }
    
    func showInfo(for viewController: UIViewController, sourceItem: UIBarButtonItem) {
        showInfo(for: viewController, sourceView: nil, sourceItem: sourceItem)
    }
    
    private func showInfo(for viewController: UIViewController, sourceView: UIView?, sourceItem: UIBarButtonItem?) {
        func createOpenURLAction(title: String, urlString: String) -> UIAlertAction {
            return UIAlertAction(title: title, style: .default) { action in
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sourceView
        alert.popoverPresentationController?.sourceItem = sourceItem
        alert.title = "Scan an item with the camera and\nsearch visually using AI"
        alert.addAction(createOpenURLAction(title: "Explore the Code", urlString: "https://github.com/waynecarter/simple-intelligence/blob/main/README.md"))
        alert.addAction(createOpenURLAction(title: "Settings", urlString: UIApplication.openSettingsURLString))
        alert.addAction(createOpenURLAction(title: "Terms of Use", urlString: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"))
        alert.addAction(createOpenURLAction(title: "Privacy Policy", urlString: "https://github.com/waynecarter/simple-intelligence/blob/main/PRIVACY"))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            alert.dismiss(animated: true)
        })
        
        viewController.present(alert, animated: true)
        
    }
    
    // MARK: - Share
    
    func showShare(for viewController: UIViewController, sourceItem: UIBarButtonItem) {
        let appStoreURL =  URL(string: "https://apps.apple.com/us/app/simple-intelligence/id6504311724")!
        let qrCodeActivity = QRCodeActivity(for: viewController, title: "Simple Intelligence", appURL: appStoreURL)
        let activityViewController = UIActivityViewController(activityItems: [appStoreURL], applicationActivities: [qrCodeActivity])
        activityViewController.popoverPresentationController?.sourceItem = sourceItem
        
        // Present the activity from the root view controller
        let rootViewController = viewController.view.window?.rootViewController ?? viewController
        rootViewController.present(activityViewController, animated: true)
    }
    
    private class QRCodeActivity: UIActivity {
        private let viewController: UIViewController
        private let title: String
        private let appURL: URL
        
        init(for viewController: UIViewController, title: String, appURL: URL) {
            self.viewController = viewController
            self.title = title
            self.appURL = appURL
        }
        
        override var activityTitle: String? {
            return "Show QR Code"
        }
        
        override var activityImage: UIImage? {
            return UIImage(systemName: "qrcode")
        }
        
        override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
            return true
        }
        
        override func perform() {
            let qrCodeViewController = QRCodeViewController(title: title, appURL: appURL)
            viewController.present(qrCodeViewController, animated: true, completion: nil)
            
            activityDidFinish(true)
        }
        
        private class QRCodeViewController: UIViewController {
            private let titleString: String
            private let appURL: URL
                
            init(title: String, appURL: URL) {
                self.titleString = title
                self.appURL = appURL
                super.init(nibName: nil, bundle: nil)
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            override func viewDidLoad() {
                super.viewDidLoad()

                self.view.backgroundColor = .systemBackground
                
                // Close button
                let closeButton = UIButton(type: .close, primaryAction: UIAction { action in
                    self.dismiss(animated: true, completion: nil)
                })
                closeButton.tintColor = .systemGray
                closeButton.configuration = {
                    var config = UIButton.Configuration.gray()
                    config.cornerStyle = .capsule
                    return config
                }()
                closeButton.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(closeButton)
                
                // Create an attributed string for the label.
                let instructionsText = "Scan the QR code to get the app"
                let attributedString = NSMutableAttributedString(string: "\(titleString)\n\(instructionsText)")
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: ceil(UIFont.labelFontSize * 1.15), weight: .bold), range: NSRange(location: 0, length: titleString.count))
                        
                // Label
                let label = UILabel()
                label.numberOfLines = 0
                label.textAlignment = .center
                label.attributedText = attributedString
                label.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(label)
                
                // Image container for shadow and corner radius.
                let imageContainerView = UIView()
                imageContainerView.backgroundColor = .white
                imageContainerView.layer.cornerRadius = 10
                imageContainerView.layer.shadowColor = UIColor.black.cgColor
                imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
                imageContainerView.layer.shadowOpacity = 0.4
                imageContainerView.layer.shadowRadius = 5
                imageContainerView.layer.masksToBounds = false
                imageContainerView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(imageContainerView)

                // Image
                let imageView = UIImageView(image: {
                    // Create the QR code image.
                    let data = appURL.dataRepresentation
                    if let filter = CIFilter(name: "CIQRCodeGenerator") {
                        filter.setValue(data, forKey: "inputMessage")
                        let transform = CGAffineTransform(scaleX: 10, y: 10)

                        if let output = filter.outputImage?.transformed(by: transform) {
                            return UIImage(ciImage: output.transformed(by: transform))
                        }
                    }
                    return nil
                }())
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageContainerView.addSubview(imageView)

                // Set up layout constraints with a margin.
                NSLayoutConstraint.activate([
                    // Close
                    closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),
                    closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
                    closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

                    // Label
                    label.bottomAnchor.constraint(equalTo: imageContainerView.topAnchor, constant: -20),
                    label.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),

                    // Image Container
                    imageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                    imageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
                    imageContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    imageContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    imageContainerView.heightAnchor.constraint(equalTo: imageContainerView.widthAnchor),

                    // Image
                    imageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor, constant: 10),
                    imageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: -10),
                    imageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor, constant: 10),
                    imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: -10)
                ])
            }
        }
    }
}
