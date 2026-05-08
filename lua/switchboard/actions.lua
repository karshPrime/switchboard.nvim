-- Actions.lua (dispatcher)

local Env = require("switchboard.env")

local Actions = {}

local function get_backend()
    if Env.is_tmux_running() then
        return require("switchboard.tmux_actions")
    else
        return require("switchboard.term_actions")
    end
end

function Actions.new_window(aCmd, aWindowName, aErrorName)
    return get_backend().new_window(aCmd, aWindowName, aErrorName)
end

function Actions.overlay(aCmd, aSleepDuration, aWidth, aHeight, aErrorName)
    return get_backend().overlay(aCmd, aSleepDuration, aWidth, aHeight, aErrorName)
end

function Actions.split_window(aCmd, aSide, aWidth, aHeight, aNewPane, aErrorName)
    return get_backend().split_window(aCmd, aSide, aWidth, aHeight, aNewPane, aErrorName)
end

return Actions
