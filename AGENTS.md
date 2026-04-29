# AGENTS.md - Vim 配置仓库指南

> **语言要求**: 本项目与用户交流请使用中文。代码标识符、命令、路径等技术术语保持原样。

## 项目概述

这是 skywind3000 的个人 Vim/Neovim 配置仓库，模块化、跨平台（Windows/Linux/macOS），同时支持 Vim (8.0+) 和 Neovim。代码库包含约 633 个 git 追踪文件，主要使用 VimL、Lua 和 Python 编写。

**作者**: skywind3000
**许可证**: MIT
**主要语言**: VimL (.vim), Lua (.lua), Python (.py)

## 架构概览

```
init.vim                    # Vim 入口，按顺序加载 init/*.vim 各模块
  +-- init/viminit.vim      # 基础设置、核心按键映射
  +-- init/config.vim       # 各插件配置、标签页标签
  +-- init/vimmake.vim      # 构建系统、grep、ctags/cscope 集成
  +-- init/ignores.vim      # 通配符忽略模式
  +-- init/tools.vim        # 工具函数（文件浏览器、透明度、性能分析）
  +-- init/keymaps.vim      # <space>/<tab>/F 键用户快捷键（~20KB，最大的文件）
  +-- init/plugins.vim      # vim-plug 插件组定义（与 bundle.vim 对应）
  +-- init/status.vim       # 自定义状态栏
  +-- init/misc.vim         # 代码片段插入、模板辅助
  +-- init/gui.vim          # GUI/字体/主题（gvim/MacVim/Neovim-Qt）
  +-- init/menu.vim         # 基于 QuickMenu 的开发菜单
  +-- init/unix.vim         # Unix 专属：终端兼容、备份、文件类型

skywind.vim                 # 主协调文件：平台检测、asyncrun 配置、配色方案系统、
                            # QuickUI/CJK/补全设置，加载 site/opt/* 和 module#drivers

bundle.vim                  # 使用 vim-plug 的插件声明（条件分组）
neovim.lua                  # Neovim Lua 入口：设置 lazy.nvim，加载 lua/plugins/*
init-vscode.vim             # VSCode Vim 扩展的最小化按键配置
tasks.ini                   # AsyncTasks 构建/运行/调试任务定义
```

## 目录结构

