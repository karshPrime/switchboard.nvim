
-- Helpers.Lua

local Helpers = {}

--
-- get matched directory override config if it exists
function Helpers.get_matched_directory_override( aConfig )
    local lFilename = vim.api.nvim_buf_get_name( 0 )
    local lHomeDir  = os.getenv("HOME")

    for _, lConfig in ipairs( aConfig.project_override_config ) do
        local lConfigDir = lConfig.project_base_dir

        if lConfigDir:sub(1, 1) == "~" then
            lConfigDir = lHomeDir .. lConfigDir:sub(2)
        end

        if string.match( lFilename, "^" .. vim.pesc(lConfigDir) ) then
            return lConfig
        end
    end

    return nil
end

--
-- get directory override config values
function Helpers.get_directory_override_commands( aOverrideConfig )
    local lProjectDir = aOverrideConfig.project_base_dir
    local lFilename   = vim.api.nvim_buf_get_name( 0 )

    if string.find( lFilename, lProjectDir ) then
        return aOverrideConfig.build, aOverrideConfig.run, aOverrideConfig.debug
    els e
        return nil, nil, nil
    end
end

--
-- get the file extension
function Helpers.get_file_extension()
    local lFilename  = vim.api.nvim_buf_get_name( 0 )
    local lExtension = lFilename:match( "^.+( %..+ )$" )

    return lExtension and lExtension:sub( 2 ) or "No Extension"
end

--
-- get build, run & debug commands based on file extension
function Helpers.get_commands_for_extension( aExtension, aConfig )
    for _, lConfig in ipairs( aConfig.build_run_config ) do
        if vim.tbl_contains( lConfig.extension, aExtension ) then
            return lConfig.build, lConfig.run, lConfig.debug
        end
    end

    return nil, nil, nil
end

--
-- check if a tmux window with the given name exists
function Helpers.tmux_window_exists( aWindowName )
    local Result = vim.fn.system( "tmux list-windows | grep -w " .. aWindowName )

    return Result ~= ""
end

--
-- change directory if not same as project
function Helpers.change_dir( aPane )
    local lProjectDir = vim.fn.trim(
        vim.fn.system( "git rev-parse --show-toplevel 2>/dev/null || pwd" )
    )
    print( lProjectDir )

    local lWindowDir = vim.fn.trim(
        vim.fn.system( "tmux display -p -t " .. aPane .. " '#{pane_current_path}'" )
    )

    if lWindowDir == lProjectDir or lWindowDir == ( "/private" .. lProjectDir ) then
        return ""
    end

    return "cd " .. lProjectDir .. "; "
end

return Helpers

