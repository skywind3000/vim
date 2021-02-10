# vim

个人 Vim 配置，不一定适合每个人，选择你需要的整合到自己配置中：

配置入口是 init.vim，主要配置集中在 init 目录下面。

(本文档严重滞后于功能，懒得更新了)


## Install


### Linux:

- 新建 `~/.vim` 目录，把项目克隆到 `~/.vim/vim` 下面：

```bash
cd ~/.vim
git clone https://github.com/skywind3000/vim.git
```

- 编辑 `~/.vimrc` 文件，里面加一行：

```VimL
so ~/.vim/vim/init.vim
so ~/.vim/vim/skywind.vim
```

### Windows:

- 新建 `D:\github` 目录，把项目克隆到 `D:\github\vim` 下面：

```batch
d:
cd \github
git clone https://github.com/skywind3000/vim.git
```

- 新建 `C:\Users\YourName\.vim` 目录：

```batch
C:\
CD \Users\YourName
mkdir .vim
```

- 编辑 `C:\Users\YourName\_vimrc` 文件，里面加一行：

```VimL
so d:/github/vim/init.vim
so d:/github/vim/skywind.vim
```

### 包管理：

在你的 `.vimrc` 文件中加入相关包配置：

```VimL
let g:bundle_group = ['simple', 'basic', 'inter', 'opt', 'ale', 'echodoc']
so ~/.vim/vim/bundle.vim
```

Windows 下修改对应目录。

本配置依个人习惯，将 tabsize shiftwidth 等设置成了 4个字节宽度，并且关闭了 expandtab，不喜欢的话可以在 source 了两个文件以后覆盖该设置。

## Keymap

### 光标移动

除了 NORMAL 模式 HJKL 移动光标外，新增加所有模式的光标移动快捷键：

| 按键    | 说 明    |
| :-----: | ------   | 
| C-H | 光标左移 |
| C-J | 光标下移 |
| C-K | 光标上移 |
| C-L | 光标右移 |

这样 INSERT下面移动几个字符，或者 COMMAND 模式下左右上下移动都都可以这么来。不喜欢可以后面 unmap 掉，但是有时候稍微移动一下还要去切换模式挺蛋疼的。

大部分默认终端都没问题，一些老终端软件，如 Xshell/SecureCRT，需要确认一下 Backspace 键的编码为 127 (`CTRL-?`) 或者勾选 Backspace sends delete，保证按下 BS 键时发送 ASCII 码 127 而不是 8 (`CTRL-H`) 。

### 插入模式

| 按键    | 说 明    |
| :-----: | ------   | 
| C-A | 移动到行首 |
| C-E | 移动到行尾 |
| C-D | 光标上移 |

### 命令模式

| 按键    | 说 明    |
| :-----: | ------   | 
| C-A | 移动到行首 |
| C-E | 移动到行尾 |
| C-D | 光标上移 |
| C-P | 历史上一条命令 |
| C-N | 历史下一条命令 |

### 窗口跳转

| 按键    | 说 明    |
| :-----: | ------   | 
| TAB h | 同 CTRL-W h |
| TAB j | 同 CTRL-W j |
| TAB k | 同 CTRL-W k |
| TAB l | 同 CTRL-W l |

先按 TAB键，再按 HJKL 其中一个来跳转窗口。


### TabPage 

除了使用原生的 TabPage 切换命令 `1gt`, `2gt`, `3gt` ... 来切换标签页外，定义了如下几个快捷命令：

| 按键    | 说 明    |
| :-----: | ------   |
| \1  | 先按反斜杠 `\`再按 `1`，切换到第一个标签页 |
| \2  | 切换到第二个标签页 |
| ... | ... |
| \9  | 切换到第九个标签页 |
| \0  | 切换到第十个标签页 |
| \t  | 新建标签页，等同于 `:tabnew` |
| \g  | 关闭标签页，等同于 `:tabclose` |
| TAB n | 下一个标签页，同 `:tabnext` |
| TAB p | 上一个标签页，同 `:tabprev` |

还可以使用 ALT+1 到 ALT+9 来切换，前提是终端软件需要配置一下，有些终端 ALT_1 到 ALT_9 被用来切换 connection 的 tab，那么可以把 ALT+SHIFT+1-9 配置成发送字符串：`\0331` 到 `\0339` 等几个不同字符串，其中 `\033` 是 ESC键的编码，这样不影响终端软件的 ALT_1-9 情况下，用 ALT_SHIFT_1-9 来代替。


### 通用按键

| 按键    | 说 明                                                                     |
| :-----: | ------                                                                    |
| F5      | 运行当前程序，自动检测 C/Python/Ruby/Shell/JavaScript，并调用正确命令运行 |
| F7      | 调用 emake 编译当前项目， $PATH 中需要有 emake 可执行                     |
| F9      | 调用 gcc 编译当前 C/C++ 程序，$PATH 中需要有 gcc可执行，编译到当前目录下  |
| F10   | 打开/关闭 quickfix                        |
| F11   | 打开【开发者目录】 |
| F12/S-F10 | 打开【主目录】|



### 文件浏览

该功能主要是使用 Vim 自带的 dirvish/netrw 被编辑文件的目录，方便各种方式切换文件

| 按键 | 说明 |
|:----:|------|
|  +  | 在当前窗口打开文件浏览器，浏览之前文件所在目录  |
|  TAB 6  | 在左边新窗口打开文件浏览器，浏览之前文件所在目录  |
|  TAB 7  | 在右边新窗口打开文件浏览器，浏览之前文件所在目录  |
|  TAB 8  | 在下边新窗口打开文件浏览器，浏览之前文件所在目录  |
|  TAB 9  | 在新标签打开文件浏览器，浏览之前文件所在目录  |

使用 `+` 返回当前文件所在目录时，如果文件被修改过未保存，且 Vim 没有设置 hidden，则会在该文件窗口上面打开目录浏览，不会把文件关掉。 

当文件浏览器打开以后，按 `~` 键，返回用户目录（$HOME）；按 `反引号`（1左边那个键），返回项目根目录，详细见：[Vinegar](https://github.com/skywind3000/vim/wiki/Vim-Vinegar-and-Oil)。
