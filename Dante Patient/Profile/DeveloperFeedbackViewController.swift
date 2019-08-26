//
//  DeveloperFeedbackViewController.swift
//  Dante Patient
//
//  Created by Hung Phan on 8/12/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import WebKit

class DeveloperFeedbackViewController: UIViewController, WKNavigationDelegate {
    
    var webView : WKWebView!
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLScK6smLExGoswnhRcESyUdjdkMThNfL1u4S3Ow0nMoQDHCR1g/viewform")
        webView.load(URLRequest(url: url!))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        change the navigation bar's title to the webview's title
//        title = webView.title
    }
    
    
}
