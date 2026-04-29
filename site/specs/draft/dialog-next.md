# Dialog 模块发展规划

> 基于 QuickUI 全部 18 个模块的代码分析、dialog.vim 的完整实现细节、
> 以及各组件在仓库中的实际调用情况，整理的发展建议。

## 现状

### QuickUI 组件矩阵

| 组件 | 定位 | 交互模式 | 实际调用量 |
|------|------|----------|-----------|
| `confirm` | 简单是/否/取消 | 按钮选择 | 中（经 drivers.vim） |
| `input` | 单行文本输入 | readline 编辑 | 中（经 drivers.vim） |
| `listbox` | 列表选择 | 上下滚动+回车 | 高（tools.vim 大量使用） |
| `context` | 右键菜单 | 点击/键盘 | 高（menu.vim 核心依赖） |
| `menu` | 顶部菜单栏 | 菜单导航 | 高（全局 UI） |
| `textbox` | 只读文本 | 滚动浏览 | 中 |
| `terminal` | 浮动终端 | shell 交互 | 低 |
| `preview` | 预览窗口 | 被动展示 | 中 |
| **`dialog`** | **多控件表单** | **复合交互** | **零** |

关键事实：**dialog 模块目前在整个仓库中零调用**。它是最强大的 UI 组件，但完全没有被集成到任何实际工作流中。

### 现有"多步骤交互"的痛点

目前仓库中需要收集多个信息时，典型做法是：

```vim
" 先弹 input 收集一个值
let name = quickui#input#open('Name:', '', 'name_hist')
if name == '' | return | endif
" 再弹 input 收集第二个值
let email = quickui#input#open('Email:', '', 'email_hist')
if email == '' | return | endif
" 再弹 confirm 让用户确认
let choice = quickui#confirm#open('Proceed?', "&Yes\n&No", 1)
```

这种**串行弹窗**体验很差——用户要连续关闭/打开多个窗口，无法回头修改前面的值，也看不到全局视图。dialog 正是为解决这个问题而生的。

---

## 发展优先级

按照**投入产出比**从高到低排序。

### 第一优先级：实际集成（价值最高，代码量最小）

dialog 最大的问题不是缺功能，而是**没有人用它**。应该先把它接入真实场景。

#### 1. 接入 `module#drivers.vim` 驱动层

drivers.vim 是所有 UI 调用的抽象层，目前只封装了 `input` 和 `confirm`。加一个 `asclib.ui.dialog` 接口，让所有模块都能方便调用 dialog：

```vim
function! s:quickui_dialog(items, opts) abort
    return quickui#dialog#open(a:items, a:opts)
endfunc
```

大约 10 行代码，但打通了整个调用链路。

#### 2. 替换现有串行弹窗场景

仓库里有几个天然适合 dialog 的场景：

| 场景 | 当前方式 | dialog 改造效果 |
|------|----------|----------------|
| AsyncTask 的 `$(VIM:xxx)` 变量输入 | 连续弹多个 `input#open` | 一个 dialog 收集所有变量 |
| GPT Commit 参数配置 | 散落的 `g:` 变量 | 对话框集中配置 model/key/style |
| 项目设置（project profile 切换） | `listbox` 选一个 | dialog 里 radio + input 组合 |
| 搜索替换 | `tools#input_search` 只能输入 pattern | dialog 里 input + check(大小写/正则) |

其中**搜索替换对话框**是最好的试点——use-dialog.md 里已经有现成的 "Find and Replace" 示例，实现成本极低，用户感知度极高。

### 第二优先级：补齐关键控件

在实际集成过程中，很快会发现现有 5 种控件不够用。

#### 3. `dropdown` 下拉列表（约 200 行）

这是最缺的控件。很多场景需要从较长的列表中选一个值（文件类型、编码、profile），radio 只适合 3-5 个选项，超过就撑爆布局。dropdown 折叠态只占 1 行，展开时复用 `listbox`。

用户 API 设想：

```vim
{'type': 'dropdown', 'name': 'lang', 'prompt': 'Language:',
 \ 'items': ['Python', 'C++', 'Rust', 'Go', 'Java'], 'value': 0}
```

折叠态显示：`Language:  [Python           v]`

实现要点：
- 折叠态在 dialog buffer 内渲染，只占 1 行
- 展开时在 dialog 之上弹出独立的 popup/float 窗口（复用 listbox）
- 需要计算下拉列表的屏幕绝对坐标（从 dialog 的 padding/border/行偏移推算）
- listbox 有自己的事件循环，天然形成模态子循环

主要复杂性在屏幕坐标计算和 Vim/Neovim 双平台 popup 坐标差异。

#### 4. `separator` 分隔线（约 15 行）

纯视觉元素，在控件之间画一条 `────` 分隔线。实现极简单（type=separator, line_count=1, focusable=0），但对复杂对话框的视觉分组帮助很大。

### 第三优先级：交互能力增强

#### 5. 字段校验与错误提示（约 60 行）

当前 dialog 没有验证机制。用户在 input 里输入了非法值，只能在 dialog 关闭后才发现。

思路：给 input 控件加一个可选的 `validate` 回调（FuncRef），Enter 确认前调用；校验失败时在控件下方显示一行红色错误文本，不关闭 dialog。

```vim
{'type': 'input', 'name': 'port', 'prompt': 'Port:',
 \ 'validate': {val -> val =~ '^\d\+$' ? '' : 'Must be a number'}}
```

把 dialog 从"收集数据"升级到"收集有效数据"。

#### 6. 动态控件联动

某个控件的值变化时，动态显示/隐藏其他控件。例如选了 "Custom" radio 后才出现额外的 input 框。

复杂度显著上升（需要重新 layout + 调整窗口大小），建议放在后面。

### 第四优先级：高级特性（远期）

| 特性 | 复杂度 | 说明 |
|------|--------|------|
| 多页 wizard | 高 | 分步骤的向导流程，适合复杂配置 |
| 异步/非模态 dialog | 高 | 不阻塞编辑，类似 IDE 的浮动面板 |
| 自定义渲染控件 | 高 | 允许用户自定义 render 函数 |
| 主题热切换 | 低 | dialog 打开时动态换肤 |

---

## 推荐行动路径

```
阶段 1 (切入点)
  |-- 接入 drivers.vim           <- ~10 行，打通调用链
  +-- 做一个真实的搜索替换对话框  <- ~50 行调用代码，验证 dialog 可用性

阶段 2 (补齐)
  |-- 加 separator 控件          <- ~15 行
  +-- 加 dropdown 控件           <- ~200 行

阶段 3 (增强)
  |-- 字段校验                   <- ~60 行
  +-- 更多实际场景替换            <- 逐步替换串行弹窗

阶段 4 (远期)
  +-- 动态联动 / wizard / 非模态
```

**核心结论**：dialog 最缺的不是新控件，而是**真实的使用场景**。先把它用起来（特别是搜索替换对话框），在使用中发现哪些控件和能力真正需要，再有针对性地补齐。
