-- High scores: the best finished games (sessions), stored locally.
-- An entry is created when a game ends (see GameFlow.endSession).
--
--   entry = { name, score, language, difficulty, time, rounds, correct }
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Config = require("src.core.config")
local Logger = require("src.core.logger")
local Profile = require("src.managers.profile_manager")

local Scores = {}

local entries = {}
Scores.lastEntry = nil   -- the entry created most recently (highlighted on screen)

local function isDifficulty(v)
    return type(v) == "string" and v ~= "order" and Config.difficulty[v] ~= nil
end

-- Returns a clean copy of a raw entry, or nil and a reason.
local function cleanEntry(raw)
    if type(raw) ~= "table" then return nil, "not a table" end
    local score, rounds, correct = raw.score, raw.rounds, raw.correct
    if type(score) ~= "number" or score ~= score or score < 0 or score > 1e12 then return nil, "bad score" end
    if type(rounds) ~= "number" or rounds < 1 or rounds > 1e6 then return nil, "bad rounds" end
    if type(correct) ~= "number" or correct < 0 or correct > rounds then return nil, "bad correct count" end
    if raw.language ~= "ar" and raw.language ~= "en" then return nil, "bad language" end
    if not isDifficulty(raw.difficulty) then return nil, "bad difficulty" end
    local time = type(raw.time) == "number" and raw.time or 0
    return {
        name = Profile.sanitizeName(raw.name),
        score = math.floor(score),
        language = raw.language,
        difficulty = raw.difficulty,
        time = time,
        rounds = math.floor(rounds),
        correct = math.floor(correct),
    }
end

local function sortEntries()
    table.sort(entries, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.time < b.time -- the earlier one ranks higher on a tie
    end)
    while #entries > Config.save.maxScores do
        entries[#entries] = nil
    end
end

-- Adds the result of a finished game. Games without points are not recorded.
-- session: { score, roundsPlayed, roundsWon, language, difficulty }
-- Returns the new entry, or nil if the game does not qualify.
function Scores.submit(session, name, now)
    if session.roundsPlayed < 1 or session.score <= 0 then
        return nil
    end
    local entry = cleanEntry({
        name = name,
        score = session.score,
        language = session.language,
        difficulty = session.difficulty,
        time = now or os.time(),
        rounds = session.roundsPlayed,
        correct = session.roundsWon,
    })
    if not entry then
        Logger.warning("Could not record the game score (invalid session data)")
        return nil
    end
    entries[#entries + 1] = entry
    sortEntries()
    Scores.lastEntry = entry
    return entry
end

-- filter: { language = "ar" | "en" | nil, difficulty = "easy" | ... | nil }
-- Returns up to `limit` entries, best first.
function Scores.getTop(filter, limit)
    filter = filter or {}
    local out = {}
    for _, e in ipairs(entries) do
        if (not filter.language or e.language == filter.language)
            and (not filter.difficulty or e.difficulty == filter.difficulty) then
            out[#out + 1] = e
            if limit and #out >= limit then
                break
            end
        end
    end
    return out
end

function Scores.count()
    return #entries
end

-- Save section -------------------------------------------------------------------------------------

function Scores.reset()
    entries = {}
    Scores.lastEntry = nil
end

function Scores.load(saved)
    Scores.reset()
    if type(saved) ~= "table" then
        return
    end
    local dropped = 0
    for _, raw in ipairs(saved) do
        local entry = cleanEntry(raw)
        if entry then
            entries[#entries + 1] = entry
        else
            dropped = dropped + 1
        end
    end
    if dropped > 0 then
        Logger.warning("Skipped %d invalid high-score entries", dropped)
    end
    sortEntries()
end

function Scores.export()
    local out = {}
    for i, e in ipairs(entries) do
        out[i] = { name = e.name, score = e.score, language = e.language, difficulty = e.difficulty,
            time = e.time, rounds = e.rounds, correct = e.correct }
    end
    return out
end

return Scores
