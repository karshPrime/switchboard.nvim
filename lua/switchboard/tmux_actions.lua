-- tmux_actions.lua

local Helpers = require("switchboard.helpers")

local TmuxActions = {}

local shell_commands = { "zsh", "bash", "sh", "fish", "dash", "ksh", "csh", "tcsh" }

--
-- check if a pane is idle (running a shell, not a program)
local function is_pane_idle(aPaneId)
    local lCurrentCommand =
        vim.fn.trim(vim.fn.system("tmux display -p -t " .. aPaneId .. " '#{pane_current_command}'"))
    for _, shell in ipairs(shell_commands) do
        if lCurrentCommand == shell then
            return true
        end
    end
    return false
end

--
-- run command in a new or existing tmux window
function TmuxActions.new_window(aCmd, aWindowName, aErrorName)
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        vim.notify("Error: " .. aErrorName .. " command not found for ." .. lExtension, vim.log.levels.ERROR)
        return 1
    end

    if Helpers.tmux_window_exists(aWindowName) then
        aCmd = Helpers.change_dir(aWindowName) .. aCmd
        vim.fn.system("tmux selectw -t " .. aWindowName .. " \\; send-keys '" .. aCmd .. "' C-m")
    else
        local lProjectDir = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel 2>/dev/null || pwd")) .. " -n "
        vim.fn.system("tmux neww -c " .. lProjectDir .. aWindowName .. " '" .. aCmd .. "; zsh'")
    end
end

--
-- run command in an overlay popup
function TmuxActions.overlay(aCmd, aSleepDuration, aWidth, aHeight, aErrorName)
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        vim.notify("Error: " .. aErrorName .. " command not found for ." .. lExtension, vim.log.levels.ERROR)
        return 1
    end

    local lProjectDir = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel 2>/dev/null || pwd"))

    local aCmdHead = "tmux display-popup -E -d" .. lProjectDir
    local lDimensions = " -w " .. aWidth .. "\\% -h " .. aHeight .. "\\% '"

    local lSleep
    if aSleepDuration < 0 then
        lSleep = "; read'"
    else
        lSleep = "; sleep " .. aSleepDuration .. "'"
    end

    vim.fn.system(aCmdHead .. lDimensions .. aCmd .. lSleep)
end

--
-- run command in same window on a new or existing pane
function TmuxActions.split_window(aCmd, aSide, aWidth, aHeight, aNewPane, aErrorName)
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        vim.notify("Error: " .. aErrorName .. " command not found for ." .. lExtension, vim.log.levels.ERROR)
        return 1
    end

    local lDirectionLookup = {
        v = "-D",
        h = "-R",
    }

    local lLengthPercentage = {
        v = aHeight,
        h = aWidth,
    }

    local lCurrentPane = vim.fn.trim(vim.fn.system("tmux display -p '#{pane_id}'"))
    vim.fn.system("tmux selectp " .. lDirectionLookup[aSide])
    local lMovedPane = vim.fn.trim(vim.fn.system("tmux display -p '#{pane_id}'"))

    if lCurrentPane == lMovedPane or aNewPane then
        -- no adjacent pane exists or user wants a fresh one
        local lParameters = aSide .. " -l " .. lLengthPercentage[aSide] .. "%"
        vim.fn.system("tmux splitw -" .. lParameters .. " '" .. aCmd .. "; zsh'")
    elseif is_pane_idle(lMovedPane) then
        -- adjacent pane exists and is idle at a shell prompt
        aCmd = Helpers.change_dir(lMovedPane) .. aCmd
        vim.fn.system("tmux send -t " .. lMovedPane .. " '" .. aCmd .. "' C-m")
    else
        -- adjacent pane has a program running, create a new split instead
        vim.fn.system("tmux selectp -t " .. lCurrentPane)
        local lParameters = aSide .. " -l " .. lLengthPercentage[aSide] .. "%"
        vim.fn.system("tmux splitw -" .. lParameters .. " '" .. aCmd .. "; zsh'")
    end

    -- return to nvim pane
    vim.fn.system("tmux selectp -t " .. lCurrentPane)
end

return TmuxActions
