-- switchboard.nvim
-- Plugin to compile and run projects in tmux panes or windows

--# INITIALISE #----------------------------------------------------------------

local M = {}
M.config = {}

function M.setup(config)
    M.config = config
end

--# CHECK ENVIRONMENT #---------------------------------------------------------

-- confirm tmux is installed
local function is_tmux_installed()
    return vim.fn.executable("tmux") == 1
end

-- check if session is in tmux
local function is_tmux_running()
    return vim.env.TMUX ~= nil
end


--# HELPER FUNCTIONS #----------------------------------------------------------

-- get the file extension
local function get_file_extension()
    local filename = vim.api.nvim_buf_get_name(0)
    return filename:match("^.+(%..+)$"):sub(2)
end

-- get build and run commands based on file extension
local function get_commands_for_extension(extension)
    if extension then
        for _, cfg in ipairs(M.config) do
            if vim.tbl_contains(cfg.extension, extension) then
                return cfg.build, cfg.run
            end
        end
        print("Error: No build and run commands found for this extension")
    else
        print("Error: No file extension found")
    end
    return nil, nil
end

-- check if a tmux window with the given name exists
local function tmux_window_exists(window_name)
    local result = vim.fn.system("tmux list-windows | grep -w " .. window_name)
    return result ~= ""
end


--# CALL FUNCTIONS #------------------------------------------------------------

-- run command in a new or existing tmux window
local function new_window(cmd, new_cmd)
    local window_name = "build"

    if tmux_window_exists(window_name) then
        local proj_dir = vim.fn.trim(vim.fn.system("pwd"))
        local win_dir = vim.fn.trim(vim.fn.system("tmux display -p -t " .. window_name .. " '#{pane_current_path}'"))

        if win_dir ~= proj_dir then
            cmd = "cd " .. proj_dir .. "; " .. cmd
        end

        local cmd_head = "silent !tmux select-window -t " .. window_name
        vim.cmd(cmd_head .. " \\; send-keys '" .. cmd .. "' C-m")
    else
        local cmd_head = "silent !tmux new-window -n " .. window_name
        vim.cmd(cmd_head .. " '" .. cmd .. "; zsh'")
    end
end

-- run command in same window on a new pane
local function split_window(cmd, side)
    if cmd then
        local cmd_head = "silent !tmux split-window " .. side
        vim.cmd(cmd_head .. " '" .. cmd .. "; exec zsh'")
    else
        print("Error: No run command found for this extension")
    end
end


--# NVIM DISPATCH #-------------------------------------------------------------

-- call the appropriate function based on the option
function M.dispatch(option)
    if not is_tmux_installed() then
        print("Error: install TMUX to use the plugin")
        return 1
    end

    if not is_tmux_running() then
        print("Error: run session in TMUX")
        return 1
    end

    local extension = get_file_extension()
    local make, run = get_commands_for_extension(extension)

    if option == "RunBG" then
        new_window(run, true)
    elseif option == "RunV" then
        split_window(run, "-v")
    elseif option == "RunH" then
        split_window(run, "-h")
    elseif option == "MakeV" then
        split_window(make, "-v")
    elseif option == "MakeH" then
        split_window(make, "-h")
    elseif option == "Make" then
        new_window(make, true)
    else
        print("Error: Invalid option. Please use one of: RunBG, RunV, RunH, Make")
    end
end

-- invoke the dispatch function
vim.api.nvim_create_user_command('Switchboard', function(args)
    M.dispatch(args.args)
end, {
    nargs = 1,
    complete = function()
        return { "RunBG", "RunV", "RunH", "Make" }
    end,
})

return M

