-- Progress that is not statistics: level and XP (Phase 6), unlocked
-- categories, achievements, and the recently played puzzle ids (so the same
-- puzzle does not come back right after restarting the game).
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Utils = require("src.core.utils")
local PuzzleManager = require("src.managers.puzzle_manager")

local Progress = {}

local DEFAULTS = {
    xp = 0,
    level = 1,
    unlockedCategories = {},   -- list of category ids unlocked by leveling up
    achievements = {},         -- id -> unlock time (Phase 6)
}

local data = Utils.deepCopy(DEFAULTS)

function Progress.get()
    return data
end

function Progress.reset()
    data = Utils.deepCopy(DEFAULTS)
    PuzzleManager.setRecentHistory({})
end

local function isNonNegativeInt(v)
    return type(v) == "number" and v == math.floor(v) and v >= 0 and v < 1e12
end

function Progress.load(saved)
    Progress.reset()
    if type(saved) ~= "table" then
        return
    end
    if isNonNegativeInt(saved.xp) then data.xp = saved.xp end
    if isNonNegativeInt(saved.level) and saved.level >= 1 then data.level = saved.level end
    if type(saved.unlockedCategories) == "table" then
        for _, id in ipairs(saved.unlockedCategories) do
            if type(id) == "string" then
                data.unlockedCategories[#data.unlockedCategories + 1] = id
            end
        end
    end
    if type(saved.achievements) == "table" then
        for id, time in pairs(saved.achievements) do
            if type(id) == "string" and type(time) == "number" then
                data.achievements[id] = time
            end
        end
    end
    PuzzleManager.setRecentHistory(saved.recentPuzzles)
end

function Progress.export()
    local out = Utils.deepCopy(data)
    out.recentPuzzles = PuzzleManager.getRecentHistory()
    return out
end

return Progress
