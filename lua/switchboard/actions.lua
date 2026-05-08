
-- Actions.Lua

local Helpers = require( "switchboard.helpers" )

local Actions = {}

--
-- run command in a new or existing tmux window
function Actions.new_window( aCmd, aWindowName, aErrorName )
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        print( "Error: " .. aErrorName .. " command not found for ." .. lExtension )

        return 1
    end

    if Helpers.tmux_window_exists( aWindowName ) then
        aCmd = Helpers.change_dir( aWindowName ) .. aCmd

        vim.fn.system( "tmux selectw -t " .. aWindowName .. " \\; send-keys '" .. aCmd .. "' C-m" )
    else
        local lProjectDir = vim.fn.trim(
            vim.fn.system( "git rev-parse --show-toplevel 2>/dev/null || pwd" )
        ) .. " -n "

        vim.fn.system( "tmux neww -c " .. lProjectDir .. aWindowName .. " '" .. aCmd .. "; zsh'" )
    end
end

--
-- run command in an overlay pane
function Actions.overlay( aCmd, aSleepDuration, aWidth, aHeight, aErrorName )
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        print( "Error: " .. aErrorName .. " command not found for ." .. lExtension )

        return 1
    end

    local lProjectDir = vim.fn.trim(
        vim.fn.system( "git rev-parse --show-toplevel 2>/dev/null || pwd" )
    )

    local aCmdHead = "tmux display-popup -E -d" .. lProjectDir
    local lDimensions = " -w " .. aWidth .. "\\% -h " .. aHeight .. "\\% '"

    local lSleep
    if aSleepDuration < 0 then
        lSleep = "; read'"
    else
        lSleep = "; sleep " .. aSleepDuration .. "'"
    end

    vim.fn.system( aCmdHead .. lDimensions .. aCmd .. lSleep )
end

--
-- run command in same window on a new pane
function Actions.split_window( aCmd, aSide, aWidth, aHeight, aNewPane, aErrorName )
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        print( "Error: " .. aErrorName .. " command not found for ." .. lExtension )

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

    local lCurrentPane = vim.fn.system( "tmux display -p '#{pane_id}'" )
    vim.fn.system( "tmux selectp " .. lDirectionLookup[aSide] )
    local lMovedPane = vim.fn.system( "tmux display -p '#{pane_id}'" )

    aCmd = Helpers.change_dir( vim.trim(lMovedPane) ) .. aCmd

    if vim.trim( lCurrentPane ) == vim.trim( lMovedPane ) or aNewPane then
        local lParameters = aSide .. " -l " .. lLengthPercentage[aSide] .. "%"
        vim.fn.system( "tmux splitw -" .. lParameters .. " '" .. aCmd .. "; zsh'" )
    else
        vim.fn.system( "tmux send -t " .. vim.trim( lMovedPane ) .. " '" .. aCmd .. "' C-m" )
    end

    -- return to nvim pane
    vim.fn.system( "tmux select-pane -l" )
end

--
-- run lazygit in an overlay pane
function Actions.lazygit( aWidth, aHeight, aErrorName )
    if vim.fn.executable( "lazygit" ) == 1 then
        Actions.overlay( "lazygit", 0, aWidth, aHeight, aErrorName )
    else
        print( "Error: lazygit not installed." )
    end
end

return Actions

