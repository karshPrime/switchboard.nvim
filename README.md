# switchboard.nvim

Neovim plugin designed to simplify the process of compiling and running projects
within tmux panes or windows. Supports multiple programming languages by
allowing customisation of build and run commands.

Also supports running [lazygit](https://github.com/jesseduffield/lazygit) from
within current Neovim session on an overlay terminal.

![preview](.media/screenshot.gif)
<br>
[editor theme above](https://github.com/karshPrime/tokyoburn.nvim)

## Install & Setup

Install using your favorite plugin manager. For example, using
[lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{ 'karshPrime/switchboard.nvim', event = 'VeryLazy' },
```
And setup it with:
```lua
require('switchboard').setup({
    -- Overriding Default Configurations. [OPTIONAL]
    save_session = false,             -- Save file before action (:wall)
    build_run_window_title = "build", -- Tmux window name for Build/Run
    ---- same window pane
    new_pane_everytime = false,       -- Use existing side panes for action, when false
    side_width_percent = 50,          -- Side pane width percentage
    bottom_height_percent = 30,       -- Bottom pane height percentage
    ---- overlay window
    overlay_width_percent = 80,       -- Overlay width percentage
    overlay_height_percent = 80,      -- Overlay height percentage
    overlay_sleep = 1,                -- Pause before overlay autoclose; seconds
                                      -- By default it sets value to -1,
                                      -- indicating not to autoclose overlay

    -- Languages' Run and Build actions.  [REQUIRED]
    build_run_config = {
        {
            extension = {'c', 'cpp', 'h'},
            build = 'make',
            run   = 'make run',
            debug = 'lldb',
        },
        {
            extension = {'rs'},
            build = 'cargo build',
            run   = 'cargo run',
            -- not all properties are required for all extensions
        },
        {
            extension = {'go'},
            run = 'go run .',
            -- Run would work for golang
            -- but Build and Debug will return errors informing configs are
            -- missing
        }
    },

    -- Directory override config. [OPTIONAL] 
    -- Set actions for a specific directory (per project basis)
    project_override_config = {
        {
            project_base_dir = '/absolute/path/to/project',
            build = 'make',
            run   = 'make run',
            debug = 'lldb',
        },
        {
            project_base_dir = '~/Projects/ESP32/',
            build = 'idf.py build',
            run   = 'idf.py flash /dev/cu.usbmodem1101'
            -- Only build will work for this path
        }
    }
})

```

## Keybinds

Create keybindings for any command by adding the following to Neovim config:

```lua
vim.keymap.set('n', 'KEYBIND', 'COMMAND<CR>', {silent=true})
```
Example: to set F5 to compile and run current project in an overlay terminal
window-
```lua
vim.keymap.set('n','<F5>', ':Switchboard Run<CR>', {silent=true})
```

### List of all supported commands

| Action / Purpose                                        | Command               |
|---------------------------------------------------------|-----------------------|
| Compile program in an overlay terminal window           | `:Switchboard Make`   |
| Compile program in a new tmux window                    | `:Switchboard MakeBG` |
| Compile program in a new pane next to current nvim pane | `:Switchboard MakeV`  |
| Compile program in a new pane bellow current nvim pane  | `:Switchboard MakeH`  |
| Run program in an overlay terminal window               | `:Switchboard Run`    |
| Run program in a tmux new window                        | `:Switchboard RunBG`  |
| Run program in a new pane next to current nvim pane     | `:Switchboard RunV`   |
| Run program in a new pane bellow current nvim pane      | `:Switchboard RunH`   |
| Start debugger in an overlay terminal window            | `:Switchboard Debug`  |
| Start debugger in a tmux new window                     | `:Switchboard DebugBG`|
| Start debugger in a new pane next to current nvim pane  | `:Switchboard DebugV` |
| Start debugger in a new pane bellow current nvim pane   | `:Switchboard DebugH` |
| Open lazygit in overlay                                 | `:Switchboard lazygit`|

\* **Run** here includes both compiling and running the program, depending on the
run command specified for the file extension.

<details>
<summary>Important Notice: Backward Compatibility Break v1 -> v2</summary>
Please note that backward compatibility is broken from Version 1 to Version 2
due to the implementation of a more robust configuration system. In the previous
version, user configuration consisted of a simple list of extensions with their
associated make and run command properties. However, with the introduction of
overlay functionality, it became necessary to add an identifier to this
previously unnamed list, resulting in incompatibility with older configurations.
<br>
Apologies for any inconvenience this may cause. From version 2, the plugin has been
designed with future-proofing in mind to ensure that such issues do not recur.
</details>

