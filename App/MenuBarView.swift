import SwiftUI

struct MenuBarView: View {
    let widgetManager: WidgetManager
    let layoutController: LayoutController

    @State private var isEditingLayout = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("桌序 Xulora")

            Divider()

            Button("添加文件整理组件") {
                widgetManager.addFileWidget()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("添加便签") {
                widgetManager.addNoteWidget()
            }

            Button("添加待办") {
                widgetManager.addTodoWidget()
            }

            Button("添加时钟") {
                widgetManager.addClockWidget()
            }

            Button("添加番茄钟") {
                widgetManager.addPomodoroWidget()
            }

            Divider()

            Toggle("编辑布局", isOn: $isEditingLayout)
                .onChange(of: isEditingLayout) { _, newValue in
                    layoutController.setEditingMode(newValue, widgetManager: widgetManager)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

            Toggle("锁定所有组件", isOn: Binding(
                get: { widgetManager.areAllLocked },
                set: { widgetManager.setAllLocked($0) }
            ))

            Toggle("显示所有组件", isOn: Binding(
                get: { widgetManager.areAllVisible },
                set: { widgetManager.setAllVisible($0) }
            ))

            Button("恢复离屏组件") {
                layoutController.recoverOffscreenWidgets()
            }

            Divider()

            Toggle("开机启动", isOn: Binding(
                get: { LoginItemService.shared.isEnabled },
                set: { LoginItemService.shared.setEnabled($0) }
            ))

            Divider()

            Button("关于桌序") {
                NSApp.orderFrontStandardAboutPanel()
            }

            Button("退出桌序") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: 220)
    }
}
