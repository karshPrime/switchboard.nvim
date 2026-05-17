# switchboard.nvim

Switchboard lets you run project commands without leaving Neovim. It picks the right command based on the file or project and runs it in a split, floating window, or tmux.

It’s designed so the same keybinds work across different languages and projects.

### What it does

* Runs commands in splits, floating windows, or tmux
* Supports project-aware editor actions (dynamic vim keybinds)
* Chooses commands based on file type or project
* Falls back to `:term` if tmux isn’t available
* Lets you define your own commands (build, run, or anything else)
* Supports local project-specific overrides




## Installation

Using the built-in package manager (Neovim 0.12+):

```lua
vim.pack.add({
    'https://github.com/karshPrime/switchboard.nvim',
})
```



## Basic idea

You define what “run”, “build”, or any editor action means per language or project:

```lua
require('switchboard').setup({
    commands = {
        lazygit = "lazygit",
    },
    build_run_config = {{
        extension = {'py'},
        commands  = {
            run   = 'uv run main',
            build = 'uv run pyinstaller bin ./*/__main__.py',
        },
        binds = {
            divide = 'I#<Esc>79A=<Esc>o',
            import = 'Iimport ',
        }
    },{
        extension = {'c', 'cpp', 'h'},
        cd_root   =  true,
        commands  = {
            run   = 'make run',
            build = 'make',
            debug = 'gdb ./bin',
        },
        binds = {
            divide = 'I//<Esc>78A=<Esc>o',
            import = 'I#include ',
        }
    }}
})
```

Then you bind keys once, and reuse them everywhere:

```lua
-- Commands:
vim.keymap.set('n', '<F5>', ':Switchboard split run<CR>', { silent = true })
vim.keymap.set('n', '<F7>', ':Switchboard vsplit debug<CR>', { silent = true })  -- works only for C/C++ projects
vim.keymap.set('n', '<leader>g', ':Switchboard overlay lazygit<CR>', { silent = true }) -- works for all projects

-- Keybinds:
vim.keymap.set('n', '<leader>id', ':Switchboard bind divide<CR>', { silent = true })
vim.keymap.set({'n','i'}, '<leader>ii', '<Esc>:Switchboard bind import<CR>', { silent = true })

-- Append <Esc> before :Switchboard for insert mode maps

```

Switchboard handles the rest.




## Usage

### Commands
```vim
:Switchboard <mode> <command-name>
```
Modes:

* `overlay` – floating window overlay
* `split` – opens a horizontal split
* `vsplit` – opens a vertical split
* `background` – background tmux window (or background term buffer)


Commands come from:

* global neovim config
* file type config - in neovim config
* project overrides - in project root

So `run` in a Python project can mean something completely different from `run` in Rust.


### Binds
```vim
:Switchboard bind <bind-name>
```
Binds run configured editor actions. For example, divide can insert a Python-style divider in Python files and a C-style divider in C files.







## Example config

```lua
require('switchboard').setup({
    -- General settings (optional)
    save_session = false,             -- Save files before executing
    build_run_window_title = "build", -- Tmux window name
    notify_missing_project_config = false,
    local_config = ".switchboard-config",

    -- Window sizing (optional)
    new_pane_everytime     = false,
    side_width_percent     = 50,
    bottom_height_percent  = 30,
    overlay_width_percent  = 80,
    overlay_height_percent = 80,
    overlay_sleep = -1,    -- -1 = no auto-close

    build_run_config = {{
        ...
    }},

    -- Override individual projects configs
    -- Example: for zephyr projects, use zephyr to build instead of set C/C++ configs
    project_override_config = {{
        project_base_dir = '~/Projects/MyProject',
        commands = {
            build = 'west build',
        }
    }}
})
```
Alternatively, have a look at [my personal config](https://github.com/karshPrime/dotfiles/blob/main/nvim/lua/plugins/tmux.lua).



## Project-specific config

You can override commands per project by adding a file at the root:

```lua
-- .switchboard-config
return {
    cd_root   =  true,
    commands  = {
        run   = 'npm start',
        build = 'npm run build',
        test  = 'npm test',
    },
    binds = {
        import = 'ggOimport <Esc>',
    }
}
```



**In short:** define commands and editor actions once, use the same keybinds everywhere, and let Switchboard adapt to the project you’re in.


