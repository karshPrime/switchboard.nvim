
-- Commands.Lua

local Actions = require( "switchboard.actions" )
local Helpers = require( "switchboard.helpers" )
local Env = require( "switchboard.env" )

local Commands = {}

--
-- commands dispatch
function Commands.dispatch( aOption, aConfig )
    if not Env.is_tmux_installed() then
        print( "Error: install TMUX to use the plugin" )
        return 1
    end

    if not Env.is_tmux_running() then
        print( "Error: run session in TMUX" )
        return 1
    end

    if aConfig.save_session then
        vim.cmd( ":wall" )
    end

    local lMake, lRun, lDebug

    local function load_from_extension()
        local lExtension    = Helpers.get_file_extension()
        lMake, lRun, lDebug = Helpers.get_commands_for_extension( lExtension, aConfig )
    end

    local lIsDirectoryOverrideSet   = aConfig.project_override_config ~= nil
    local lIsDirectoryOverrideFound = false

    if lIsDirectoryOverrideSet then
        local lOverrideConfig = Helpers.get_matched_directory_override( aConfig )

        if lOverrideConfig ~= nil then
            lMake, lRun, lDebug = lOverrideConfig.build, lOverrideConfig.run, lOverrideConfig.debug
            lIsDirectoryOverrideFound = true
        else
            load_from_extension()
        end
    else
        load_from_extension()
    end

    local commands = {
        Run   = { command = lRun,   title = "Run"   },
        Make  = { command = lMake,  title = "Make"  },
        Debug = { command = lDebug, title = "Debug" },
    }

    local function execute_command( cmd, lOrientation, lBackground )
        local lCommandInfo = commands[cmd]

        if not lCommandInfo then
            print( "Error: Invalid aOption." )
            return
        end

        if lIsDirectoryOverrideFound and lCommandInfo.command == nil then
            print( "Error: override for directory set but no command found." )
            return
        end

        local action = lBackground and Actions.new_window or Actions.overlay
        if lOrientation then
            action = Actions.split_window
        end

        if lBackground then
            action( lCommandInfo.command, aConfig.build_run_window_title, lCommandInfo.title )
        elseif lOrientation then
            action(
                lCommandInfo.command,
                lOrientation,
                aConfig.side_width_percent,
                aConfig.bottom_height_percent,
                aConfig.new_pane_everytime,
                lCommandInfo.title
            )
        else
            action(
                lCommandInfo.command,
                aConfig.overlay_sleep,
                aConfig.overlay_width_percent,
                aConfig.overlay_height_percent,
                lCommandInfo.title
            )
        end
    end

    if aOption == "lazygit" then
        Actions.lazygit( aConfig.overlay_width_percent, aConfig.overlay_height_percent )
    else
        local lOrientation = nil
        local lBackground = false

        if aOption:sub( -1 ) == "V" then
            lOrientation = "v"
            aOption = aOption:sub( 1, -2 )
        elseif aOption:sub( -1 ) == "H" then
            lOrientation = "h"
            aOption = aOption:sub( 1, -2 )
        elseif aOption:sub( -2 ) == "BG" then
            lBackground = true
            aOption = aOption:sub( 1, -3 )
        end

        execute_command( aOption, lOrientation, lBackground )
    end
end

return Commands

