# QuickUI Dialog 使用指南

`quickui#dialog#open()` 提供数据驱动的对话框功能。你只需声明控件列表，即可弹出包含输入框、单选、复选、按钮等控件的对话框，用户交互完毕后返回所有控件的值。

## 快速上手

```vim
let items = [
    \ {'type': 'label', 'text': 'Please fill in:'},
    \ {'type': 'input', 'name': 'username', 'prompt': 'Name:', 'value': 'skywind'},
    \ {'type': 'input', 'name': 'email', 'prompt': 'Email:'},
    \ {'type': 'button', 'name': 'confirm', 'items': [' &OK ', ' &Cancel ']},
    \ ]

let result = quickui#dialog#open(items, {'title': 'User Info'})

if result.button ==# 'confirm' && result.button_index == 1
    echo 'Name: ' . result.username
    echo 'Email: ' . result.email
endif
```

效果：

```
┌─ User Info ──────────────────────────────┐
│                                           │
│  Please fill in:                          │
│                                           │
│  Name:  [skywind                       ]  │
│  Email: [                              ]  │
│                                           │
│            < OK >    < Cancel >            │
│                                           │
└───────────────────────────────────────────┘
```

## API

```vim
let result = quickui#dialog#open(items [, opts])
```

- `items` — `List<Dict>`，每个元素描述一个控件
- `opts` — `Dict`（可选），对话框级别选项
- 返回 — `Dict`，包含所有控件值和退出状态

## 控件类型

### label — 静态文本

不可聚焦，用于显示说明文字。

```vim
{'type': 'label', 'text': 'Please fill in the form:'}
{'type': 'label', 'text': ['Line 1', 'Line 2']}   " 多行
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | String | 是 | `'label'` |
| `text` | String / List | 是 | 显示文本。String 按 `\n` 拆行，List 每元素一行 |

### input — 单行输入框

可聚焦，内置 readline 编辑能力（光标移动、选择、剪贴板、历史浏览）。

```vim
{'type': 'input', 'name': 'username', 'prompt': 'Name:', 'value': 'skywind'}
```

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | String | 是 | — | `'input'` |
| `name` | String | 是 | — | 控件名称，用作返回值键名 |
| `prompt` | String | 否 | `''` | 左侧标签文本 |
| `value` | String | 否 | `''` | 初始文本 |
| `history` | String | 否 | `''` | 历史记录命名空间（多次调用共享历史） |

**编辑快捷键**（焦点在 input 上时）：

| 按键 | 动作 |
|------|------|
| 普通字符 | 插入 |
| `Left` / `Right` | 移动光标 |
| `Home` / `End` | 行首/行尾 |
| `Ctrl+A` / `Ctrl+E` | 行首/行尾 |
| `Backspace` / `Delete` | 删除字符 |
| `Ctrl+K` / `Ctrl+U` | 删除到行尾/行首 |
| `Ctrl+W` | 删除前一个单词 |
| `Shift+Left/Right` | 选择文本 |
| `Ctrl+C` / `Ctrl+V` | 复制/粘贴 |
| `Ctrl+Up` / `Ctrl+Down` | 浏览历史 |
| `Enter` | 确认对话框 |
| `Up` / `Down` | 焦点切换到上/下控件 |
| `Tab` / `S-Tab` | 焦点前进/后退 |

### radio — 单选组

可聚焦，用 Left/Right/Space 切换选项。

```vim
{'type': 'radio', 'name': 'role', 'prompt': 'Role:',
 \ 'items': ['&Dev', '&QA', '&PM'], 'value': 0}
```

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | String | 是 | — | `'radio'` |
| `name` | String | 是 | — | 控件名称 |
| `prompt` | String | 否 | `''` | 左侧标签 |
| `items` | List | 是 | — | 选项文本列表，`&` 标记快捷键 |
| `value` | Number | 否 | `0` | 默认选中项索引（0-based） |
| `vertical` | Number | 否 | auto | `0` 强制水平，`1` 强制垂直，不指定时自动 |

水平布局：`Role:  (*) Dev  ( ) QA  ( ) PM`

垂直布局（选项过宽时自动切换）：
```
Role:  (*) Development
       ( ) Quality Assurance
       ( ) Project Management
