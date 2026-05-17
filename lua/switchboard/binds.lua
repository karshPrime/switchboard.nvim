-- Binds.lua

local Helpers = require("switchboard.helpers")

local Binds = {}

--
-- get binds table for a file extension
local function get_binds_for_extension(aExtension, aConfig)
    for _, lConfig in ipairs(aConfig.build_run_config) do
        if vim.tbl_contains(lConfig.extension, aExtension) then
            return lConfig.binds
        end
    end
    return nil
end

--
-- resolve a bind name to its keys string
local function resolve_bind(aBindName, aConfig)
    -- 1. project override config
    if aConfig.override_config_from_project then
        local lOverride = aConfig.project_override_config
        if type(lOverride) == "table" then
            if lOverride.binds and lOverride.binds[aBindName] then
                return lOverride.binds[aBindName]
            end
            if #lOverride > 0 then
                local lMatched = Helpers.get_matched_directory_override(aConfig)
                if lMatched and lMatched.binds and lMatched.binds[aBindName] then
                    return lMatched.binds[aBindName]
                end
            end
        end
    end

    -- 2. extension-specific binds
    local lExtension = Helpers.get_file_extension()
    local lExtBinds = get_binds_for_extension(lExtension, aConfig)
    if lExtBinds and lExtBinds[aBindName] then
        return lExtBinds[aBindName]
    end

    return nil
end

--
-- execute a bind
function Binds.execute(aBindName, aConfig)
    local lKeys = resolve_bind(aBindName, aConfig)
    if not lKeys then
        local lExtension = Helpers.get_file_extension()
        vim.notify("Error: bind '" .. aBindName .. "' not found for " .. lExtension, vim.log.levels.ERROR)
        return
    end

    local lParsedKeys = vim.api.nvim_replace_termcodes(lKeys, true, false, true)
    vim.api.nvim_feedkeys(lParsedKeys, "n", false)
end

--
-- get all available bind names for completion
function Binds.get_available_binds(aConfig)
    local names = {}
    local seen = {}

    -- project override binds
    if aConfig.override_config_from_project then
        local lOverride = aConfig.project_override_config
        if type(lOverride) == "table" and lOverride.binds then
            for name, _ in pairs(lOverride.binds) do
                if not seen[name] then
                    table.insert(names, name)
                    seen[name] = true
                end
            end
        end
    end

    -- extension-specific binds
    local lExtension = Helpers.get_file_extension()
    local lExtBinds = get_binds_for_extension(lExtension, aConfig)
    if lExtBinds then
        for name, _ in pairs(lExtBinds) do
            if not seen[name] then
                table.insert(names, name)
                seen[name] = true
            end
        end
    end

    table.sort(names)
    return names
end

return Binds
