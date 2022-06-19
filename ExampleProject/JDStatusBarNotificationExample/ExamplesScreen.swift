//
//

import Foundation
import SwiftUI

@available(iOS 15.0, *)
class ExamplesScreenFactory: NSObject {
  @objc static func createExamplesScreen() -> UIViewController {
    let text = "👋 Hello World!"
    NotificationPresenter.shared().present(text: text,
                                           dismissAfterDelay: 2.5,
                                           includedStyle: IncludedStatusBarStyle.matrix)
    return UIHostingController(rootView:
      NavigationView {
        ExamplesScreen()
      }
    )
  }
}

@available(iOS 15.0, *)
struct ExamplesScreen: View {
  enum ExampleStyle: String, RawRepresentable, CaseIterable {
    case custom1
    case custom2
    case custom3
    case icon
  }

  @State var progress = 0.0
  @State var showActivity = false
  @State var showSubtitle = false
  @State var backgroundType: BarBackgroundType = .pill

  func showDefaultNotification(_ text: String, completion: @escaping (NotificationPresenter) -> ()) {
    let styleName = NotificationPresenter.shared().addStyle(styleName: "tmp", basedOnIncludedStyle: .defaultStyle) { style in
      style.backgroundStyle.backgroundType = backgroundType
      return style
    }
    NotificationPresenter.shared().present(title: text,
                                           subtitle: showSubtitle ? "{subtitle}" : nil,
                                           customStyle: styleName,
                                           completion: completion)

    if showActivity {
      NotificationPresenter.shared().displayActivityIndicator(true)
    }
    if progress > 0.0 {
      NotificationPresenter.shared().displayProgressBar(percentage: progress)
    }
  }

  func showIncludedStyle(_ text: String, style: IncludedStatusBarStyle) {
    let styleName = NotificationPresenter.shared().addStyle(styleName: "tmp", basedOnIncludedStyle: style) { style in
      style.backgroundStyle.backgroundType = backgroundType
      return style
    }
    NotificationPresenter.shared().present(title: text,
                                           subtitle: showSubtitle ? "{subtitle}" : nil,
                                           customStyle: styleName)
    NotificationPresenter.shared().dismiss(afterDelay: 3.0)

    if showActivity {
      NotificationPresenter.shared().displayActivityIndicator(true)
    }
    if progress > 0.0 {
      NotificationPresenter.shared().displayProgressBar(percentage: progress)
    }
  }

