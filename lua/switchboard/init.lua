-- switchboard.nvim
-- Plugin to compile and run projects in tmux panes or windows

--# INITIALISE #----------------------------------------------------------------

local M = {}
M.config = {
    save_session = false,
    build_run_window_title = "build",
    new_pane_everytime = false,
    side_width_percent = 50,
    bottom_height_percent = 30,
    overlay_sleep = -1,
    overlay_width_percent = 80,
    overlay_height_percent = 80,
    build_run_config = {}
}

function M.setup(config)
    for key, value in pairs(config) do
        M.config[key] = value or M.config[key]
    end
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
    local ext = filename:match("^.+(%..+)$")
    if ext then
        return ext:sub(2)
    else
        return "No Extension"
    end
end

-- get build, run & debug commands based on file extension
local function get_commands_for_extension(extension)
    for _, cfg in ipairs(M.config.build_run_config) do
        if vim.tbl_contains(cfg.extension, extension) then
            return cfg.build, cfg.run, cfg.debug
        end
    end
    return nil, nil, nil
end

-- check if a tmux window with the given name exists
local function tmux_window_exists(window_name)
    local result = vim.fn.system("tmux list-windows | grep -w " .. window_name)
    return result ~= ""
end

-- change directory if not same as project
local function change_dir(pane)
    local proj_dir = vim.fn.trim(vim.fn.system("pwd"))
    local win_dir = vim.fn.trim(vim.fn.system("tmux display -p -t " .. pane .. " '#{pane_current_path}'"))

    if (win_dir == proj_dir) or (win_dir == ("/private"..proj_dir)) then
        return ""
    end

    return "cd " .. proj_dir .. "; "
end


--# CALL FUNCTIONS #------------------------------------------------------------

-- run command in a new or existing tmux window
local function new_window(cmd, error_name)
    if not cmd then
        local extension = get_file_extension()
        print("Error: " .. error_name .. " command not found for ." .. extension)
        return 1
    end

    local window_name = M.config.build_run_window_title

    if tmux_window_exists(window_name) then
        cmd = change_dir(window_name) .. cmd

        vim.fn.system("tmux selectw -t " .. window_name .. " \\; send-keys '" .. cmd .. "' C-m")
    else
        vim.fn.system("tmux neww -n " .. window_name .. " '" .. cmd .. "; zsh'")
    end
end

-- run command in an overlay pane
local function overlay(cmd, sleep_duration, error_name)
    if not cmd then
        local extension = get_file_extension()
        print("Error: " .. error_name .. " command not found for ." .. extension)
        return 1
    end

    local proj_dir = vim.fn.trim(vim.fn.system("pwd"))
    local cmd_head = "tmux display-popup -E -d" .. proj_dir

    local dimensions = " -w " .. M.config.overlay_width_percent .. "\\% -h " .. M.config.overlay_height_percent .. "\\% '"

	local sleep
	if sleep_duration < 0 then
		sleep = "; read'"
	else
		sleep = "; sleep " .. sleep_duration .. "'"
	end

    vim.fn.system(cmd_head .. dimensions .. cmd .. sleep)
end

-- run command in same window on a new pane
local function split_window(cmd, side, error_name)
    if not cmd then
        local extension = get_file_extension()
        print("Error: " .. error_name .. " command not found for ." .. extension)
        return 1
    end

    local direction_lookup = {
        v = "-D",
        h = "-R"
    }

    local length_percentage = {
        v = M.config.bottom_height_percent,
        h = M.config.side_width_percent
    }

    local current_pane = vim.fn.system("tmux display -p '#{pane_id}'")
    vim.fn.system("tmux selectp " .. direction_lookup[side])
    local moved_pane = vim.fn.system("tmux display -p '#{pane_id}'")

    if (vim.trim(current_pane) == vim.trim(moved_pane) or M.config.new_pane_everytime) then
        local parameters = side .. " -l " .. length_percentage[side] .. "%"
        vim.fn.system("tmux splitw -" .. parameters .. " '" .. cmd .. "; zsh'")
    else
        cmd = change_dir(vim.trim(moved_pane)) .. cmd
        vim.fn.system("tmux send -t " .. vim.trim(moved_pane) .. " '" .. cmd .. "' C-m")
    end

	-- return to nvim pane
	vim.fn.system("tmux select-pane -l")
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

    local commands = {
        lazygit = lazygit,
        Run = function() overlay(run, M.config.overlay_sleep, "Run") end,
        RunV = function() split_window(run, "v", "Run") end,
        RunH = function() split_window(run, "h", "Run") end,
        RunBG = function() new_window(run, "Run") end,
        Make = function() overlay(make, M.config.overlay_sleep, "Make") end,
        MakeV = function() split_window(make, "v", "Make") end,
        MakeH = function() split_window(make, "h", "Make") end,
        MakeBG = function() new_window(make, "Make") end,
        Debug = function() overlay(debug, M.config.overlay_sleep, "Debug") end,
        DebugV = function() split_window(debug, "v", "Debug") end,
        DebugH = function() split_window(debug, "h", "Debug") end,
        DebugBG = function() new_window(debug, "Debug") end
    }

    if commands[option] then
        commands[option]()
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
        return {
            "lazygit",
            "Run", "RunV", "RunH", "RunBG",
            "Make", "MakeV", "MakeH", "MakeBG",
            "Debug", "DebugV", "DebugH", "DebugBG"
        }
    end,
})

return M