```

| 按键 | 动作 |
|------|------|
| `Left` / `h` | 选上一项 |
| `Right` / `l` / `Space` | 选下一项 |
| `Enter` | 确认对话框 |
| `Up` / `Down` | 焦点切换 |

### check — 复选框

可聚焦，Space 切换勾选状态。

```vim
{'type': 'check', 'name': 'admin', 'text': '&Administrator'}
{'type': 'check', 'name': 'notify', 'text': 'Send &notification', 'value': 1}
```

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | String | 是 | — | `'check'` |
| `name` | String | 是 | — | 控件名称 |
| `text` | String | 是 | — | 显示文本，`&` 标记快捷键 |
| `prompt` | String | 否 | `''` | 左侧标签（设置后参与 prompt 对齐组） |
| `value` | Number | 否 | `0` | 0=未选中，1=选中 |

布局：`[x] Administrator` 或 `Admin:  [x] Administrator`（有 prompt 时）

| 按键 | 动作 |
|------|------|
| `Space` | 切换勾选 |
| `Enter` | 确认对话框 |
| `Up` / `Down` | 焦点切换 |

### button — 按钮行

可聚焦，按钮居中排列。激活任何按钮都会关闭对话框。

```vim
{'type': 'button', 'name': 'confirm', 'items': [' &OK ', ' &Cancel ']}
```

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `type` | String | 是 | — | `'button'` |
| `name` | String | 否 | `'button'` | 控件名称 |
| `items` | List | 是 | — | 按钮文本列表，`&` 标记快捷键 |
| `value` | Number | 否 | `0` | 默认聚焦按钮索引（0-based） |

布局：`< OK >    < Cancel >`

| 按键 | 动作 |
|------|------|
| `Left` / `h` | 切换到左按钮 |
| `Right` / `l` | 切换到右按钮 |
| `Space` / `Enter` | 激活当前按钮，关闭对话框 |

## 对话框选项

通过第二个参数 `opts` 传递：

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | String | `'Dialog'` | 标题文本 |
| `w` | Number | auto | 内容区宽度（不指定则自动计算） |
| `min_w` | Number | `40` | 自动宽度的下限 |
| `border` | Number | `g:quickui#style#border` | 边框样式 |
| `center` | Number | `1` | 是否居中 |
| `padding` | List | `[1,1,1,1]` | 内边距 `[top, right, bottom, left]` |
| `color` | String | `'QuickBG'` | 背景高亮组 |
| `bordercolor` | String | `'QuickBorder'` | 边框高亮组 |
| `gap` | Number | `1` | 不同类型控件间的空行数 |
| `button` | Number | `1` | 是否显示关闭按钮 |
| `focus` | String | — | 初始焦点控件的 name |

## 返回值

返回一个 Dict，**无论确认还是取消，始终包含所有控件的当前值**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `button` | String | 触发退出的按钮 name；`'enter'`=从非 button 控件按 Enter；`''`=取消 |
| `button_index` | Number | 按钮索引（**1-based**）；Enter 确认=`0`；取消=`-1` |
| `<input.name>` | String | 文本框内容 |
| `<radio.name>` | Number | 选中项索引（0-based） |
| `<check.name>` | Number | 勾选状态（0/1） |

### 判断退出方式

```vim
let r = quickui#dialog#open(items, opts)

" 用户按了 OK 按钮（button name='confirm'，OK 是第1个按钮）
if r.button ==# 'confirm' && r.button_index == 1
    " 处理确认逻辑
endif

" 用户从 input/radio/check 上按了 Enter
if r.button ==# 'enter'
    " 处理 Enter 确认
endif

" 用户取消（ESC / Ctrl-C / 关闭按钮）
if r.button ==# ''
    " 取消处理（r 中仍包含用户已填写的值）
endif
```

## 快捷键

button、radio、check 的文本中用 `&` 标记快捷键字符（如 `' &OK '` 中 `O` 是快捷键）。

- **button 快捷键** → 直接激活按钮，关闭对话框
- **radio 快捷键** → 选中对应选项，不关闭
- **check 快捷键** → 切换勾选，不关闭

快捷键在焦点不在 input 上时全局有效。焦点在 input 上时，所有字符都作为输入处理，不触发快捷键。

## 焦点导航

| 按键 | 动作 |
|------|------|
| `Tab` | 焦点前进到下一个控件（循环） |
| `Shift-Tab` | 焦点后退到上一个控件（循环） |
| `Up` | 焦点后退（纵向直觉） |
| `Down` | 焦点前进（纵向直觉） |

