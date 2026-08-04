# 桌序 · Xulora

> 让一切各归其位。 — *Everything in its place.*

**桌序**（Xulora）是一个以文件整理为核心的 macOS 私人桌面工作台。用户可以把真实文件夹以桌面组件的形式长期放在桌面上，直接完成文件查看、移动、复制和打开，同时使用便签、待办、时钟与番茄钟处理日常信息和专注任务。

---

## 功能

| 组件 | 描述 |
|------|------|
| 文件整理 | 绑定真实文件夹，拖入/拖出移动或复制文件，双击打开 |
| 便签 | 纯文本快速记录，自动保存 |
| 待办 | 简单任务管理，添加、完成、排序、删除 |
| 时钟 | 时间与日期展示，支持 12/24 小时制 |
| 番茄钟 | 专注与休息周期，系统通知提醒 |

## 技术栈

| 层级 | 技术 |
|------|------|
| 语言 | Swift 6 |
| UI | SwiftUI + AppKit |
| 持久化 | SwiftData |
| 测试 | Swift Testing |
| 最低系统 | macOS 26.0 |

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/insanetoto/xulora.git
cd xulora

# 编译
swift build

# 运行测试
swift test

# 在 Xcode 中打开
open Package.swift
```

## 项目结构

```
Xulora/
├── App/                    # 入口与菜单栏
│   ├── XuloraApp.swift     # @main, MenuBarExtra
│   ├── MenuBarView.swift   # 菜单栏交互
│   └── AppLifecycle.swift  # 休眠/唤醒/退出监听
├── Desktop/                # 桌面窗口管理
│   ├── WidgetManager.swift     # 组件生命周期
│   ├── WidgetWindow.swift      # NSWindow 封装
│   └── LayoutController.swift  # 编辑模式与多显示器
├── Models/                 # SwiftData 数据模型
│   ├── WidgetInstance.swift
│   ├── TodoItem.swift
│   ├── PomodoroState.swift
│   ├── FileWidgetConfiguration.swift
│   └── NoteRecord.swift
├── FileOrganizer/          # 文件整理模块
│   ├── FileWidgetView.swift
│   ├── FileOperationService.swift  # 移动/复制/废纸篓
│   ├── FolderObserver.swift        # FSEvents 监听
│   ├── FileDropHandler.swift       # Finder 拖放
│   └── FileConflictResolver.swift  # 命名冲突
├── Widgets/                # 功能组件视图
│   ├── NoteWidgetView.swift
│   ├── TodoWidgetView.swift
│   ├── ClockWidgetView.swift
│   └── PomodoroWidgetView.swift
├── Services/               # 横切服务
│   ├── PersistenceService.swift
│   ├── NotificationService.swift
│   └── LoginItemService.swift
└── Tests/
```

## 设计原则

- **本地优先** — V0.1 不登录、不上传、不依赖网络
- **文件安全** — 不静默覆盖、不永久删除、失败不丢源文件
- **安静克制** — 不抢焦点、不遮挡应用、低资源占用
- **文件夹为唯一事实来源** — 不复制维护独立文件数据库

## 开发计划

| 阶段 | 范围 | 状态 |
|------|------|------|
| P0 | 窗口技术验证 | 待开始 |
| P1 | 文件整理原型 | 待开始 |
| P2 | 完整文件整理能力 | 待开始 |
| P3 | 便签/待办/时钟/番茄钟 | 待开始 |
| P4 | 自用验证 | 待开始 |

## 版本

- **当前版本**: V0.1
- **后续候选版本**: V0.2 → V0.3 → V1.0
- 详见 [Xulora-产品说明.md](./Xulora-产品说明.md)

## 许可

Copyright (c) 2026 诺崇. All rights reserved.
