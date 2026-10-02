-- Session: data for the current game (from the moment the player starts a
-- game until it ends), kept separate from lifetime statistics.
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Session = {}

local data

local function blank()
    return {
        score = 0,
        streak = 0,
        roundsPlayed = 0,
        roundsWon = 0,
        hintsUsed = 0,
        time = 0,
        -- Choices made when the game started ("" = unknown).
        language = "",
        difficulty = "",
        category = "",
        submitted = false,   -- the score was already added to the high scores
    }
end

-- Starts a new game. meta: { language, difficulty, category } (optional).
function Session.start(meta)
    data = blank()
    for _, key in ipairs({ "language", "difficulty", "category" }) do
        if meta and type(meta[key]) == "string" then
            data[key] = meta[key]
        end
    end
    return data
end

-- The current session; one is created if none exists.
function Session.get()
    return data or Session.start()
end

-- The current session, or nil when none exists (does not create one).
function Session.peek()
    return data
end

-- Forgets the current session.
function Session.clear()
    data = nil
end

function Session.update(dt)
    local s = Session.get()
    s.time = s.time + dt
end

-- Records a finished round. scoreResult comes from Scoring.calculate().
function Session.recordRound(round, scoreResult)
    local s = Session.get()
    s.roundsPlayed = s.roundsPlayed + 1
    s.score = s.score + scoreResult.total
    s.hintsUsed = s.hintsUsed + round.revealHints + (round.textHintUsed and 1 or 0)
    if round:isWon() then
        s.roundsWon = s.roundsWon + 1
        s.streak = s.streak + 1
    else
        s.streak = 0
    end
    return s
end

function Session.export()
    local s = Session.get()
    local copy = {}
    for k, v in pairs(s) do copy[k] = v end
    return copy
end

-- Restores a session from saved data; wrong or missing values stay at their defaults.
function Session.load(saved)
    Session.start()
    if type(saved) == "table" then
        for k, default in pairs(data) do
            local v = saved[k]
            if type(v) == type(default) then
                if type(v) ~= "number" or (v == v and v >= 0 and v < 1e12) then
                    data[k] = v
                end
            end
        end
    end
    return data
end

return Session