```
c:\Share\vim/
|-- init/               核心初始化模块（12 个 VimL 文件）
|-- autoload/           自动加载函数库（约 160 个文件）
|   |-- asclib/         公共工具库（24 个模块），提供路径、字符串、UI、Git、Python 等公共函数，
|   |                   供仓库内其他模块广泛调用
|   |-- asyncrun/       作者自写的 AsyncRun 插件，异步运行 shell 命令，
|   |                   输出到 quickfix 窗口或内置终端，支持 13 种终端后端
|   |-- asynctask.vim   基于 job 的异步任务执行引擎
|   |-- quickui/        作者自写的 Vim 界面增强库（19 个组件：菜单、列表框、输入框、
|   |                   确认框、预览窗口、终端等），基于 popup/floating window
|   |-- module/         内部高级功能模块，基于 asclib 的二次封装
|   |                   （24+ 模块：cpp、go、lsp、git、project、mode 等）
|   |-- navigator/      作者自写的浮动操作面板，类似 Emacs 的 which-key，
|   |                   提供键盘驱动的层级菜单导航（7 个模块）
|   |-- quickmenu.vim   垂直弹出菜单系统
|   |-- preview.vim     窗口管理系统（带唯一 ID 追踪）
|   |-- colorexp/       配色方案浏览器和调色板查看器
|   |-- gdv/            作者自写的 Git Diff View，在 fugitive 中按 dd 可分屏显示
|   |                   相关文件的 diff（6 个模块）
|   |-- gptcommit/      GPT 生成 Git 提交日志（支持 ChatGPT/Ollama）
|   |-- notify/         弹窗通知系统
|   |-- tweak/          杂项增强（cherry-pick、pastebin）
|   |-- python/         Python 集成（pyvim、parser、treesitter）
|   |-- plug.vim        vim-plug 插件管理器（junegunn，第三方）
|   +-- ...             其他：snippet、svnhelp、textobj、projectile 等
|-- plugin/             启动脚本，Vim 启动时自动加载（约 41 个文件）
|   |-- asyncrun.vim    AsyncRun 核心（约 67KB）
|   |-- asynctasks.vim  AsyncTasks 核心（约 71KB）
|   |-- commands.vim    自定义命令（FileSwitch、SwitchHeader 等）
|   |-- menu_init.vim   QuickUI 菜单栏设置
|   |-- menu_keys.vim   Buffer/窗口/标签导航菜单
|   |-- template.vim    文件模板系统
|   |-- textproc.vim    文本处理管道
|   |-- terminal_help.vim  终端集成
|   |-- altmeta.vim     修复控制台 Vim 的 Alt/Meta 键编码
|   |-- gutentags_plus.vim GNU Global/cscope 集成
|   +-- ...             其他：highlight、localrc、preview、rtformat 等
|-- site/
|   |-- bundle/         各外部插件的配置文件（约 44 个，每个插件一个文件）
|   |-- opt/            可选的内置插件（calendar、taglist、vimim 等）
|   |-- snippets/       SnipMate 代码片段（按语言分）
|   |-- ultisnips/      UltiSnips 代码片段（按语言分）
|   |-- template/       新建文件模板（按语言分：c、cpp、python、go 等）
|   |-- text/           文本过滤脚本（Python/shell：格式化、转换等）
|   |-- escript/        编辑器工具脚本（导出配色、列出路径等）
|   |-- minisnip/       Minisnip 代码片段
|   |-- samples/        示例配置文件
|   |-- doc/            速查文档（bash、emacs、gdb、git、vim 等）
|   +-- specs/          agent 沟通文档（草案讨论、分析报告、模块详细说明等）
|-- lua/                Neovim Lua 配置，与 Vim 配置共用 autoload/ 和 plugin/ 下的脚本
|   |-- core/           核心工具（ascmini.lua、loader、utils）
|   |-- config/         Lua 配置（custom、extra、packages），入口为 init.lua
|   +-- plugins/        lazy.nvim 插件规格（basic、lsp、treesitter、telescope 等）
|-- ftplugin/           文件类型专属设置（约 31 个文件：c、cpp、python、go 等）
|-- colors/             配色方案（约 24 个 + patch/ 补丁 + quickui/ 变体）
|-- syntax/             自定义语法文件（navigator、quickmenu、taskini、python 等）
|-- cheat/              速查表（git、linux、regex、tcpdump 等）
|-- doc/                Vim 帮助文件（asyncrun、asynctasks、terminal_help、apc 等）
|-- lib/                Python 库模块（约 28 个文件：emake、gptcommit、shell 等）
|-- tools/
|   |-- bin/            命令行工具（cheat、dotenv、fasd、q-* 系列工具）
|   |-- conf/           配置文件（clang-format、coc-settings、flake8、pylint 等）
|   |-- dotenv/         环境设置（mingw、vc、watcom、clang）
|   |-- emake/          Emake 构建配置（编译器工具链 INI）
|   |-- script/         工具脚本（视频、git-credential 等）
|   |-- share/          系统引导脚本
|   |-- utils/          asynctask CLI、drop 工具
|   |-- test/           插件测试脚本
|   +-- tips/           Vim 技巧和 fortune 文本
+-- etc/                个人 bash/zsh 等 shell 配置文件
                        （bash、zsh、fish、tmux、readline、z.lua 等）
```

## 核心概念

### 初始化流程

1. 用户的 `.vimrc` 加载 `init.vim`，可选加载 `skywind.vim`
2. `init.vim` 设置 `s:home`，添加到 rtp/packpath，然后按顺序加载 `init/*.vim`
3. `skywind.vim` 执行额外的平台专属设置，加载 `site/opt/*` 插件，配置 asyncrun/asynctask/quickui，设置配色方案
4. `bundle.vim`（用户单独加载）定义 vim-plug 插件分组
5. Neovim 场景：`neovim.lua` 设置 lazy.nvim 并加载 `lua/plugins/*.lua`
6. `local.vim`（不纳入 git 追踪）最后加载，用于机器特定的覆盖配置

### 插件分组系统

插件通过 `g:bundle_group` 列表按条件分组加载：
- `simple` - 基础必备：dirvish、sneak/easymotion、fugitive、surround、unimpaired、cycle
- `basic` - 开发工具：choosewin、startify、markdown、语法高亮、LeaderF/CtrlP
- `inter` - 中级功能：notes、outliner、DrawIt、flog、vim-mark
- `high` - 高级功能：signify、fzf、neoformat、table-mode
- `opt` - 可选功能：translator、gutentags、emmet、switch.vim
- 代码片段引擎（互斥）：`snipmate`、`ultisnips`、`minisnip`、`neosnippet`
- LSP/补全：`coc`、`lsp`、`ycm`、`lcn`、`yegappan`
- UI：`lightline`、`airline`、`colors`

