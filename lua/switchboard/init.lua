-- switchboard.nvim
-- Plugin to compile and run projects in tmux panes or windows

--# INITIALISE #----------------------------------------------------------------

local M = {}
M.config = {
    save_session = false,
    overlay_sleep = 1,
    overlay_width_percent = 80,
    overlay_height_percent = 80,
    build_run_window_title = "build",
    build_run_config = {}
}

function M.setup(config)
    M.config.save_session = config.save_session or M.config.save_session
    M.config.overlay_sleep = config.overlay_sleep or M.config.overlay_sleep
    M.config.overlay_width_percent = config.overlay_width_percent or M.config.overlay_width_percent
    M.config.overlay_height_percent = config.overlay_height_percent or M.config.overlay_height_percent
    M.config.build_run_window_title = config.build_run_window_title or M.config.build_run_window_title
    M.config.build_run_config = config.build_run_config or M.config.build_run_config
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

-- get build, run & debug commands based on file extension
local function get_commands_for_extension(extension)
    if extension then
        for _, cfg in ipairs(M.config.build_run_config) do
            if vim.tbl_contains(cfg.extension, extension) then
                return cfg.build, cfg.run, cfg.debug
            end
        end
        print("Error: No build and run commands found for this extension")
    else
        print("Error: No file extension found")
    end
    return nil, nil, nil
end

-- check if a tmux window with the given name exists
local function tmux_window_exists(window_name)
    local result = vim.fn.system("tmux list-windows | grep -w " .. window_name)
    return result ~= ""
end


--# CALL FUNCTIONS #------------------------------------------------------------

-- run command in a new or existing tmux window
local function new_window(cmd)
    local window_name = M.config.build_run_window_title

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

-- run command in an overlay pane
local function overlay(cmd, sleep_duration)
    if cmd then
        local proj_dir = vim.fn.trim(vim.fn.system("pwd"))
        local cmd_head = "silent !tmux display-popup -E -d" .. proj_dir

        local dimensions = " -w " .. M.config.overlay_width_percent .. "\\% -h " .. M.config.overlay_height_percent .. "\\% '"

        local sleep = "; sleep " .. sleep_duration .. "'"

        vim.cmd(cmd_head .. dimensions .. cmd .. sleep)
    else
        print("Error: Command not found for this extension")
    end
end

-- run command in same window on a new pane
local function split_window(cmd, side)
    if cmd then
        local cmd_head = "silent !tmux split-window " .. side
        vim.cmd(cmd_head .. " '" .. cmd .. "; exec zsh'")
    else
        print("Error: Command not found for this extension")
    end
end

-- run lazygit in an overlay pane
local function lazygit()
    if vim.fn.executable("lazygit") == 1 then
        overlay("lazygit", 0)
    else
        print("Error: lazygit not installed.")
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

    if M.config.save_session then
        vim.cmd(":wall")
    end

    local extension = get_file_extension()
    local make, run, debug = get_commands_for_extension(extension)

    if option == "lazygit" then
        lazygit()
    elseif option == "Run" then
        overlay(run, M.config.overlay_sleep, "Run")
    elseif option == "RunV" then
        split_window(run, "-v", "Run")
    elseif option == "RunH" then
        split_window(run, "-h", "Run")
    elseif option == "RunBG" then
        new_window(run, "Run")
    elseif option == "Make" then
        overlay(make, M.config.overlay_sleep, "Make")
    elseif option == "MakeV" then
        split_window(make, "-v", "Make")
    elseif option == "MakeH" then
        split_window(make, "-h", "Make")
    elseif option == "MakeBG" then
        new_window(make, "Make")
    elseif option == "Debug" then
        overlay(debug, M.config.overlay_sleep, "Debug")
    elseif option == "DebugV" then
        split_window(debug, "-v", "Debug")
    elseif option == "DebugH" then
        split_window(debug, "-h", "Debug")
    elseif option == "DebugBG" then
        new_window(debug, "Debug")
    else
        print("Error: Invalid option.")
    end
end

-- invoke the dispatch function
vim.api.nvim_create_user_command('Switchboard', function(args)
    M.dispatch(args.args)
end, {
    nargs = 1,
    complete = function()
        return { "lazygit",
                 "Run", "RunV", "RunH", "RunBG",
                 "Make", "MakeV", "MakeH", "MakeBG",
                 "Debug", "DebugV", "DebugH", "DebugBG"
               }
    end,
})

return M

