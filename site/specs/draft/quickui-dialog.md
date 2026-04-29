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