### Autoload 命名空间约定

所有自定义函数遵循 Vim 的 autoload 模式 `namespace#module#function()`：
- `asclib#path#*` - 路径工具
- `asclib#utils#*` - 通用工具（URL 打开、lint、配色切换）
- `asyncrun#*` / `asynctask#*` - 任务执行
- `quickui#*` - UI 组件
- `module#*` - 功能模块（project、action、mode、cpp、go、lsp 等）
- `navigator#*` - 导航系统
- `vimmake#*` - 构建/grep/tags

### AsyncTask 任务系统

主要的构建/运行机制，任务定义在 `tasks.ini`（全局）或 `.tasks`（项目级）：
- F5=file-run, F6=make, F7=emake, F8=emake-exe, F9=file-build
- Shift-F5=project-run, Shift-F9=project-build 等
- 支持 profiles（debug/release）、环境变量、多种输出模式

### 快捷键前缀体系

- `<space>` - 主用户命令前缀（keymaps.vim）
- `<tab>` - 窗口/Buffer 导航前缀（viminit.vim、keymaps.vim）
- `\`（反斜杠）- Buffer/窗口/标签管理（viminit.vim）
- `Alt+N` - 标签页切换（1-9）
- `F1-F12` / `Shift-F1-F12` - 构建任务（keymaps.vim）
- `<leader>c` - CScope 查找操作

## 编码规范

### VimL 风格

- 脚本局部变量使用 `let s:variable`，全局变量使用 `g:variable`
- 全局变量前缀 `g:asc_` 或插件特定前缀
- 脚本局部函数使用 `function! s:FuncName()`
- Autoload 函数：`function! namespace#module#func()`
- 使用 Tab 缩进（tabstop=4），不使用 expandtab
- 用特性检查保护命令：`if has('feature')`、`if exists(':command')`
- 平台检查使用 `g:asc_uname`（'windows'、'linux'、'macos'）或 `has('win32')`

### Lua 风格（Neovim）

- 插件规格放在 `lua/plugins/*.lua`（每个文件对应一类）
- 核心工具在 `lua/core/`（ascmini.lua 是主工具库）
- 配置在 `lua/config/`（custom.lua 用于用户覆盖）
- 使用 lazy.nvim 管理插件

### Python 模块

- `lib/` 下的模块是独立 CLI 工具或 Vim 集成工具
- `autoload/python/` 包含 Vim 可调用的 Python 模块
- Python 2/3 兼容性由 `asclib#python` 处理

## 新功能开发指南

1. **新插件配置**: 在 `site/bundle/pluginname.vim` 添加文件
2. **新 autoload 函数**: 在 `autoload/` 下按命名空间约定添加
3. **新文件类型设置**: 添加 `ftplugin/filetype.vim`
4. **新配色方案**: 添加到 `colors/`，可选在 `colors/patch/` 添加补丁
5. **新任务**: 添加到 `tasks.ini`（全局）或项目的 `.tasks` 文件
6. **新代码片段**: 添加到 `site/snippets/`（SnipMate）或 `site/ultisnips/`（UltiSnips）
7. **新文件模板**: 添加到 `site/template/language/`
8. **新文本过滤器**: 添加到 `site/text/`
9. **新 Lua 插件配置**: 添加到 `lua/plugins/`
10. **新 module 模块**: 添加 `autoload/module/name.vim`，在 `module#drivers` 中注册

## 重要文件速查

| 文件 | 用途 | 大小 |
|------|------|------|
| `init/keymaps.vim` | 所有用户按键映射 | ~20KB |
| `init/plugins.vim` / `bundle.vim` | 插件列表（基本一致，bundle.vim 面向用户） | 各 ~10KB |
| `init/config.vim` | 插件设置、标签行 | ~6KB |
| `skywind.vim` | 主配置、平台设置 | 大文件 |
| `plugin/asyncrun.vim` | 异步执行引擎核心 | ~67KB |
| `plugin/asynctasks.vim` | 任务系统核心 | ~71KB |
| `autoload/quickui/core.vim` | QuickUI 基础 | ~27KB |
| `autoload/preview.vim` | 窗口管理系统 | ~26KB |
| `autoload/asclib/utils.vim` | 核心工具函数 | ~15KB |
| `tasks.ini` | 全局任务定义 | 大文件 |

