-- Puzzle manager: loads, validates and selects puzzles.
--
-- Puzzle packs are Lua data files in the folders listed in Config.puzzles
-- (trusted content shipped with the game, see PUZZLES.md). Other sources,
-- such as the player's own words, are added with PuzzleManager.addPuzzles().
--
--   local puzzle = PuzzleManager.pick({ language = "ar", category = "animals", difficulty = "easy" })
--   PuzzleManager.markPlayed(puzzle.id)
--
-- Every record is validated; invalid ones are skipped with a warning and
-- never crash the game.

local Config = require("src.core.config")
local Logger = require("src.core.logger")
local Utf8 = require("src.localization.utf8_util")
local Normalizer = require("src.gameplay.normalizer")
local categoryList = require("data.categories")

local unpack = unpack or table.unpack

local PuzzleManager = {}

local LANGUAGES = { ar = true, en = true }
local DIFFICULTIES = { easy = true, normal = true, hard = true }
local FOLDER_LANGUAGE = { arabic = "ar", english = "en" }

local puzzles = {}       -- valid records
local byId = {}
local recent = {}        -- recently played ids, oldest first
local categoryById = {}
for _, category in ipairs(categoryList) do
    categoryById[category.id] = category
end

-- Validation -------------------------------------------------------------------------------

-- Letters from any script that the puzzle's keyboard cannot type.
local function isForeignLetter(cp)
    return (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x61 and cp <= 0x7A)
        or (cp >= 0xC0 and cp <= 0x24F)
        or (cp >= 0x0620 and cp <= 0x06FF)
end

local function cleanAnswer(answer)
    answer = answer:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    return answer
end

-- Returns a clean copy of the record, or nil and a reason.
function PuzzleManager.validate(record, defaults)
    defaults = defaults or {}
    if type(record) ~= "table" then
        return nil, "record is not a table"
    end
    local id = record.id
    if type(id) ~= "string" or id == "" then
        return nil, "missing id"
    end
    if type(record.answer) ~= "string" or cleanAnswer(record.answer) == "" then
        return nil, "missing answer"
    end

    local language = record.language or defaults.language
    if not LANGUAGES[language] then
        return nil, "invalid language '" .. tostring(language) .. "'"
    end
    local category = record.category or defaults.category
    if not categoryById[category] then
        return nil, "unknown category '" .. tostring(category) .. "'"
    end
    local difficulty = record.difficulty or defaults.difficulty or "normal"
    if not DIFFICULTIES[difficulty] then
        return nil, "invalid difficulty '" .. tostring(difficulty) .. "'"
    end
    local hint = record.hint
    if hint ~= nil and type(hint) ~= "string" and type(hint) ~= "table" then
        return nil, "hint must be a string or a table"
    end

    local answer = cleanAnswer(record.answer)
    local letters = 0
    for _, cp in ipairs(Utf8.decode(answer)) do
        if Normalizer.isGuessable(cp, language) then
            letters = letters + 1
        elseif not Normalizer.isIgnored(cp, language) and isForeignLetter(cp) then
            return nil, string.format("answer contains '%s', which the %s keyboard cannot type",
                Utf8.char(cp), language)
        end
    end
    if letters == 0 then
        return nil, "answer has no letters to guess"
    end

    return {
        id = id,
        answer = answer,
        language = language,
        category = category,
        difficulty = difficulty,
        hint = hint,
        source = defaults.source or "pack",
    }
end