初始焦点默认在第一个可聚焦控件上。可通过 `opts.focus` 指定初始焦点：

```vim
let result = quickui#dialog#open(items, {'focus': 'email'})
```

## 布局规则

### 垂直堆叠

控件按 `items` 顺序从上到下排列。

### 空行分隔

- 不同类型的相邻控件之间插入 `gap` 行空行（默认 1 行）
- 相同类型的相邻控件之间**不插入**空行，形成视觉分组

### prompt 对齐

连续的带 prompt 的控件（input、radio、有 prompt 的 check）自动对齐：

```
Name:   [skywind                       ]
Email:  [                              ]
Role:   (*) Dev  ( ) QA  ( ) PM
```

label 不打断对齐组，无 prompt 的交互控件才会打断。

## 鼠标支持

- 点击 input → 聚焦并定位光标
- 点击 radio 选项 → 聚焦并选中该项
- 点击 check → 聚焦并切换勾选
- 点击 button → 激活该按钮，关闭对话框
- 点击关闭按钮（X） → 取消

## 完整示例

### 用户表单

```vim
let items = [
    \ {'type': 'label', 'text': 'Please fill in the user form:'},
    \ {'type': 'input', 'name': 'username', 'prompt': 'Name:',
    \  'value': 'skywind'},
    \ {'type': 'input', 'name': 'email', 'prompt': 'Email:'},
    \ {'type': 'radio', 'name': 'role', 'prompt': 'Role:',
    \  'items': ['&Dev', '&QA', '&PM'], 'value': 0},
    \ {'type': 'check', 'name': 'admin', 'text': '&Administrator'},
    \ {'type': 'check', 'name': 'notify', 'text': 'Send &notification',
    \  'value': 1},
    \ {'type': 'button', 'name': 'confirm',
    \  'items': [' &OK ', ' &Cancel ']},
    \ ]

let result = quickui#dialog#open(items, {
    \ 'title': 'User Form', 'w': 50})

if result.button ==# 'confirm' && result.button_index == 1
    echo 'User: ' . result.username
    echo 'Email: ' . result.email
    echo 'Role: ' . result.role
    echo 'Admin: ' . result.admin
    echo 'Notify: ' . result.notify
endif
```

### 简单确认对话框

```vim
let items = [
    \ {'type': 'label', 'text': 'Are you sure you want to delete this file?'},
    \ {'type': 'button', 'name': 'confirm',
    \  'items': [' &Yes ', ' &No ']},
    \ ]

let result = quickui#dialog#open(items, {'title': 'Confirm Delete'})

if result.button ==# 'confirm' && result.button_index == 1
    echo 'Deleted!'
endif
```

### 带历史的搜索框

```vim
let items = [
    \ {'type': 'input', 'name': 'pattern', 'prompt': 'Search:',
    \  'history': 'dialog_search'},
    \ {'type': 'check', 'name': 'case', 'text': 'Case &sensitive'},
    \ {'type': 'check', 'name': 'regex', 'text': 'Use &regex', 'value': 1},
    \ {'type': 'button', 'name': 'action',
    \  'items': [' &Find ', ' &Replace ', ' &Cancel ']},
    \ ]

let result = quickui#dialog#open(items, {
    \ 'title': 'Find and Replace', 'w': 50})
```

### 纯 label + Enter 退出

```vim
let items = [
    \ {'type': 'label', 'text': [
    \   'Build completed successfully!',
    \   '',
    \   'Output: /tmp/build/output',
    \   'Time: 3.2s',
    \ ]},
    \ {'type': 'button', 'name': 'done', 'items': [' &OK ']},
    \ ]

let result = quickui#dialog#open(items, {'title': 'Build Result'})
```

## 注意事项

1. **name 必须唯一** — 所有带 name 的控件不能重名
2. **多 button 行需不同 name** — 默认 name 是 `'button'`，多个 button 必须各指定不同 name
3. **快捷键不能重复** — 不同控件的 `&` 快捷键字符不能冲突
4. **button_index 是 1-based** — 与 `quickui#confirm#open()` 一致，第一个按钮返回 1
5. **高度限制** — 控件总行数不能超出屏幕高度，否则报错
6. **取消时值仍保留** — ESC 取消后返回值中仍包含用户已修改的控件值，方便重新打开时恢复
