
-- init.lua

local Commands = require( "switchboard.commands" )

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
    build_run_config = {},
}

function M.setup( aConfig )
    for key, value in pairs( aConfig ) do
        M.config[key] = value or M.config[key]
    end
end

-- nvim command integration
vim.api.nvim_create_user_command(
    "Switchboard",
    function( args )
    Commands.dispatch( args.args, M.config )
    end,
    {
        nargs = 1,
        complete = function()
        return {
            "lazygit",
            "yazi",
            "Run",
            "RunV",
            "RunH",
            "RunBG",
            "Make",
            "MakeV",
            "MakeH",
            "MakeBG",
            "Debug",
            "DebugV",
            "DebugH",
            "DebugBG",
        }
    end,
    }
)

return M