-- Adds records (validated). Returns the number added.
-- defaults: { language, category, difficulty, source } applied to records
-- that do not set them.
function PuzzleManager.addPuzzles(records, sourceName, defaults)
    local added, rejected = 0, 0
    for index, record in ipairs(records or {}) do
        local clean, reason = PuzzleManager.validate(record, defaults)
        if clean and byId[clean.id] then
            clean, reason = nil, "duplicate id"
        end
        if clean then
            puzzles[#puzzles + 1] = clean
            byId[clean.id] = clean
            added = added + 1
        else
            rejected = rejected + 1
            Logger.warning("Puzzle %s #%d (%s) skipped: %s", sourceName, index,
                type(record) == "table" and tostring(record.id) or "?", reason)
        end
    end
    return added, rejected
end

-- Removes every puzzle coming from a source (e.g. before reloading the
-- player's own words).
function PuzzleManager.removeSource(source)
    local kept = {}
    for _, p in ipairs(puzzles) do
        if p.source == source then
            byId[p.id] = nil
        else
            kept[#kept + 1] = p
        end
    end
    puzzles = kept
end

-- Loading packs -------------------------------------------------------------------------------

local function loadPackFile(path, folderLanguage)
    local okLoad, chunk = pcall(love.filesystem.load, path)
    if not okLoad or not chunk then
        Logger.error("Could not read puzzle pack %s: %s", path, tostring(chunk))
        return 0
    end
    local okRun, pack = pcall(chunk)
    if not okRun or type(pack) ~= "table" then
        Logger.error("Puzzle pack %s is invalid: %s", path, tostring(pack))
        return 0
    end
    local records = pack.puzzles or pack
    local defaults = {
        language = pack.language or folderLanguage,
        category = pack.category,
        difficulty = pack.difficulty,
        source = "pack",
    }
    return (PuzzleManager.addPuzzles(records, path, defaults))
end

function PuzzleManager.init()
    puzzles, byId = {}, {}
    local total = 0
    for _, folder in ipairs(Config.puzzles.folders) do
        local folderLanguage = FOLDER_LANGUAGE[folder:match("([^/]+)$")]
        local items = love.filesystem.getDirectoryItems(folder)
        table.sort(items)
        for _, name in ipairs(items) do
            if name:match("%.lua$") then
                total = total + loadPackFile(folder .. "/" .. name, folderLanguage)
            end
        end
    end
    Logger.info("Loaded %d puzzles (Arabic %d, English %d)", total,
        PuzzleManager.count({ language = "ar" }), PuzzleManager.count({ language = "en" }))
end

-- Selection --------------------------------------------------------------------------------------

local function matches(p, filter)
    if filter.language and p.language ~= filter.language then
        return false
    end
    if filter.category and filter.category ~= "all" and p.category ~= filter.category then
        return false
    end
    if filter.isUnlocked and not filter.isUnlocked(p.category) then
        return false
    end
    return true
end

function PuzzleManager.count(filter)
    local n = 0
    for _, p in ipairs(puzzles) do
        if matches(p, filter or {}) then n = n + 1 end
    end
    return n
end

-- Picks a puzzle for the filter { language, category, difficulty, isUnlocked }.
-- Prefers the requested difficulty (falls back to any) and avoids recently
-- played puzzles while enough others exist. Returns nil if nothing matches.
function PuzzleManager.pick(filter, random)
    random = random or love.math.random
    local pool = {}
    for _, p in ipairs(puzzles) do
        if matches(p, filter) then pool[#pool + 1] = p end
    end
    if #pool == 0 then
        Logger.warning("No puzzles for language=%s category=%s", tostring(filter.language), tostring(filter.category))
        return nil
    end

    if filter.difficulty then
        local preferred = {}
        for _, p in ipairs(pool) do
            if p.difficulty == filter.difficulty then preferred[#preferred + 1] = p end
        end
        if #preferred > 0 then pool = preferred end
    end

    -- Avoid the most recent puzzles, but always leave at least one choice.
    local avoidCount = math.min(Config.puzzles.recentHistorySize, #pool - 1)
    local avoid = {}
    for i = #recent, math.max(1, #recent - avoidCount + 1), -1 do
        avoid[recent[i]] = true
    end
    local fresh = {}
    for _, p in ipairs(pool) do
        if not avoid[p.id] then fresh[#fresh + 1] = p end
    end
    if #fresh == 0 then fresh = pool end

    return fresh[random(#fresh)]
end

function PuzzleManager.markPlayed(id)
    for i = #recent, 1, -1 do
        if recent[i] == id then table.remove(recent, i) end
    end
    recent[#recent + 1] = id
    local limit = Config.puzzles.recentHistorySize
    while #recent > limit do
        table.remove(recent, 1)
    end
end

function PuzzleManager.getRecentHistory()
    return { unpack(recent) }
end

function PuzzleManager.setRecentHistory(list)
    recent = {}
    for _, id in ipairs(type(list) == "table" and list or {}) do
        if type(id) == "string" then recent[#recent + 1] = id end
    end
end

function PuzzleManager.get(id)
    return byId[id]
end

-- Categories ---------------------------------------------------------------------------------------

function PuzzleManager.getCategories()
    return categoryList
end

function PuzzleManager.getCategory(id)
    return categoryById[id]
end

function PuzzleManager.getCategoryName(id, uiLanguage)
    local category = categoryById[id]
    if not category then
        return tostring(id)
    end
    return category.name[uiLanguage] or category.name.en or id
end

-- Returns the hint text for the interface language (hints may be a plain
-- string in the puzzle's language or a table { ar = ..., en = ... }).
function PuzzleManager.getHint(puzzle, uiLanguage)
    local hint = puzzle.hint
    if type(hint) == "table" then
        return hint[uiLanguage] or hint[puzzle.language] or hint.en or hint.ar
    end
    return hint
end

return PuzzleManager