  var body: some View {
    List {
      Section {
        NavigationLink {
          StyleEditorScreen()
        } label: {
          VStack(alignment: .leading) {
            Text("Style Editor")
              .font(.subheadline)
              .foregroundColor(.accentColor)
            Text("Get creative & create your own style!")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }.foregroundColor(.accentColor)
      }

      Section("Default Style") {
        cell(title: "Present / dismiss", subtitle: "Default style, don't autohide", useAccentColor: true) {
          if NotificationPresenter.shared().isVisible() {
            NotificationPresenter.shared().dismiss()
          } else {
            showDefaultNotification("Better call Saul!") { _ in }
          }
        }
        cell(title: "Animate progress bar & hide", subtitle: "Hide bar at 100%", useAccentColor: true) {
          if !NotificationPresenter.shared().isVisible() {
            showDefaultNotification("Animating Progress…") { presenter in
              presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
                presenter.dismiss()
              }
            }
            NotificationPresenter.shared().displayProgressBar(percentage: 0.0)
          } else {
            NotificationPresenter.shared().displayProgressBar(percentage: 0.0)
            NotificationPresenter.shared().animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }
      }

      Section("Settings") {
        Toggle("Show subtitle", isOn: $showSubtitle)
          .onChange(of: showSubtitle) { on in
            if on, !NotificationPresenter.shared().isVisible() {
              showDefaultNotification("Look!") { _ in }
              NotificationPresenter.shared().dismiss(afterDelay: 2.0)
            }
            NotificationPresenter.shared().updateSubtitle(on ? "I am a subtitle" : nil)
          }.font(.subheadline)

        Toggle("Activity Indicator", isOn: $showActivity)
          .onChange(of: showActivity) { _ in
            if !NotificationPresenter.shared().isVisible() {
              if showActivity {
                let styleName = NotificationPresenter.shared().addStyle(styleName: "tmp", basedOnIncludedStyle: .defaultStyle) { style in
                  style.backgroundStyle.backgroundType = backgroundType
                  style.backgroundStyle.pillStyle.minimumWidth = 0.0
                  return style
                }
                NotificationPresenter.shared().present(text: "", dismissAfterDelay: 2.0, customStyle: styleName)
                NotificationPresenter.shared().displayActivityIndicator(true)
              }
            } else {
              NotificationPresenter.shared().displayActivityIndicator(showActivity)
            }
          }.font(.subheadline)

        HStack {
          Text("Progress Bar (\(Int(round(progress * 100)))%)")
          Spacer()
          Slider(value: $progress)
            .frame(width: 150)
        }
        .onChange(of: progress) { _ in
          if !NotificationPresenter.shared().isVisible() {
            if progress > 0.0 {
              showDefaultNotification("Making progress…") { _ in }
              NotificationPresenter.shared().dismiss(afterDelay: 2.0)
            }
          } else {
            NotificationPresenter.shared().displayProgressBar(percentage: progress)
          }
        }.font(.subheadline)

        VStack(alignment: .leading, spacing: 6.0) {
          Text("BarBackgroundType").font(.subheadline)
          Picker("", selection: $backgroundType) {
            EnumPickerOptionView(BarBackgroundType.pill)
            EnumPickerOptionView(BarBackgroundType.fullWidth)
          }.font(.subheadline).pickerStyle(.segmented)
        }
        .onChange(of: backgroundType) { _ in
          showDefaultNotification(backgroundType == .pill ? "Ohhh so shiny!" : "I prefer classic…") { _ in }
          NotificationPresenter.shared().dismiss(afterDelay: 2.0)
        }
      }

      Section("Included Styles") {
        includedStyleCell("Uh huh.", style: .defaultStyle)
        includedStyleCell("It's time.", style: .light)
        includedStyleCell("Don't mess with me!", style: .dark)
        includedStyleCell("That's how we roll!", style: .success)
        includedStyleCell("You know who I am!", style: .warning)
        includedStyleCell("Uh oh, that didn't work..", style: .error)
        includedStyleCell("Wake up Neo…", style: .matrix)
      }

      Section("Custom Styles") {
        cell(title: "Present custom style \"Love it!\"", subtitle: "AnimationType.fade + Progress") {
          setupCustomStyles()
          NotificationPresenter.shared().present(text: "Love it!",
                                                 customStyle: ExampleStyle.custom1.rawValue) { presenter in
            presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }

        cell(title: "Present custom style \"Level Up\"", subtitle: "AnimationType.bounce + Progress") {
          setupCustomStyles()
          NotificationPresenter.shared().present(text: "Level up!",
                                                 customStyle: ExampleStyle.custom2.rawValue) { presenter in
            presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }

        cell(title: "Present custom style \"Looks good\"", subtitle: "Subtitle + Progress") {
          setupCustomStyles()
          NotificationPresenter.shared().present(title: "Damn",
                                                 subtitle: "This looks gooood!",
                                                 customStyle: ExampleStyle.custom3.rawValue) { presenter in
            presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }

        cell(title: "2 notifications in sequence", subtitle: "Utilizing the completion block") {
          showIncludedStyle("This is 1/2!", style: .dark)
          NotificationPresenter.shared().displayActivityIndicator(true)
          NotificationPresenter.shared().displayProgressBar(percentage: 0.0)
          NotificationPresenter.shared().dismiss(afterDelay: 1.0) { presenter in
            showIncludedStyle("✅ This is 2/2!", style: .dark)
            NotificationPresenter.shared().displayActivityIndicator(false)
            NotificationPresenter.shared().displayProgressBar(percentage: 0.0)
            presenter.dismiss(afterDelay: 1.0)
          }
        }
      }

      Section("Custom Views") {
        cell(title: "Present a button", subtitle: "A custom notification view") {
          // create button
          let button = UIButton(type: .system, primaryAction: UIAction { _ in
            NotificationPresenter.shared().dismiss()
          })
          button.setTitle("Dismiss!", for: .normal)

          // present
          let styleName = NotificationPresenter.shared().addStyle(styleName: "tmp", basedOnIncludedStyle: .defaultStyle) { style in
            style.backgroundStyle.backgroundType = backgroundType
            return style
          }
          NotificationPresenter.shared().present(customView: button, style: styleName)
        }

        cell(title: "Present with icon", subtitle: "A custom left view") {
          // create icon
          let image = UIImageView(image: UIImage(systemName: "gamecontroller.fill"))
          image.tintColor = UIColor.orange
          image.sizeToFit()

          // present
          setupCustomStyles()
          NotificationPresenter.shared().present(title: "Player II", subtitle: "Connected", customStyle: ExampleStyle.icon.rawValue)
          NotificationPresenter.shared().displayLeftView(image)
          NotificationPresenter.shared().dismiss(afterDelay: 2.5)
        }
      }
    }
    .navigationTitle(Bundle.main.object(forInfoDictionaryKey: "ExampleViewControllerTitle") as? String ?? "")
    .navigationBarTitleDisplayMode(.inline)
  }

  func cell(title: String, subtitle: String? = nil, useAccentColor: Bool = false, action: @escaping () -> ()) -> some View {
    Button(action: action, label: {
      HStack {
        VStack(alignment: .leading) {
          Text(title)
            .font(.subheadline)
            .foregroundColor(useAccentColor ? .accentColor : .primary)
          if let subtitle = subtitle {
            Text(subtitle)
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
          Spacer()
          NavigationLink.empty
            .frame(width: 30.0)
            .foregroundColor(useAccentColor ? .accentColor : .secondary)
      }
    })
  }

  func includedStyleCell(_ text: String, style: IncludedStatusBarStyle) -> some View {
    cell(title: "Present \(style.stringValue)", subtitle: "Duration: 3s") {
      showIncludedStyle(text, style: style)
    }
  }

  func setupCustomStyles() {
    NotificationPresenter.shared().addStyle(styleName: ExampleStyle.custom1.rawValue) { style in
      style.backgroundStyle.backgroundColor = UIColor(red: 0.797, green: 0.0, blue: 0.662, alpha: 1.0)
      style.backgroundStyle.backgroundType = backgroundType
      style.textStyle.textColor = .white
      style.animationType = .fade
      style.textStyle.font = UIFont(name: "SnellRoundhand-Bold", size: 20.0)!
      style.progressBarStyle.barColor = UIColor(red: 0.986, green: 0.062, blue: 0.598, alpha: 1.0)
      style.progressBarStyle.barHeight = 400.0
      style.progressBarStyle.cornerRadius = 0.0
      style.progressBarStyle.horizontalInsets = 0.0
      style.progressBarStyle.offsetY = 0.0
      return style
    }

    NotificationPresenter.shared().addStyle(styleName: ExampleStyle.custom2.rawValue) { style in
      style.backgroundStyle.backgroundColor = .cyan
      style.backgroundStyle.backgroundType = backgroundType
      style.textStyle.textColor = UIColor(red: 0.056, green: 0.478, blue: 0.998, alpha: 1.0)
      style.textStyle.textOffsetY = 3.0
      style.animationType = .bounce
      style.textStyle.font = UIFont(name: "DINCondensed-Bold", size: 17.0)!
      style.progressBarStyle.barColor = UIColor(white: 1.0, alpha: 0.66)
      style.progressBarStyle.barHeight = 6.0
      style.progressBarStyle.cornerRadius = 3.0
      style.progressBarStyle.horizontalInsets = 20.0
      style.progressBarStyle.position = .center
      style.progressBarStyle.offsetY = -2.0
      return style
    }

    NotificationPresenter.shared().addStyle(styleName: ExampleStyle.custom3.rawValue) { style in
      style.backgroundStyle.backgroundColor = UIColor(red: 0.9999999403953552, green: 0.3843138813972473, blue: 0.31372547149658203, alpha: 1.0) // "red"
      style.backgroundStyle.backgroundType = backgroundType
      style.textStyle.textColor = UIColor(red: 0.9999999403953552, green: 1.0000001192092896, blue: 1.0000001192092896, alpha: 1.0) // "white"
      style.textStyle.font = UIFont(name: "Noteworthy", size: 13.0)!
      style.textStyle.textOffsetY = 2.0
      style.subtitleStyle.textColor = UIColor(red: 0.48235297203063965, green: 0.16078439354896545, blue: -6.016343867543128e-09, alpha: 1.0) // "dark red orange"
      style.subtitleStyle.font = UIFont(name: "Noteworthy", size: 14.0)!
      style.subtitleStyle.textOffsetY = -6.0
      style.systemStatusBarStyle = .darkContent
      style.progressBarStyle.barHeight = 4.0
      style.progressBarStyle.barColor = UIColor(red: 0.8194038271903992, green: 6.258426310523646e-07, blue: 0.003213257063180208, alpha: 1.0) // "dark red"
      style.progressBarStyle.horizontalInsets = 0.0
      style.progressBarStyle.cornerRadius = 2.0
      style.progressBarStyle.offsetY = 0.0

      return style
    }

    NotificationPresenter.shared().addStyle(styleName: ExampleStyle.icon.rawValue, prepare: { style in
      style.backgroundStyle.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
      style.backgroundStyle.backgroundType = backgroundType
      style.backgroundStyle.pillStyle.minimumWidth = 200.0
      style.backgroundStyle.pillStyle.height = 50.0
      style.systemStatusBarStyle = .lightContent

      switch backgroundType {
        case .pill:
          style.leftViewStyle.alignment = .left
          style.leftViewStyle.spacing = 10.0
          style.leftViewStyle.offsetX = -8.0
        default:
          style.leftViewStyle.spacing = 10.0
          style.leftViewStyle.alignment = .centerWithText
      }

      style.textStyle.textColor = UIColor.white
      style.textStyle.font = UIFont.boldSystemFont(ofSize: 13.0)
      style.textStyle.textOffsetY = 1

      style.subtitleStyle.textColor = UIColor.lightGray
      style.subtitleStyle.font = UIFont.systemFont(ofSize: 12.0)
      return style
    })
  }

  func animationDurationForCurrentStyle() -> Double {
    switch backgroundType {
      case .pill:
        return 0.66
      case .fullWidth:
        fallthrough
      default:
        return 1.2
    }
  }
}

extension NavigationLink where Label == EmptyView, Destination == EmptyView {
  static var empty: NavigationLink {
    self.init(destination: EmptyView(), label: { EmptyView() })
  }
}

@available(iOS 15.0, *)
struct ExamplesScreen_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      ExamplesScreen()
    }
  }
}