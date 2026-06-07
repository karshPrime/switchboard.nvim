-- Commands.Lua

local Actions = require("switchboard.actions")
local Binds = require("switchboard.binds")
local Helpers = require("switchboard.helpers")
local Env = require("switchboard.env")

local Commands = {}

local valid_modes = { split = true, vsplit = true, overlay = true, background = true, quickfix = true }

--
-- get all available command names for completion
function Commands.get_available_commands(aConfig)
    local names = {}
    local seen = {}

    local lExtension = Helpers.get_file_extension()
    local lExtCommands = Helpers.get_commands_for_extension(lExtension, aConfig)
    if lExtCommands then
        for name, _ in pairs(lExtCommands) do
            if not seen[name] then
                table.insert(names, name)
                seen[name] = true
            end
        end
    end

    if aConfig.commands then
        for name, _ in pairs(aConfig.commands) do
            if not seen[name] then
                table.insert(names, name)
                seen[name] = true
            end
        end
    end

    table.sort(names)
    return names
end

--
-- resolve a command name to its shell command string
function Commands.resolve_command(aCommandName, aConfig)
    -- 1. project override config
    if aConfig.override_config_from_project then
        local lOverride = aConfig.project_override_config
        if type(lOverride) == "table" then
            if lOverride.commands and lOverride.commands[aCommandName] then
                return lOverride.commands[aCommandName]
            end
            if #lOverride > 0 then
                local lMatched = Helpers.get_matched_directory_override(aConfig)
                if lMatched and lMatched.commands and lMatched.commands[aCommandName] then
                    return lMatched.commands[aCommandName]
                end
            end
        end
    end

    -- 2. extension-specific commands
    local lExtension = Helpers.get_file_extension()
    local lExtCommands = Helpers.get_commands_for_extension(lExtension, aConfig)
    if lExtCommands and lExtCommands[aCommandName] then
        return lExtCommands[aCommandName]
    end

    -- 3. global commands
    if aConfig.commands and aConfig.commands[aCommandName] then
        return aConfig.commands[aCommandName]
    end

    return nil
end

--
-- commands dispatch
function Commands.dispatch(aArgs, aConfig)
    if not Env.is_tmux_running() and not Env.is_tmux_installed() then
        -- neither tmux nor fallback issue; term backend always works
    end

    local parts = vim.split(vim.trim(aArgs), "%s+")
    if #parts < 2 then
        local msg =
        "Switchboard <mode> [command]\n\n" ..
        "Modes:\n" ..
        "  split       - open in horizontal split\n" ..
        "  vsplit      - open in vertical split\n" ..
        "  overlay     - open in overlay window\n" ..
        "  background  - run in background\n" ..
        "  quickfix    - send output to quickfix\n" ..
        "  bind        - run a named bind\n" ..
        "  version     - print plugin version\n" ..
        "\ngithub:karshPrime/switchboard.nvim"

        vim.notify(msg, vim.log.levels.WARN)
        return
    end

    local lMode = parts[1]
    local lCommandName = parts[2]

    if lMode == "bind" then
        Binds.execute(lCommandName, aConfig)
        return
    end

    if not valid_modes[lMode] then
        vim.notify("Invalid mode '" .. lMode .. "'. Use: split, vsplit, overlay, background, quickfix, bind", vim.log.levels.ERROR)
        return
    end

    if aConfig.save_session then
        vim.cmd(":wall ++p")
    end

    local lCmd = Commands.resolve_command(lCommandName, aConfig)
    if not lCmd then
        local lExtension = Helpers.get_file_extension()
        vim.notify("'" .. lCommandName .. "' not defined for " .. lExtension, vim.log.levels.ERROR)
        return
    end

    if lMode == "overlay" then
        Actions.overlay(
            lCmd,
            aConfig.overlay_sleep,
            aConfig.overlay_width_percent,
            aConfig.overlay_height_percent,
            lCommandName
        )
    elseif lMode == "split" then
        Actions.split_window(
            lCmd,
            "v",
            aConfig.side_width_percent,
            aConfig.bottom_height_percent,
            aConfig.new_pane_everytime,
            lCommandName
        )
    elseif lMode == "vsplit" then
        Actions.split_window(
            lCmd,
            "h",
            aConfig.side_width_percent,
            aConfig.bottom_height_percent,
            aConfig.new_pane_everytime,
            lCommandName
        )
    elseif lMode == "background" then
        Actions.new_window(lCmd, aConfig.build_run_window_title, lCommandName)
    elseif lMode == "quickfix" then
        vim.fn.setqflist({}, " ", { lines = vim.fn.systemlist(lCmd) })
        vim.cmd("copen")
    end
end

return Commands

