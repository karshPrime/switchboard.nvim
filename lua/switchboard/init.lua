-- init.lua

local Commands = require("switchboard.commands")
local Helpers = require("switchboard.helpers")

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
    commands = {},
    build_run_config = {},
    notify_missing_project_config = false,
    local_config = "switchboard.lua",
}

local modes = { "split", "vsplit", "overlay", "background", "quickfix", "bind" }

function M.setup(aConfig)
    for key, value in pairs(aConfig) do
        M.config[key] = value or M.config[key]
    end

    local lLocalConfig = Helpers.search_project_defined_override_config(
        M.config["notify_missing_project_config"],
        M.config["local_config"]
    )

    if lLocalConfig ~= nil then
        M.config["project_override_config"] = lLocalConfig
        M.config["override_config_from_project"] = true
    else
        M.config["override_config_from_project"] = false
    end
end

-- nvim command integration
vim.api.nvim_create_user_command("Switchboard", function(args)
    Commands.dispatch(args.args, M.config)
end, {
    nargs = "+",
    complete = function(argLead, cmdLine)
        local parts = vim.split(vim.trim(cmdLine), "%s+")
        if #parts <= 2 then
            return vim.tbl_filter(function(m)
                return m:find(argLead, 1, true) == 1
            end, modes)
        else
            local lFirstArg = parts[2]
            local command_names
            if lFirstArg == "bind" then
                local Binds = require("switchboard.binds")
                command_names = Binds.get_available_binds(M.config)
            else
                command_names = Commands.get_available_commands(M.config)
            end
            return vim.tbl_filter(function(c)
                return c:find(argLead, 1, true) == 1
            end, command_names)
        end
    end,
})

return M
