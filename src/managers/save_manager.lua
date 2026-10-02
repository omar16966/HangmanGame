-- Save manager: reads and writes the player's save file (see SAVE_FORMAT.md).
--
-- Design goals: never crash, never lose progress to a damaged file.
--   * Writing: the new file is written to save.tmp and read back and checked
--     BEFORE it replaces save.json. The previous save.json is kept as
--     save.bak, and the file as it was when the game started as save.start.bak.
--   * Loading: if save.json is damaged it is kept aside as
--     save.corrupt-<time>.json, and the newest usable backup is loaded.
--     If nothing is usable, defaults are used and the player is told.
--   * Every section is validated by its own module and falls back to
--     defaults on bad data, so one wrong value cannot break the rest.
--   * Old saves are upgraded step by step (see `migrations`).
--
-- Files live in the LÖVE save folder (never in the game folder). With a
-- profile name (development: `--profile test`) they live in profiles/<name>/.
--
-- Sections are modules with load(data), export() and reset(); they are
-- registered with SaveManager.register(name, module).

local Config = require("src.core.config")
local Logger = require("src.core.logger")
local JSON = require("src.core.json")

local SaveManager = {}

local CURRENT_VERSION = 1

-- migrations[n] upgrades a save from version n to n + 1 and returns it.
-- Example, when version 2 changes the layout of the scores:
--   migrations[1] = function(data) data.scores = convert(data.scores) return data end
local migrations = {}

local DIFFICULTIES = { easy = true, normal = true, hard = true }

local sections = {}          -- ordered list of { name, module }
local suspended = nil        -- the game in progress (for Continue), or nil
local dir = ""               -- folder prefix ("" or "profiles/<name>/")
local readOnly = false
local loaded = false
local report = { status = "new" }   -- status: new | ok | recovered | reset
local notice = nil           -- localization key of a message for the player

local clock = 0
local dirty = false
local dirtySince, lastDirty, nextAttempt = 0, 0, 0
local failureNoticed = false

local function path(name)
    return dir .. name
end

local function exists(name)
    return love.filesystem.getInfo(name) ~= nil
end

-- Setup ------------------------------------------------------------------------------------------

-- options: { profile = "name" | nil, readOnly = bool }
function SaveManager.init(options)
    options = options or {}
    readOnly = options.readOnly == true
    dir = ""
    if options.profile and options.profile ~= "" then
        local name = options.profile:gsub("[^%w_%-]", "_")
        dir = "profiles/" .. name .. "/"
        love.filesystem.createDirectory("profiles/" .. name)
    end
    loaded = false
    dirty = false
    clock, dirtySince, lastDirty, nextAttempt = 0, 0, 0, 0
    suspended = nil
    notice = nil
    failureNoticed = false
    report = { status = "new" }
end

