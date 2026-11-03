import UIKit

final class KeyboardViewController: UIInputViewController {
    private let store = UserDefaults(suiteName: "group.app.misg.keyboard")
    private var thaiMode = false
    private var symbolsMode = false
    private var shiftOn = false
    private var showingClips = false
    private var keys: [[String]] {
        if symbolsMode {
            return [["1","2","3","4","5","6","7","8","9","0"],["@","#","$","&","-","+","(",")","/"],["=","%","*","\"","'",":",";","!","?" ]]
        }
        if thaiMode {
            return [["ๆ","ไ","ำ","พ","ะ","ั","ี","ร","น","ย"],["บ","ล","ห","ก","ด","เ","้","่","า"],["ผ","ป","แ","อ","ิ","ื","ท","ม","ใ","ฝ"]]
        }
        return [["q","w","e","r","t","y","u","i","o","p"],["a","s","d","f","g","h","j","k","l"],["z","x","c","v","b","n","m"]]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondarySystemBackground
        buildKeyboard()
    }

    private func buildKeyboard() {
        view.subviews.forEach { $0.removeFromSuperview() }
        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

        let top = UIStackView()
        top.axis = .horizontal
        top.spacing = 6
        let clipsButton = makeButton(showingClips ? "ABC" : "▤", action: #selector(toggleClips))
        let languageButton = makeButton(thaiMode ? "TH" : "EN", action: #selector(switchLanguage))
        let symbolButton = makeButton(symbolsMode ? "ABC" : "123", action: #selector(switchSymbols))
        top.addArrangedSubview(clipsButton)
        top.addArrangedSubview(languageButton)
        top.addArrangedSubview(symbolButton)
        top.addArrangedSubview(UIView())
        root.addArrangedSubview(top)

        if showingClips {
            let scroll = UIScrollView()
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 6
            stack.translatesAutoresizingMaskIntoConstraints = false
            scroll.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
                stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
                stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
                stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
            ])
            let clips = loadClips()
            if clips.isEmpty {
                let empty = UILabel()
                empty.text = "No saved clips yet — add some in Misg Keyboard"
                empty.textAlignment = .center
                empty.textColor = .secondaryLabel
                stack.addArrangedSubview(empty)
            }
            for clip in clips {
                let button = makeButton((clip.pinned ? "📌 " : "") + clip.text, action: #selector(insertClip(_:)))
                button.accessibilityHint = clip.text
                button.titleLabel?.lineBreakMode = .byTruncatingTail
                stack.addArrangedSubview(button)
            }
            root.addArrangedSubview(scroll)
        } else {
            for row in keys {
                let line = UIStackView()
                line.axis = .horizontal
                line.spacing = 4
                line.distribution = .fillEqually
                for key in row {
                    let value = shiftOn && !thaiMode ? key.uppercased() : key
                    let button = makeButton(value, action: #selector(typeKey(_:)))
                    button.accessibilityHint = key
                    line.addArrangedSubview(button)
                }
                root.addArrangedSubview(line)
            }
            let bottom = UIStackView()
            bottom.axis = .horizontal
            bottom.spacing = 5
            bottom.distribution = .fillEqually
            bottom.addArrangedSubview(makeButton("⇧", action: #selector(toggleShift)))
            bottom.addArrangedSubview(makeButton("🌐", action: #selector(nextKeyboard)))
            bottom.addArrangedSubview(makeButton("space", action: #selector(spaceKey)))
            bottom.addArrangedSubview(makeButton("⌫", action: #selector(backspace)))
            bottom.addArrangedSubview(makeButton("return", action: #selector(returnKey)))
            root.addArrangedSubview(bottom)
        }
    }

    private func makeButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: title.count > 8 ? 13 : 17, weight: .medium)
        button.titleLabel?.numberOfLines = 1
        button.backgroundColor = .tertiarySystemBackground
        button.layer.cornerRadius = 7
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 38).isActive = true
        return button
    }

    private func loadClips() -> [(text: String, pinned: Bool)] {
        guard let data = store?.data(forKey: "savedClips"),
              let values = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return values.compactMap {
            guard let text = $0["text"] as? String else { return nil }
            return (text, $0["pinned"] as? Bool ?? false)
        }.sorted { $0.pinned && !$1.pinned }
    }

    @objc private func typeKey(_ sender: UIButton) {
        guard let value = sender.accessibilityHint else { return }
        textDocumentProxy.insertText(shiftOn && !thaiMode ? value.uppercased() : value)
        if shiftOn { shiftOn = false; buildKeyboard() }
    }

    @objc private func insertClip(_ sender: UIButton) {
        guard let text = sender.accessibilityHint else { return }
        textDocumentProxy.insertText(text)
    }

    @objc private func toggleClips() { showingClips.toggle(); buildKeyboard() }
    @objc private func switchLanguage() { thaiMode.toggle(); symbolsMode = false; buildKeyboard() }
    @objc private func switchSymbols() { symbolsMode.toggle(); buildKeyboard() }
    @objc private func toggleShift() { shiftOn.toggle(); buildKeyboard() }
    @objc private func nextKeyboard() { advanceToNextInputMode() }
    @objc private func spaceKey() { textDocumentProxy.insertText(" ") }
    @objc private func returnKey() { textDocumentProxy.insertText("\n") }
    @objc private func backspace() { textDocumentProxy.deleteBackward() }
}