## 跨平台注意事项

- 路径分隔符：VimL 中统一使用 `/`（Vim 在所有平台上会自动规范化）
- 编码：主要使用 UTF-8，中文 Windows 下回退到 GBK
- 终端：Alt/Meta 键兼容性由 `plugin/altmeta.vim` 处理
- Shell：Fish shell 会被检测并转换为 sh 以保证兼容
- WSL：特殊终端修复（移除 t_u7、光标形状）
- MSYS/MinGW：在 Windows 上为 asyncrun 自动检测

## 不应修改的文件

- `autoload/plug.vim` - 第三方 vim-plug 管理器（来自上游）
- `autoload/textobj/user.vim` - 第三方文本对象库
- `plugin/commentary.vim` - 基于 tpope 的 commentary
- `site/opt/` 中后缀为 `.old` 的文件 - 已归档，不再活跃
- `lib/*.py` 模块大多是独立工具，修改时请谨慎

## 内置插件参考文档

`site/specs/reference/` 存放了仓库内置插件的详细文档。

> **强制规则**: 在**修改**或**调用**下列内置插件的代码之前，**必须先阅读**对应的参考文档，以了解插件的接口设计、使用约定和注意事项。

| 参考文档 | 对应插件 | 关键代码路径 |
|----------|----------|-------------|
| `site/specs/reference/asyncrun.md` | AsyncRun 异步执行引擎 | `plugin/asyncrun.vim`, `autoload/asyncrun/` |
| `site/specs/reference/asynctasks.md` | AsyncTasks 任务系统 | `plugin/asynctasks.vim`, `autoload/asynctask.vim` |
| `site/specs/reference/quickui.md` | QuickUI 界面组件库 | `autoload/quickui/`, `plugin/menu_init.vim` |
| `site/specs/reference/gdv.md` | Git Diff View | `autoload/gdv/` |
| `site/specs/reference/textproc.md` | TextProc 文本处理管道 | `plugin/textproc.vim` |

## 测试

- 插件测试脚本在 `tools/test/`（test_confirm.vim、test_listbox.vim 等）
- 在 Vim 中使用 `:source tools/test/test_xxx.vim` 测试特定 UI 组件
- 没有自动化测试框架；测试通过 Vim 运行时手动进行
- 配色方案测试：`site/escript/dump_colors.vim`

## 依赖关系图

```
用户 .vimrc
  |
  +-- init.vim
  |     +-- init/viminit.vim（基础）
  |     +-- init/config.vim（插件设置）
  |     +-- init/vimmake.vim --> asclib#path, asclib#quickfix, asyncrun
  |     +-- init/tools.vim --> asclib, auxlib
  |     +-- init/keymaps.vim --> asynctask, vimmake, module#*, asclib
  |     +-- init/plugins.vim（插件分组，使用 vim-plug）
  |     +-- init/menu.vim --> quickmenu, asynctask, svnhelp, asclib
  |     +-- init/gui.vim --> asclib#color_switch
  |     +-- init/unix.vim（独立）
  |     +-- init/status.vim（独立）
  |     +-- init/misc.vim（独立）
  |     +-- init/ignores.vim（独立）
  |
  +-- skywind.vim
  |     +-- site/opt/*（可选插件）
  |     +-- module#drivers#install()
  |     +-- asyncrun/asynctask 配置
  |     +-- quickui 配置
  |     +-- 配色方案系统 --> asclib#color_switch
  |
  +-- bundle.vim（vim-plug 插件定义）
  |
  +-- local.vim（机器特定配置，不纳入 git）

Autoload 层：
  asclib/*（基础库）<-- 几乎所有模块都依赖
  asyncrun/* + asynctask.vim <-- 构建/任务系统
  quickui/* <-- UI 组件库
  module/* <-- 功能插件模块
  navigator/* <-- 键盘导航面板
  quickmenu.vim <-- 简单菜单
  preview.vim <-- 窗口管理
  gdv/* <-- Git Diff View
  gptcommit/* <-- AI 提交日志

Neovim Lua 层（与 Vim 共用 autoload/ 和 plugin/）：
  neovim.lua --> lua/plugins/*.lua（lazy.nvim 插件规格）
  lua/core/ascmini.lua（Lua 工具库）
  lua/config/init.lua（Lua 配置入口）
```
