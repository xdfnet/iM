//
//  MainSplitViewController.swift
//  iM
//

import Cocoa

@MainActor
final class MainSplitViewController: NSViewController {

    private let contentViewController = ContentViewController()

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(contentViewController)
        let contentView = contentViewController.view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func display(markdown: String, fileName: String, url: URL?, assetBaseURL: URL?) {
        contentViewController.display(markdown: markdown, assetBaseURL: assetBaseURL)
    }

    func clearContent() {
        contentViewController.clearContent()
    }

}
