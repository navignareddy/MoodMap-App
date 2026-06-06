import SwiftUI
import UIKit

private func configureBar(_ bar: UINavigationBar) {
    let white = UIColor.white
    let bg    = UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1)
    let tint  = UIColor(red: 129/255, green: 140/255, blue: 248/255, alpha: 1)

    let opaque = UINavigationBarAppearance()
    opaque.configureWithOpaqueBackground()
    opaque.backgroundColor          = bg
    opaque.titleTextAttributes      = [.foregroundColor: white]
    opaque.largeTitleTextAttributes = [.foregroundColor: white]

    let edge = UINavigationBarAppearance()
    edge.configureWithTransparentBackground()
    edge.backgroundColor          = bg
    edge.titleTextAttributes      = [.foregroundColor: white]
    edge.largeTitleTextAttributes = [.foregroundColor: white]

    bar.standardAppearance   = opaque
    bar.compactAppearance    = opaque
    bar.scrollEdgeAppearance = edge
    bar.tintColor            = tint
    bar.setNeedsLayout()
    bar.layoutIfNeeded()
}

private func fixAllNavBars(in vc: UIViewController) {
    if let nav = vc as? UINavigationController {
        configureBar(nav.navigationBar)
    }
    for child in vc.children {
        fixAllNavBars(in: child)
    }
    if let presented = vc.presentedViewController {
        fixAllNavBars(in: presented)
    }
}

class AppearanceFixVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fix()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fix()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.fix() }
    }
    private func fix() {
        guard let root = view.window?.rootViewController else { return }
        fixAllNavBars(in: root)
    }
}

struct AppearanceFix: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AppearanceFixVC { AppearanceFixVC() }
    func updateUIViewController(_ vc: AppearanceFixVC, context: Context) {}
}

extension View {
    func fixNavBarAppearance() -> some View {
        self.background(AppearanceFix().frame(width: 0, height: 0))
    }
}
