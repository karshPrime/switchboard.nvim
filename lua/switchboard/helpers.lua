-- Helpers.Lua

local Helpers = {}

--
-- search for directory override config in project directory
function Helpers.search_project_defined_override_config(notify_missing_config, config_name)
    local lCwd = vim.fn.getcwd()
    local lPathsToSearch = { "/.nvim", "/nvim", "" }

    for _, lPath in ipairs(lPathsToSearch) do
        local lFullPath = lCwd .. lPath .. "/" .. config_name

        if vim.fn.filereadable(lFullPath) == 1 then
            vim.notify("Found TmuxCompile config file at " .. lFullPath, vim.log.levels.INFO)
            local lSuccess, lResult = pcall(dofile, lFullPath)

            if lSuccess then
                return lResult
            else
                vim.notify("Error loading TmuxCompile config file: " .. lResult, vim.log.levels.ERROR)
            end
        end
    end

    local lPathsSearched = vim.tbl_map(function(aPath)
        return lCwd .. aPath .. "/" .. config_name
    end, lPathsToSearch)

    if notify_missing_config then
        vim.notify(
            "Did not find TMUXCompile config file or it is not readable. Paths searched:  "
                .. table.concat(lPathsSearched, "\n"),
            vim.log.levels.INFO
        )
    end
    return nil
end

--
-- get matched directory override config if it exists
function Helpers.get_matched_directory_override(aConfig)
    local lFilename = vim.api.nvim_buf_get_name(0)
    local lHomeDir = os.getenv("HOME")

    for _, lConfig in ipairs(aConfig.project_override_config) do
        local lConfigDir = lConfig.project_base_dir

        if lConfigDir:sub(1, 1) == "~" then
            lConfigDir = lHomeDir .. lConfigDir:sub(2)
        end

        vim.notify("Checking if " .. lFilename .. " matches " .. vim.pesc(lConfigDir), vim.log.levels.INFO)

        if string.match(lFilename, "^" .. vim.pesc(lConfigDir)) then
            return lConfig
        end
    end

    return nil
end

--
-- get the file extension
function Helpers.get_file_extension()
    local lFilename = vim.api.nvim_buf_get_name(0)
    local lExtension = lFilename:match("^.+(%..+)$")

    return lExtension and lExtension:sub(2) or "No Extension"
end

--
-- get commands table for a file extension
function Helpers.get_commands_for_extension(aExtension, aConfig)
    for _, lConfig in ipairs(aConfig.build_run_config) do
        if vim.tbl_contains(lConfig.extension, aExtension) then
            return lConfig.commands
        end
    end

    return nil
end

--
-- check if a tmux window with the given name exists
function Helpers.tmux_window_exists(aWindowName)
    local Result = vim.fn.system("tmux list-windows | grep -w " .. aWindowName)

    return Result ~= ""
end

--
-- change directory if not same as project
function Helpers.change_dir(aPane)
    local lProjectDir = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel 2>/dev/null || pwd"))
    print(lProjectDir)

    local lWindowDir = vim.fn.trim(vim.fn.system("tmux display -p -t " .. aPane .. " '#{pane_current_path}'"))

    if lWindowDir == lProjectDir or lWindowDir == ("/private" .. lProjectDir) then
        return ""
    end

    return "cd " .. lProjectDir .. "; "
end

return Helpers
