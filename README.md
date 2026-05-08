# switchboard.nvim

A Neovim plugin for executing build and run commands in tmux panes, splits, or floating windows without leaving the editor. Features:

- Execute commands in overlay windows, splits, or tmux background windows
- Configure commands by file extension, project, or globally
- Automatic tmux detection with terminal fallback
- Tab completion for configured commands

## Installation

Install with any plugin manager. For example, with the inbuilt one in `NeoVim 0.12+`:

```lua
vim.pack.add({
    'https://github.com/karshPrime/switchboard.nvim',
})
```

## Configuration

```lua
require('switchboard').setup({
    -- General settings (optional)
    save_session = false,             -- Save files before executing
    build_run_window_title = "build", -- Tmux window name
    notify_missing_project_config = false,
    local_config = ".commands",

    -- Window sizing (optional)
    new_pane_everytime = false,
    side_width_percent = 50,
    bottom_height_percent = 30,
    overlay_width_percent = 80,
    overlay_height_percent = 80,
    overlay_sleep = -1,               -- -1 = no auto-close

    -- Global commands (all file types)
    commands = {
        yazi = 'yazi',
        lazygit = 'lazygit',
    },

    -- Extension-specific commands
    build_run_config = {{
            extension = {'c', 'cpp'},
            commands = {
                build = 'make',
                run = 'make run',
            }
        },{
            extension = {'rs'},
            commands = {
                build = 'cargo build',
                run = 'cargo run',
                anyKeywordCommand = 'echo example rust only command'
            }
        },
    },

    -- Project-specific overrides
    project_override_config = {{
            project_base_dir = '~/Projects/MyProject',
            commands = {
                build = 'make build',
                run = 'make run',
            }
        },
    }
})
```

## Usage

### Running Commands

```
:Switchboard <mode> <command>
```

**Modes** (built-in):

- `overlay` - Floating window
- `split` - Vertical split (right side)
- `vsplit` - Horizontal split (bottom)
- `background` - New tmux window

**Commands** (user-defined in config):
Commands are defined in the configuration under `build_run_config[].commands`, `commands`, or `project_override_config[].commands`. Available commands depend on the current file's extension and project configuration (like in the example above).

### Examples

```lua
-- Bind F5 to run in a new pane on right
vim.keymap.set('n', '<F5>', ':switchboard split run<CR>', {silent=true})

-- Bind F6 to build under the active pane
vim.keymap.set('n', '<F6>', ':switchboard vsplit build<CR>', {silent=true})

-- Bind F7 to run yazi on overlay
vim.keymap.set('n', '<F6>', ':switchboard overlay yazi<CR>', {silent=true})
```

### Project Configuration

Create a `switchboard.lua` file in the project root (or custom `local_config` specified in the config):
```lua
return {
    commands = {
        run = 'npm start',
        build = 'npm run build',
        test = 'npm test',
    }
}
```