function SaveManager.register(name, module)
    sections[#sections + 1] = { name = name, module = module }
end

function SaveManager.isReadOnly()
    return readOnly
end

-- Reading ------------------------------------------------------------------------------------------

-- Returns the decoded and upgraded save, the raw text, or nil and a reason.
local function readSaveFile(name)
    local text = love.filesystem.read(name)
    if type(text) ~= "string" or text == "" then
        return nil, "file is empty or unreadable"
    end
    local data, err = JSON.decode(text)
    if type(data) ~= "table" then
        return nil, err or "not a JSON object"
    end
    local version = data.version
    if type(version) ~= "number" or version ~= math.floor(version) or version < 1 then
        return nil, "missing or invalid version"
    end
    return data, text
end

-- Brings a save up to CURRENT_VERSION. Returns data, wasFromNewerVersion or nil, reason.
local function migrate(data)
    local version = data.version
    if version > CURRENT_VERSION then
        return data, true
    end
    while version < CURRENT_VERSION do
        local step = migrations[version]
        if not step then
            return nil, "no migration from version " .. version
        end
        local ok, result = pcall(step, data)
        if not ok or type(result) ~= "table" then
            return nil, "migration from version " .. version .. " failed: " .. tostring(result)
        end
        data = result
        version = version + 1
        data.version = version
    end
    return data, false
end

local function timestamp()
    return os.date("%Y%m%d-%H%M%S")
end

-- Keeps a damaged file for inspection (limited number of copies).
local function preserveCorrupt(name)
    local text = love.filesystem.read(name)
    if not text then
        return
    end
    local copy = path("save.corrupt-" .. timestamp() .. ".json")
    if love.filesystem.write(copy, text) then
        Logger.warning("Damaged save kept as %s", copy)
    end
    local list = {}
    for _, item in ipairs(love.filesystem.getDirectoryItems(dir ~= "" and dir:sub(1, -2) or "")) do
        if item:match("^save%.corrupt%-.*%.json$") then
            list[#list + 1] = item
        end
    end
    table.sort(list)
    while #list > Config.save.keepCorruptFiles do
        love.filesystem.remove(path(table.remove(list, 1)))
    end
end

-- Suspended game -------------------------------------------------------------------------------------

local function isList(v, maxLength, check)
    if type(v) ~= "table" or #v > maxLength then return false end
    for _, item in ipairs(v) do
        if not check(item) then return false end
    end
    return true
end

local function isCodepoint(v)
    return type(v) == "number" and v == math.floor(v) and v > 0 and v < 0x110000
end

-- Checks the data of a suspended game; returns a clean copy or nil.
local function cleanSuspended(raw)
    if type(raw) ~= "table" or type(raw.round) ~= "table" or type(raw.params) ~= "table" then
        return nil
    end
    local round, params = raw.round, raw.params
    if type(round.puzzleId) ~= "string" or round.puzzleId == "" then return nil end
    if type(round.maxWrong) ~= "number" or round.maxWrong < 1 or round.maxWrong > 30 then return nil end
    if not isList(round.guessOrder, 200, isCodepoint) then return nil end
    if not isList(round.hintKeys or {}, 200, isCodepoint) then return nil end
    if params.language ~= "ar" and params.language ~= "en" then return nil end
    if type(params.difficulty) ~= "string" or not DIFFICULTIES[params.difficulty] then return nil end
    if type(params.category) ~= "string" then return nil end
    return {
        round = {
            puzzleId = round.puzzleId,
            maxWrong = math.floor(round.maxWrong),
            guessOrder = round.guessOrder,
            hintKeys = round.hintKeys or {},
            textHintUsed = round.textHintUsed == true,
            elapsed = (type(round.elapsed) == "number" and round.elapsed >= 0 and round.elapsed < 1e7) and round.elapsed or 0,
        },
        params = { language = params.language, difficulty = params.difficulty, category = params.category },
        session = type(raw.session) == "table" and raw.session or {},
        savedAt = type(raw.savedAt) == "number" and raw.savedAt or 0,
    }
end

function SaveManager.getSuspended()
    return suspended
end

-- Stores (or with nil, clears) the game in progress. Saved with the next autosave.
function SaveManager.setSuspended(data)
    suspended = data
    SaveManager.markDirty()
end

-- Loading ------------------------------------------------------------------------------------------------

local function resetSections()
    for _, s in ipairs(sections) do
        local ok, err = pcall(s.module.reset)
        if not ok then
            Logger.error("Could not reset section '%s': %s", s.name, tostring(err))
        end
    end
    suspended = nil
end

local function applyData(data)
    for _, s in ipairs(sections) do
        local ok, err = pcall(s.module.load, data[s.name])
        if not ok then
            Logger.error("Save section '%s' could not be loaded (%s); using defaults", s.name, tostring(err))
            pcall(s.module.reset)
        end
    end
    suspended = cleanSuspended(data.suspended)
end

-- Loads the save into all registered sections. Returns the report:
-- { status = "new" | "ok" | "recovered" | "reset", source = file name }
function SaveManager.load()
    loaded = true
    if readOnly then
        resetSections()
        report = { status = "ok", readOnly = true }
        return report
    end

    local candidates = { "save.json", "save.bak", "save.start.bak" }
    local anyFile, data, source, rawText = false, nil, nil, nil
    for i, name in ipairs(candidates) do
        if exists(path(name)) then
            anyFile = true
            local d, textOrReason = readSaveFile(path(name))
            if d then
                local migrated, newerOrReason = migrate(d)
                if migrated then
                    data, source, rawText = migrated, name, textOrReason
                    if newerOrReason == true then
                        Logger.warning("Save comes from a newer game version (%s); unknown data is ignored", tostring(d.version))
                        love.filesystem.write(path("save.future.bak"), textOrReason)
                    end
                    break
                end
                textOrReason = newerOrReason
            end
            Logger.warning("Save file %s cannot be used: %s", name, tostring(textOrReason))
            if i == 1 then
                preserveCorrupt(path(name))
            end
        end
    end

    if not data then
        resetSections()
        if anyFile then
            report = { status = "reset" }
            notice = "SAVE_RESET"
            Logger.error("No usable save file found; started with defaults")
        else
            report = { status = "new" }
            Logger.info("No save file found: first launch")
        end
        return report
    end

    applyData(data)
    if source == "save.json" then
        report = { status = "ok", source = source }
        -- A copy of the file as it was when this run started.
        love.filesystem.write(path("save.start.bak"), rawText)
    else
        report = { status = "recovered", source = source }
        notice = "SAVE_RECOVERED"
        Logger.warning("Progress restored from %s", source)
        SaveManager.save("recovered")
    end
    Logger.info("Save loaded (%s)", report.status)
    return report
end

function SaveManager.getReport()
    return report
end

-- True when there was no (usable) save: the first-launch setup should run.
function SaveManager.isFirstLaunch()
    return report.status == "new" or report.status == "reset"
end

-- A localization key for a message the player should see (once), or nil.
function SaveManager.consumeNotice()
    local key = notice
    notice = nil
    return key
end

-- Writing ---------------------------------------------------------------------------------------------------

local function collect()
    local data = {
        version = CURRENT_VERSION,
        savedAt = os.time(),
        gameVersion = Config.app.version,
    }
    for _, s in ipairs(sections) do
        local ok, value = pcall(s.module.export)
        if ok then
            data[s.name] = value
        else
            Logger.error("Could not export section '%s': %s", s.name, tostring(value))
        end
    end
    data.suspended = suspended
    return data
end

local function writeFailed(message)
    Logger.error("Saving failed: %s", message)
    nextAttempt = clock + Config.save.retryDelay
    if not failureNoticed then
        failureNoticed = true
        notice = notice or "SAVE_FAILED"
    end
    return false
end

-- Writes the save now. Returns true on success.
function SaveManager.save(reason)
    if readOnly or not loaded then
        return true
    end
    local okEncode, text = pcall(JSON.encode, collect(), { indent = 2 })
    if not okEncode then
        return writeFailed("could not encode the save data: " .. tostring(text))
    end
    if not JSON.decode(text) then
        return writeFailed("the encoded save did not decode again")
    end

    -- 1. Write the new data next to the real file and check it.
    local tmp, main, backup = path("save.tmp"), path("save.json"), path("save.bak")
    local ok, err = love.filesystem.write(tmp, text)
    if not ok then
        return writeFailed("writing " .. tmp .. ": " .. tostring(err))
    end
    if love.filesystem.read(tmp) ~= text then
        return writeFailed("the temporary file did not read back correctly")
    end

    -- 2. Keep the previous save as a backup (only if it is itself valid).
    if exists(main) then
        local old = love.filesystem.read(main)
        if old and JSON.decode(old) then
            love.filesystem.write(backup, old)
        end
    end

    -- 3. Replace the real file. The verified copy stays until this succeeded.
    ok, err = love.filesystem.write(main, text)
    if not ok then
        return writeFailed("writing " .. main .. ": " .. tostring(err))
    end
    love.filesystem.remove(tmp)

    dirty = false
    failureNoticed = false
    Logger.debug("Saved (%s, %d bytes)", reason or "save", #text)
    return true
end

-- Autosave ----------------------------------------------------------------------------------------------------

-- Marks the data as changed. It is saved a moment later (so a slider being
-- dragged does not write the file on every frame).
function SaveManager.markDirty()
    if readOnly or not loaded then
        return
    end
    if not dirty then
        dirty = true
        dirtySince = clock
    end
    lastDirty = clock
end

function SaveManager.update(dt)
    clock = clock + dt
    if dirty and clock >= nextAttempt then
        if clock - lastDirty >= Config.save.autosaveDelay or clock - dirtySince >= Config.save.autosaveMaxWait then
            SaveManager.save("autosave")
        end
    end
end

function SaveManager.isDirty()
    return dirty
end

-- Writes pending changes now (called when the game quits).
function SaveManager.flush()
    if dirty then
        return SaveManager.save("flush")
    end
    return true
end

-- Test access ------------------------------------------------------------------------------------------------------

SaveManager._test = {
    migrations = migrations,
    currentVersion = function() return CURRENT_VERSION end,
    setCurrentVersion = function(v) CURRENT_VERSION = v end,
    cleanSuspended = cleanSuspended,
}

return SaveManager
