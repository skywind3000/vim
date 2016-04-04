# vim
个人 Vim 配置，十分个人化，不一定每人都喜欢，选择你需要的整合到自己配置中，部分演示见：

https://www.zhihu.com/question/20833248/answer/186085007

主要功能都放到了 F12，F11 呼出的菜单里了。

(本文档严重滞后于功能，懒得更新了)


## Install

默认安装:

```bash
cd ~/github
git clone https://github.com/skywind3000/vim.git
echo "source '~/github/vim/asc.vim'" >> ~/.vimrc
```

额外可选:

```bash
echo "source '~/github/vim/skywind.vim'" >> ~/.vimrc
```

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

### Cscope / Pycscope / Ctags

虽然大多数环境下用 Grep比较方便，无需使用 ctags/cscope，但项目大了，经常同一个关键字 Grep 出一堆乱七八糟的不相关内容来。

| 按键 | 说明 |
|:----:|------|
|  g3  | 使用 cscope 查找函数的定义，需要生成 cscope 文件 |
|  g4  | 使用 cscope 查找函数的引用，需要生成 cscope 文件 |
|  g5  | 在预览窗口内查看光标下符号的定义，再按一次显示下一个，需要生成 ctags |
|  g6  | 调用 cscope 在当前 **项目目录** 扫描 C/C++ 代码，生成 cscope文件 .cscope |
|  g7  | 调用 pycscope 在当前 **项目目录** 扫描 Python 代码，生成 pycscope文件 .cscopy |
|  g9  | 调用 ctags 在当前 **项目目录** 扫描代码，生成 ctags文件 .tags |



