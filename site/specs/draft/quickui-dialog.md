# QuickUI Dialog 模块设计方案

> **目标文件**: `autoload/quickui/dialog.vim`
> **依赖**: `quickui#window`, `quickui#readline`, `quickui#core`, `quickui#utils`, `quickui#highlight`
> **适用**: Vim 8.2+ / Neovim 0.4+
> **状态**: 草案

## 概述

`quickui#dialog` 是一个数据驱动的通用对话框模块。用户通过声明式的控件列表描述对话框的内容和布局，调用 `quickui#dialog#open()` 即可弹出对话框，用户交互完毕后返回一个包含所有控件值的字典。

### 设计目标

- 数据驱动：用户传入控件描述列表，不需要手动管理窗口和渲染
- 支持 Tab 焦点链在多个可交互控件之间切换
- 复用现有 `quickui#window`（窗口管理）和 `quickui#readline`（文本编辑）
- 初期支持 5 种基础控件：label、input、radio、check、button
- Vim/Neovim 双平台兼容

## API

### 主入口

```vim
let result = quickui#dialog#open(items, opts)
```

**参数**:

- `items`: List，每个元素是一个 Dict，描述一个控件（见 [控件定义](#控件定义)）
- `opts`: Dict，对话框级别选项（见 [对话框选项](#对话框选项)）

**返回值**: Dict，包含所有命名控件的当前值，以及按钮状态（见 [返回值](#返回值)）

### 控件定义

#### label — 静态文本

```vim
{'type': 'label', 'text': 'Please fill in the form:'}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | String | 是 | `'label'` |
| `text` | String / List | 是 | 显示文本，String 按 `\n` 拆分为多行，List 每个元素一行 |

- 不可聚焦，Tab 跳过
- 占用行数 = 文本行数

#### input — 单行文本输入框

```vim
{'type': 'input', 'name': 'username', 'prompt': 'Name:', 'value': 'skywind'}
```

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | String | 是 | — | `'input'` |
| `name` | String | 是 | — | 控件名称，用于返回值的键名 |
| `prompt` | String | 否 | `''` | 左侧标签文本 |
| `value` | String | 否 | `''` | 初始文本 |
| `history` | String | 否 | `''` | 历史记录命名空间（同 `quickui#input` 的 history） |

- 可聚焦
- 占用 1 行
- 内部关联一个 `quickui#readline` 实例
- 布局：`prompt  [editable area.............]`
- 连续多个 input 控件的 prompt 自动对齐（取最长 prompt 宽度 + 2 作为标签列宽）

#### radio — 单选组

```vim
{'type': 'radio', 'name': 'role', 'prompt': 'Role:',
 \ 'items': ['&Dev', '&QA', '&PM'], 'value': 0}
```

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | String | 是 | — | `'radio'` |
| `name` | String | 是 | — | 控件名称 |
| `prompt` | String | 否 | `''` | 左侧标签文本 |
| `items` | List | 是 | — | 选项文本列表，支持 `&` 标记快捷键 |
| `value` | Number | 否 | `0` | 默认选中项索引（0-based） |

- 可聚焦
- 占用 1 行（水平排列）
- 布局：`prompt  (*) Dev  ( ) QA  ( ) PM`

#### check — 复选框

```vim
{'type': 'check', 'name': 'admin', 'text': 'Administrator', 'value': 0}
```

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | String | 是 | — | `'check'` |
| `name` | String | 是 | — | 控件名称 |
| `text` | String | 是 | — | 显示文本，支持 `&` 标记快捷键 |
| `value` | Number | 否 | `0` | 初始状态，0=未选中，1=选中 |

- 可聚焦
- 占用 1 行
- 布局：`[x] Administrator` 或 `[ ] Administrator`

#### button — 按钮行

```vim
{'type': 'button', 'name': 'confirm', 'items': [' &OK ', ' &Cancel '], 'value': 0}
```

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | String | 是 | — | `'button'` |
| `name` | String | 否 | `'button'` | 控件名称，用于返回值标识哪个 button 行被激活 |
| `items` | List | 是 | — | 按钮文本列表，支持 `&` 标记快捷键 |
| `value` | Number | 否 | `0` | 默认聚焦的按钮索引（0-based） |

- 可聚焦
- 占用 1 行
- 支持定义多个 button 控件，各占一行
- 布局：按钮居中或居右排列，`< OK >  < Cancel >`
- `items` 中的 `&` 标记同 `quickui#confirm` 的 choices 约定（`quickui#utils#item_parse`）

### 对话框选项

通过 `opts` 参数传递：

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | String | `'Dialog'` | 对话框标题 |
| `w` | Number | auto | 对话框内容区宽度，不指定则自动计算 |
| `border` | Number | `g:quickui#style#border` | 边框样式 |
| `center` | Number | `1` | 是否居中显示 |
| `padding` | List | `[1,1,1,1]` | 内边距 |
| `color` | String | `'QuickBG'` | 背景高亮组 |
| `bordercolor` | String | `'QuickBorder'` | 边框高亮组 |
| `gap` | Number | `1` | 不同类型控件之间的空行数 |
| `button` | Number | `1` | 是否显示窗口关闭按钮 |

### 返回值

返回一个 Dict，包含：

- 所有命名控件的值（以 `name` 为键）
- `button` 字段标识哪个 button 控件被激活
- `button_index` 字段标识该控件内第几个按钮

**用户点击按钮关闭**:

```vim
{
    \ 'button': 'confirm',
    \ 'button_index': 0,
    \ 'username': 'skywind',
    \ 'email': 'test@example.com',
    \ 'role': 1,
    \ 'admin': 0,
    \ 'notify': 1,
    \ }
```

**用户按 ESC 或点击关闭按钮取消**:

```vim
{
    \ 'button': '',
    \ 'button_index': -1,
    \ }
```

字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `button` | String | 被激活的 button 控件的 `name`，取消时为空字符串 |
| `button_index` | Number | 被激活按钮在其控件 `items` 中的索引（0-based），取消时为 -1 |
| `<input.name>` | String | 文本框的内容 |
| `<radio.name>` | Number | 单选组的选中项索引（0-based） |
| `<check.name>` | Number | 复选框状态，0 或 1 |

## 完整示例

```vim
let items = [
    \ {'type': 'label', 'text': 'Please fill in the user form:'},
    \ {'type': 'input', 'name': 'username', 'prompt': 'Name:',
    \  'value': 'skywind'},
    \ {'type': 'input', 'name': 'email', 'prompt': 'Email:'},
    \ {'type': 'radio', 'name': 'role', 'prompt': 'Role:',
    \  'items': ['&Dev', '&QA', '&PM'], 'value': 0},
    \ {'type': 'check', 'name': 'admin', 'text': 'Administrator'},
    \ {'type': 'check', 'name': 'notify', 'text': 'Send notification',
    \  'value': 1},
    \ {'type': 'button', 'name': 'confirm',
    \  'items': [' &OK ', ' &Cancel ']},
    \ ]

let opts = {'title': 'User Form', 'w': 50}
let result = quickui#dialog#open(items, opts)

if result.button == 'confirm' && result.button_index == 0
    echo 'User: ' . result.username
    echo 'Email: ' . result.email
    echo 'Role: ' . result.role
    echo 'Admin: ' . result.admin
endif
```

渲染效果：

```
┌─ User Form ──────────────────────────────┐
│                                           │
│  Please fill in the user form:            │
│                                           │
│  Name:  [skywind                       ]  │
│  Email: [                              ]  │
│                                           │
│  Role:  (*) Dev  ( ) QA  ( ) PM           │
│                                           │
│  [x] Administrator                        │
│  [x] Send notification                    │
│                                           │
│            < OK >    < Cancel >            │
│                                           │
└───────────────────────────────────────────┘
```

## 布局规则

### 垂直堆叠

所有控件按 items 列表顺序从上到下排列，每个控件占固定行数。

### 控件占用行数

| 类型 | 行数 |
|------|------|
| `label` | 文本行数（String 按 `\n` 拆分） |
| `input` | 1 |
| `radio` | 1（水平排列） |
| `check` | 1 |
| `button` | 1 |

### 空行分隔规则

- 不同类型的相邻控件之间插入 `gap` 行空行（默认 1 行）
- 相同类型的相邻控件之间**不插入**空行，形成视觉分组
  - 例：连续多个 check 紧挨排列
  - 例：连续多个 input 紧挨排列，prompt 自动对齐
- button 控件之间也不插入空行（多个按钮行紧挨）

### prompt 对齐

连续的 input 控件（中间无其他类型控件）形成一个"对齐组"，组内所有 prompt 按最长的 prompt 宽度 + 2 对齐：

```
Name:   [skywind                       ]
Email:  [                              ]
Phone:  [                              ]
```

radio 控件的 prompt 也参与对齐组（如果与 input 连续）。

### 宽度自动计算

如果 `opts.w` 未指定，自动计算对话框宽度：

1. 取所有 label 文本行的最大宽度
2. 取所有 button 行的渲染宽度
3. 取所有 input/radio/check 渲染所需的最小宽度
4. 取以上最大值，并设下限（如 40 列）和上限（`&columns * 80 / 100`）

## 焦点管理

### 焦点链

从 items 中过滤出所有可聚焦控件（input、radio、check、button），按顺序构建焦点链 `focus_list`。每个焦点项记录：

```vim
{
    \ 'index': 3,           " 在 items 中的原始索引
    \ 'type': 'input',      " 控件类型
    \ 'control': {...},     " 内部控件对象的引用
    \ }
```

### 焦点切换

| 按键 | 行为 |
|------|------|
| `Tab` | 焦点移到下一个控件（循环到首个） |
| `Shift-Tab` | 焦点移到上一个控件（循环到末尾） |

焦点切换时：
1. 旧焦点控件的高亮变为"未聚焦"样式
2. 新焦点控件的高亮变为"聚焦"样式
3. 如果新焦点是 input，readline 光标重新显示

### 初始焦点

默认聚焦到焦点链中的第一个控件。可以通过 `opts.focus` 指定初始焦点的控件 `name`。

## 按键分发

### 全局按键（所有状态下生效）

| 按键 | 行为 |
|------|------|
| `ESC` / `Ctrl-C` | 取消对话框 |
| `Tab` | 焦点前进 |
| `Shift-Tab` | 焦点后退 |
| `LeftMouse` | 点击定位：聚焦对应控件并执行点击操作 |

### input 控件按键

| 按键 | 行为 |
|------|------|
| readline 按键 | 委托给 `rl.feed()`（光标移动、编辑、选择、剪贴板等） |
| `Enter` | 焦点前进到下一个控件 |
| `Up` / `Down` | 有历史时浏览历史；无历史时焦点上/下移动 |

说明：input 控件聚焦时接管大部分按键，只有 Tab/S-Tab/Enter/ESC 走全局处理。

### radio 控件按键

| 按键 | 行为 |
|------|------|
| `Left` / `h` | 选择上一个选项（循环） |
| `Right` / `l` | 选择下一个选项（循环） |
| `Space` | 无额外操作（切换已通过方向键即时生效） |
| `Enter` | 焦点前进到下一个控件 |

### check 控件按键

| 按键 | 行为 |
|------|------|
| `Space` | 切换勾选状态 |
| `Enter` | 焦点前进到下一个控件 |

### button 控件按键

| 按键 | 行为 |
|------|------|
| `Left` / `h` | 切换到左侧按钮 |
| `Right` / `l` | 切换到右侧按钮 |
| `Space` / `Enter` | **激活当前按钮，关闭对话框，返回结果** |

### 快捷键

button 和 radio 的 `items` 支持 `&` 标记快捷键（同 `quickui#utils#item_parse` 约定）。快捷键为全局有效：

- button 快捷键：直接激活对应按钮，关闭对话框
- radio 快捷键：选中对应选项（不关闭对话框）
- check 的 `text` 也支持 `&` 快捷键：切换勾选状态

## 鼠标交互

通过 `v:mouse_winid` + 鼠标坐标判断点击位置，映射到对应控件：

| 点击目标 | 行为 |
|----------|------|
| input 区域 | 聚焦该控件，定位 readline 光标到点击位置 |
| radio 选项 | 聚焦该控件，选中被点击的选项 |
| check 区域 | 聚焦该控件，切换勾选状态 |
| button | 聚焦该控件，激活被点击的按钮，关闭对话框 |
| label / 空白 | 无操作 |
| 窗口关闭按钮 | 取消对话框 |

## 高亮方案

### 控件状态高亮

| 控件 | 聚焦态 | 未聚焦态 |
|------|--------|----------|
| input 文本区域 | `QuickInput` | `QuickOff`（或 `QuickBG` 带下划线） |
| input 光标 | `QuickCursor`（闪烁） | 不显示 |
| input 选区 | `QuickVisual` | 不显示 |
| radio 选中项 | `QuickSel` | 正常文本 |
| radio `(*)` 标记 | `QuickSel` | 正常文本 |
| check `[x]` 标记 | `QuickSel` | 正常文本 |
| button 当前按钮 | `QuickSel`（同 confirm.vim） | `QuickBG` |
| button 快捷键字符 | 下划线变体（同 confirm.vim 的 `QuickButtonOn2`/`QuickButtonOff2`） | 下划线变体 |

### 新增高亮组

可能需要新增：

- `QuickOff` — 未聚焦的 input 区域背景（与 `QuickInput` 区分）
- 或复用现有高亮组，通过 `quickui#highlight` 动态生成变体

## 内部架构

### 数据结构

```vim
" 对话框主状态对象
let hwnd = {
    \ 'items': [...],          " 原始 items 列表
    \ 'controls': [...],       " 解析后的内部控件对象列表
    \ 'focus_list': [...],     " 可聚焦控件的有序列表
    \ 'focus_index': 0,        " 当前焦点在 focus_list 中的索引
    \ 'win': <window object>,  " quickui#window 实例
    \ 'w': 50,                 " 内容区宽度
    \ 'h': 20,                 " 内容区高度
    \ 'keymap': {...},         " 快捷键映射表
    \ 'exit': 0,               " 是否退出主循环
    \ 'accept': 0,             " 是否为正常接受（非取消）
    \ }
```

```vim
" 内部控件对象（以 input 为例）
let control = {
    \ 'type': 'input',
    \ 'name': 'username',
    \ 'prompt': 'Name:',
    \ 'prompt_width': 6,       " prompt 显示宽度（对齐后）
    \ 'line_start': 4,         " 在 buffer 中的起始行号（0-based）
    \ 'line_count': 1,         " 占用行数
    \ 'focusable': 1,          " 是否可聚焦
    \ 'rl': <readline object>, " readline 实例（仅 input）
    \ 'pos': 0,                " readline 视口位置（仅 input）
    \ 'value': 'skywind',      " 当前值
    \ 'input_col': 8,          " 输入区域起始列（仅 input）
    \ 'input_width': 40,       " 输入区域宽度（仅 input）
    \ }
```

### 执行流程

```
quickui#dialog#open(items, opts)
  │
  ├── s:parse_items(items)
  │     解析每个 item，创建内部 control 对象
  │     input 类型：创建 readline 实例，设置初始值
  │     button 类型：调用 quickui#utils#item_parse 解析按钮文本
  │
  ├── s:calc_layout(hwnd, opts)
  │     计算对齐组、每个 control 的行位置、对话框总尺寸
  │     处理 prompt 对齐、空行插入
  │
  ├── s:build_focus_list(hwnd)
  │     过滤可聚焦控件，构建焦点链
  │
  ├── s:build_keymap(hwnd)
  │     收集所有 button/radio/check 的快捷键，构建全局快捷键表
  │
  ├── s:build_content(hwnd)
  │     生成初始 buffer 文本行
  │
  ├── win = quickui#window#new()
  │   call win.open(content, win_opts)
  │
  └── 主事件循环
        │
        ├── s:render_all(hwnd)
        │     遍历所有 controls 调用各自的渲染函数
        │     对聚焦的 input 调用 rl.render() 获取带属性文本
        │     使用 win.syntax_begin/region/end 设置高亮
        │
        ├── redraw
        │
        ├── getchar() / getchar(0)
        │
        └── s:handle_key(hwnd, ch)
              ├── 全局键判断：ESC/Tab/S-Tab/Mouse/快捷键
              ├── 获取当前焦点控件
              └── 调用对应的 s:handle_<type>(hwnd, control, ch)
                    ├── s:handle_input()  → rl.feed(ch)
                    ├── s:handle_radio()  → 切换选项
                    ├── s:handle_check()  → 切换状态
                    └── s:handle_button() → 激活按钮
```

### 渲染函数

每个控件类型有独立的渲染函数：

```vim
" 渲染 input 控件
function! s:render_input(hwnd, control, focused)
    let rl = a:control.rl
    let win = a:hwnd.win
    let y = a:control.line_start
    let col = a:control.input_col

    if a:focused
        " 计算视口、渲染 readline
        let a:control.pos = rl.slide(a:control.pos, a:control.input_width)
        let display = rl.render(a:control.pos, a:control.input_width)
        let ts = float2nr(reltimefloat(reltime()) * 1000)
        let blink = rl.blink(ts)

        " 逐片段设置高亮
        let x = col
        for [attr, text] in display
            let len = strwidth(text)
            if attr == 1
                let color = blink ? 'QuickInput' : 'QuickCursor'
            elseif attr == 2
                let color = 'QuickVisual'
            elseif attr == 3
                let color = blink ? 'QuickVisual' : 'QuickCursor'
            else
                let color = 'QuickInput'
            endif
            call win.syntax_region(color, x, y, x + len, y)
            let x += len
        endfor

        " 更新 buffer 行文本
        " ...
    else
        " 未聚焦：显示静态文本，使用 QuickOff 高亮
        call win.syntax_region('QuickOff', col, y, col + a:control.input_width, y)
    endif
endfunc
```

### 与 confirm.vim 的关系

button 控件的渲染逻辑直接复用 `confirm.vim` 中的模式：

- `quickui#utils#item_parse()` 解析按钮文本和快捷键
- 按钮居中/居右排列
- 焦点态用 `QuickSel`，快捷键字符用下划线变体（`QuickButtonOn2`/`QuickButtonOff2`）
- 鼠标点击区域判断逻辑相同

区别在于 dialog 的 button 只是众多控件之一，不独占整个窗口。

## 扩展预留

以下功能不在初期实现范围内，但设计时预留扩展空间：

1. **radio 垂直布局** — 通过 `vertical: 1` 选项，每个选项独占一行
2. **input 多行文本框** — 通过 `multiline: 1` 选项，支持多行编辑
3. **separator 控件** — `{'type': 'separator'}` 绘制水平分隔线
4. **listbox 控件** — 下拉选择框或内嵌列表
5. **控件禁用** — 通过 `enable: 0` 禁用特定控件（灰色显示，Tab 跳过）
6. **回调函数** — 控件值变更时触发回调（如 radio 选择后动态更新其他控件）

## 测试计划

在 `tools/test/test_dialog.vim` 中提供测试脚本：

```vim
" 基础测试：所有控件类型
function! Test_dialog_basic()
    let items = [
        \ {'type': 'label', 'text': 'Test all controls:'},
        \ {'type': 'input', 'name': 'name', 'prompt': 'Name:',
        \  'value': 'test'},
        \ {'type': 'radio', 'name': 'choice', 'prompt': 'Pick:',
        \  'items': ['A', 'B', 'C']},
        \ {'type': 'check', 'name': 'flag', 'text': 'Enable'},
        \ {'type': 'button', 'name': 'confirm',
        \  'items': [' &OK ', ' &Cancel ']},
        \ ]
    let result = quickui#dialog#open(items, {'title': 'Test'})
    echo result
endfunc

" 多按钮行测试
function! Test_dialog_multi_button()
    let items = [
        \ {'type': 'label', 'text': 'Multiple button rows:'},
        \ {'type': 'button', 'name': 'action',
        \  'items': [' &Apply ', ' &Reset ']},
        \ {'type': 'button', 'name': 'confirm',
        \  'items': [' &OK ', ' &Cancel ']},
        \ ]
    let result = quickui#dialog#open(items, {'title': 'Multi Button'})
    echo result
endfunc
```

在 Vim 中运行：`:source tools/test/test_dialog.vim | call Test_dialog_basic()`

### 自动化验证

手动测试无法覆盖所有场景，且 coding agent 无法直接操作 Vim 交互式界面。因此需要一套基于脚本的自动化验证方案，让 Vim 在无人值守模式下完成渲染验证。

#### 核心思路

1. 编写 VimL 测试脚本（如 `tools/test/test_dialog_auto.vim`）
2. 通过命令行启动 Vim 加载该脚本，Vim 在脚本内完成全部验证
3. 脚本内使用 `screenstring()` / `screenchars()` 获取屏幕内容，与预期值比对
4. 脚本通过 `:cq` 命令退出 Vim，返回码表示成功/失败
5. 外部调用方（shell 或 coding agent）通过检查退出码判断测试结果

#### 启动方式

```bash
# 以固定屏幕尺寸启动 Vim，加载测试脚本
# -u NONE 避免加载用户 vimrc 干扰
# -N 启用 nocompatible
# -i NONE 禁用 viminfo
# -n 禁用 swap 文件
# -e -s 进入 silent ex mode（部分场景可用）
vim -u NONE -N -i NONE -n \
    --cmd "set lines=30 columns=80" \
    -S tools/test/test_dialog_auto.vim
echo "Exit code: $?"
# 退出码 0 = 所有测试通过
# 退出码非 0 = 某项测试失败
```

注意：`set lines=30 columns=80` 放在 `--cmd` 中确保在脚本加载前设置。某些终端环境下 Vim 的 `lines`/`columns` 可能被终端尺寸覆盖，如果无法设定可改用 GUI 模式（`gvim`）或在脚本中校验并跳过。

#### 测试脚本结构

```vim
" tools/test/test_dialog_auto.vim
" 自动化验证脚本 —— 由命令行启动，无需人工交互

" ── 0. 加载依赖 ──────────────────────────────────────
set rtp+=c:/Share/vim        " 或用相对路径，确保 autoload/ 可达
runtime plugin/asyncrun.vim  " 按需加载

" ── 1. 校验屏幕尺寸 ──────────────────────────────────
let s:expected_lines = 30
let s:expected_cols = 80
if &lines != s:expected_lines || &columns != s:expected_cols
    " 屏幕尺寸不符合预期，写日志并退出
    call writefile(['FAIL: screen size mismatch, expected ' .
        \ s:expected_lines . 'x' . s:expected_cols .
        \ ', got ' . &lines . 'x' . &columns],
        \ 'test_dialog_result.log')
    cq 2    " 退出码 2 表示环境问题
endif

" ── 2. 测试辅助函数 ──────────────────────────────────

" 捕获屏幕指定区域的文本
function! s:screen_capture(row, col, width) abort
    let text = ''
    let c = a:col
    while c < a:col + a:width
        let ch = screenstring(a:row, c)
        let text .= ch
        " 全角字符占两列，跳过下一列
        let w = strdisplaywidth(ch)
        let c += (w > 1) ? w : 1
    endwhile
    return text
endfunc

" 捕获整个屏幕到行列表（用于 dump 到文件）
function! s:screen_dump(filename) abort
    let lines = []
    for row in range(1, &lines)
        let line = ''
        let col = 1
        while col <= &columns
            let ch = screenstring(row, col)
            let line .= ch
            let w = strdisplaywidth(ch)
            let col += (w > 1) ? w : 1
        endwhile
        call add(lines, line)
    endfor
    call writefile(lines, a:filename)
endfunc

" 断言函数：actual != expected 时记录错误
let s:errors = []
function! s:assert_equal(expected, actual, msg) abort
    if a:expected != a:actual
        call add(s:errors, a:msg . ': expected ' .
            \ string(a:expected) . ', got ' . string(a:actual))
    endif
endfunc

" 断言屏幕某位置包含指定文本
function! s:assert_screen(row, col, expected, msg) abort
    let width = strdisplaywidth(a:expected)
    let actual = s:screen_capture(a:row, a:col, width)
    call s:assert_equal(a:expected, actual, a:msg)
endfunc

" ── 3. 模拟用户输入 ──────────────────────────────────
"
" 关键技巧：dialog 的主循环使用 getchar() 等待输入，
" 可以用 feedkeys() 预先注入按键序列，使 dialog 在无人
" 交互下完成输入并退出。
"
" feedkeys() 的 't' 标志表示按键被当作用户输入（触发映射），
" 'x' 标志表示立即执行（不等待 getchar 返回）。
"
" 示例：输入 "hello"，然后按 Tab 切换焦点，再按 Enter 确认
"   call feedkeys("hello\<Tab>\<CR>", 't')

" ── 4. 测试用例 ──────────────────────────────────────

function! s:test_basic_render() abort
    " 构造对话框
    let items = [
        \ {'type': 'label', 'text': 'Hello Dialog:'},
        \ {'type': 'input', 'name': 'name', 'prompt': 'Name:',
        \  'value': 'test'},
        \ {'type': 'check', 'name': 'flag', 'text': 'Enable'},
        \ {'type': 'button', 'name': 'confirm',
        \  'items': [' &OK ', ' &Cancel ']},
        \ ]

    " 预注入按键：直接按 ESC 关闭对话框
    " 如需测试输入：feedkeys("hello\<Tab>\<Space>\<Tab>\<CR>", 't')
    call feedkeys("\<ESC>", 't')

    let result = quickui#dialog#open(items, {
        \ 'title': 'Test', 'w': 40})

    " 验证返回值
    call s:assert_equal('', result.button, 'ESC should cancel')
    call s:assert_equal(-1, result.button_index, 'cancel index')
endfunc

function! s:test_input_and_submit() abort
    let items = [
        \ {'type': 'input', 'name': 'name', 'prompt': 'Name:'},
        \ {'type': 'button', 'name': 'confirm',
        \  'items': [' &OK ', ' &Cancel ']},
        \ ]

    " 预注入：输入 "skywind" → Tab 到按钮 → Enter 确认
    call feedkeys("skywind\<Tab>\<CR>", 't')

    let result = quickui#dialog#open(items, {
        \ 'title': 'Test', 'w': 40})

    call s:assert_equal('confirm', result.button, 'button name')
    call s:assert_equal(0, result.button_index, 'OK index')
    call s:assert_equal('skywind', result.name, 'input value')
endfunc

function! s:test_screen_content() abort
    " 测试渲染后的屏幕内容
    let items = [
        \ {'type': 'label', 'text': 'Screen Test:'},
        \ {'type': 'check', 'name': 'flag', 'text': 'Enable',
        \  'value': 1},
        \ {'type': 'button', 'name': 'confirm',
        \  'items': [' &OK ']},
        \ ]

    " 注入一个 timer 延迟检查屏幕（在 dialog 显示期间）
    " 然后注入 ESC 关闭
    let s:screen_ok = 0
    function! s:check_screen(timer) closure
        " 把当前屏幕 dump 到文件供外部审查
        call s:screen_dump('test_dialog_screen.txt')

        " 也可以直接断言屏幕内容
        " 假设对话框居中显示，label 在某行某列
        " 具体坐标取决于 lines/columns 和对话框尺寸
        " call s:assert_screen(row, col, '[x] Enable', 'checkbox')

        let s:screen_ok = 1
        " 注入 ESC 关闭对话框
        call feedkeys("\<ESC>", 't')
    endfunc

    " 50ms 后检查屏幕（足够 dialog 渲染完毕）
    call timer_start(50, function('s:check_screen'))

    let result = quickui#dialog#open(items, {
        \ 'title': 'Test', 'w': 40})

    call s:assert_equal(1, s:screen_ok, 'screen check executed')
endfunc

" ── 5. 运行所有测试并汇报结果 ─────────────────────────

call s:test_basic_render()
call s:test_input_and_submit()
call s:test_screen_content()

" ── 6. 输出结果并退出 ─────────────────────────────────
if len(s:errors) == 0
    call writefile(['ALL PASSED'], 'test_dialog_result.log')
    qa!      " 退出码 0 —— 成功
else
    let report = ['FAILED: ' . len(s:errors) . ' error(s)'] + s:errors
    call writefile(report, 'test_dialog_result.log')
    cq 1     " 退出码 1 —— 测试失败
endif
```

#### 技术要点

##### 屏幕尺寸控制

```vim
" --cmd 在加载任何文件前执行，确保尺寸在 dialog 渲染前就绑定
" 终端 Vim 的 lines/columns 可能被终端模拟器覆盖，
" gvim 则可以可靠地设置任意尺寸：
"   gvim --cmd "set lines=30 columns=80" -S test.vim
"
" 脚本内必须校验实际尺寸是否符合预期
```

##### feedkeys() 模拟输入

```vim
" feedkeys(keys, flags) 的关键 flags：
"   't' — 当作从终端输入（触发映射和 typeahead）
"   'x' — 立即处理（不等待返回主循环）
"   'n' — 不重新映射
"
" dialog 主循环用 getchar() 阻塞等待输入，
" feedkeys 注入的按键会被 getchar() 依次消费。
"
" 时序：feedkeys() 在调用 dialog#open() 之前执行，
" 按键被放入 typeahead 缓冲区，dialog 启动后
" getchar() 立即从缓冲区取到按键。

" 示例：完整的表单填写流程
call feedkeys("John\<Tab>john@test.com\<Tab>\<Right>\<Tab>\<Space>\<Tab>\<CR>", 't')
"             ^^^^^ input1  ^^^^^^^^^^^^^ input2  ^^^^^^ radio   ^^^^^^ check  ^^ button
```

##### screenstring() 屏幕捕获

```vim
" screenstring(row, col) — 返回屏幕指定位置的字符
"   row: 1-based 行号（1 = 屏幕最顶行）
"   col: 1-based 列号（1 = 最左列）
"   返回值：单个字符的字符串（多字节字符返回完整字符）
"
" screenchars(row, col) — 返回字符码点列表
"   用于精确比对 Unicode 字符
"
" screenattr(row, col) — 返回屏幕属性（高亮信息）
"   可以用来验证高亮是否正确应用
"
" 注意：必须在 redraw 之后调用，否则屏幕内容可能未更新。
" 在 dialog 主循环中，可以通过 timer_start() 延迟回调
" 来在 redraw 之后捕获屏幕。
```

##### timer_start() 延迟验证

```vim
" 对于需要在 dialog 显示期间验证屏幕内容的场景，
" 不能在 feedkeys 中直接做（feedkeys 的按键被 dialog 消费了）。
" 解决办法：用 timer_start() 注册一个延迟回调，
" dialog 显示并 redraw 后，timer 触发，在回调中：
"   1. 调用 screenstring() 验证屏幕
"   2. 调用 s:screen_dump() 保存屏幕快照
"   3. 注入 feedkeys("\<ESC>") 关闭 dialog
"
" timer 的延迟建议 50-100ms，足够 dialog 完成首次渲染。
```

##### :cq 退出码

```vim
" :cq [N] — 以错误码 N 退出 Vim（默认 N=1）
" :qa!     — 正常退出，退出码为 0
"
" 约定：
"   0 — 所有测试通过
"   1 — 测试失败（断言不匹配）
"   2 — 环境问题（屏幕尺寸不对等）
"
" 外部 shell 检查：
"   vim ... -S test.vim; echo $?
```

##### screen dump 供外部审查

```vim
" 当断言条件难以精确预知（如对话框居中位置取决于尺寸计算），
" 可以将整个屏幕 dump 到文本文件，由 coding agent 读取
" 文件内容进行视觉审查：
"
"   call s:screen_dump('test_dialog_screen.txt')
"
" 文件格式为纯文本，每行对应屏幕一行，可直接阅读。
" agent 读取后可以检查：
"   - 对话框边框是否完整
"   - 控件文本是否正确渲染
"   - 焦点高亮位置是否正确（通过 screenattr 辅助判断）
```

#### 外部调用流程

```bash
# 1. coding agent 生成/修改 dialog.vim 代码
# 2. 启动 Vim 执行自动化测试
vim -u NONE -N -i NONE -n \
    --cmd "set lines=30 columns=80" \
    -S tools/test/test_dialog_auto.vim

# 3. 检查退出码
if [ $? -eq 0 ]; then
    echo "PASS"
else
    echo "FAIL — see test_dialog_result.log"
    cat test_dialog_result.log
fi

# 4. 可选：读取 screen dump 文件进行视觉审查
cat test_dialog_screen.txt
```

对于 Windows 环境，等效的调用方式：

```cmd
vim -u NONE -N -i NONE -n ^
    --cmd "set lines=30 columns=80" ^
    -S tools/test/test_dialog_auto.vim
echo Exit code: %ERRORLEVEL%
type test_dialog_result.log
```
