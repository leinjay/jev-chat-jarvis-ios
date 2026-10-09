import SwiftUI
import Combine

/// 开始页：键盘装没装、完全访问给没给、共享配置通不通，一眼看清。
struct SetupView: View {
    @EnvironmentObject private var store: ConfigStore
    @State private var kbStatus: KeyboardStatus?
    @State private var groupContainerAvailable = false

    private var keyboardStatusRecent: Bool {
        guard let lastSeen = kbStatus?.lastSeen else { return false }
        let age = Date().timeIntervalSince(lastSeen)
        return age >= 0 && age < 120
    }

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            List {
                languageSection
                statusSection
                howSection
                privacySection
            }
            .navigationTitle("Jev Jarvis")
            .onAppear { refresh() }
            .onReceive(timer) { _ in refresh() }
        }
    }

    private func refresh() {
        kbStatus = JevStore.loadKeyboardStatus()
        groupContainerAvailable = JevStore.groupAvailable
    }

    private var languageSection: some View {
        Section(jevLocalized(store.language, zh: "语言", en: "Language")) {
            Picker(jevLocalized(store.language, zh: "界面语言", en: "Interface language"), selection: $store.language) {
                ForEach(JevLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
        }
    }

    // MARK: 状态卡

    private var statusSection: some View {
        Section {
            row(icon: "keyboard", title: jevLocalized(store.language, zh: "键盘状态回写", en: "Keyboard status"),
                ok: keyboardStatusRecent,
                detail: kbStatus.map {
                    jevLocalized(store.language,
                                 zh: "最近写入：\(timeAgo($0.lastSeen))。再次唤起键盘可刷新状态。",
                                 en: "Last write: \(timeAgo($0.lastSeen)). Open the keyboard again to refresh.")
                } ?? jevLocalized(store.language, zh: "尚未收到键盘状态。若键盘已打开，说明当前安装无法跨进程共享。", en: "No keyboard status received. If the keyboard has opened, this installation cannot share data between processes."))

            row(icon: "lock.open", title: jevLocalized(store.language, zh: "允许完全访问", en: "Full Access"),
                ok: keyboardStatusRecent && kbStatus?.hasFullAccess == true,
                detail: !keyboardStatusRecent
                    ? jevLocalized(store.language,
                                   zh: "需要最近的键盘状态：先在任意输入框切到 Jev 键盘唤起一次。",
                                   en: "Recent keyboard status required. Open Jev in any text field first.")
                    : (kbStatus?.hasFullAccess == true
                        ? jevLocalized(store.language, zh: "已开启：键盘可以联网、读剪贴板", en: "On: the keyboard can use the network and clipboard")
                        : jevLocalized(store.language, zh: "未开启：键盘无法联网和读剪贴板，也不会出候选", en: "Off: the keyboard cannot use the network or clipboard")))

            row(icon: "externaldrive.connected.to.line.below", title: jevLocalized(store.language, zh: "App Group 容器", en: "App Group container"),
                ok: groupContainerAvailable, detail: groupContainerAvailable
                    ? jevLocalized(store.language, zh: "主 App 可访问：\(JevStore.appGroupID)。还需确认键盘状态更新。", en: "App access granted: \(JevStore.appGroupID). Confirm that keyboard status updates too.")
                    : jevLocalized(store.language, zh: "当前签名无权访问共享容器：\(JevStore.appGroupID)", en: "The current signature cannot access the shared container: \(JevStore.appGroupID)"))

            row(icon: "arrow.left.arrow.right", title: jevLocalized(store.language, zh: "跨进程共享", en: "Cross-process sharing"),
                ok: groupContainerAvailable && keyboardStatusRecent,
                detail: groupContainerAvailable && keyboardStatusRecent
                    ? jevLocalized(store.language, zh: "已收到键盘最近写入的状态", en: "Recent keyboard status received")
                    : jevLocalized(store.language, zh: "在输入框唤起 Jev 键盘，再回此页查看最近使用是否更新", en: "Open the Jev keyboard in a text field, then return and check whether Last used updates"))
        } header: {
            Text(jevLocalized(store.language, zh: "状态", en: "Status"))
        } footer: {
            Text(jevLocalized(store.language, zh: "键盘每次被唤起时会回写状态，这里每 2 秒刷新。", en: "The keyboard writes its status when opened. This view refreshes every 2 seconds."))
        }
    }

    private func row(icon: String, title: String, ok: Bool, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(ok ? Color.green : Color.orange)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: 步骤

    private var howSection: some View {
        Section(jevLocalized(store.language, zh: "三步启用", en: "Set up in three steps")) {
            step(1, jevLocalized(store.language, zh: "设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → Jev 键盘", en: "Settings → General → Keyboard → Keyboards → Add New Keyboard → Jev Keyboard"))
            step(2, jevLocalized(store.language, zh: "回到「键盘」列表，点 Jev 键盘 → 打开「允许完全访问」", en: "Return to Keyboards, select Jev Keyboard, and turn on Full Access"))
            step(3, jevLocalized(store.language, zh: "去「模型」页填一个 API Key（如智谱 glm-4-flash），然后在聊天 App 中使用：长按消息 → 复制 → 键盘上点「分析剪贴板」", en: "Add an API key on Models (e.g. Zhipu glm-4-flash), then in any chat app long-press a message, copy it, and tap Analyze Clipboard"))
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(String(n))
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))
            Text(text).font(.subheadline)
        }
        .padding(.vertical, 2)
    }

    // MARK: 隐私

    private var privacySection: some View {
        Section(jevLocalized(store.language, zh: "隐私边界", en: "Privacy")) {
            Label(jevLocalized(store.language, zh: "聊天内容只发给你自己配置的模型接口，无自建服务器、不落盘、不进日志", en: "Chat content is sent only to the model endpoint you configure. No server, storage, or logs."), systemImage: "hand.raised")
            Label(jevLocalized(store.language, zh: "Key 存在本机 App Group 私有容器，仅 App 与键盘可读", en: "The key stays in a private App Group container readable only by the app and keyboard."), systemImage: "key")
            Label(jevLocalized(store.language, zh: "候选只「插入」输入框，发送永远由你手动完成", en: "Suggestions are only inserted into the field. You always send manually."), systemImage: "square.and.arrow.down.on.square")
            Label(jevLocalized(store.language, zh: "键盘不监听、不上传按键内容；完全访问可随时在系统设置里关闭或移除键盘", en: "The keyboard does not monitor or upload keystrokes. Full Access can be disabled anytime."), systemImage: "shield")
        }
        .font(.subheadline)
    }

    private func timeAgo(_ d: Date) -> String {
        let s = Date().timeIntervalSince(d)
        if store.language == .english {
            if s < 60 { return "\(Int(s)) sec ago" }
            if s < 3600 { return "\(Int(s / 60)) min ago" }
            return "\(Int(s / 3600)) hr ago"
        }
        if s < 60 { return "\(Int(s)) 秒前" }
        if s < 3600 { return "\(Int(s / 60)) 分钟前" }
        return "\(Int(s / 3600)) 小时前"
    }
}
