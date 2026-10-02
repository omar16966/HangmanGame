-- Lifetime statistics (kept separate from the per-session data in
-- gameplay/session.lua). Updated by GameFlow when a round ends.
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Utils = require("src.core.utils")

local Stats = {}

local DEFAULTS = {
    gamesPlayed = 0,      -- sessions with at least one finished round
    roundsPlayed = 0,
    roundsWon = 0,
    roundsLost = 0,
    correctGuesses = 0,   -- distinct correct letters guessed by the player
    wrongGuesses = 0,
    arabicGames = 0,
    englishGames = 0,
    bestScore = 0,        -- best score of a whole game (session)
    bestRoundScore = 0,
    totalScore = 0,
    bestStreak = 0,
    currentStreak = 0,    -- rounds won in a row, across games
    hintsUsed = 0,
    perfectRounds = 0,    -- won with no wrong guess and no hint
    playTime = 0,         -- seconds spent in finished rounds
}

local data = Utils.deepCopy(DEFAULTS)

function Stats.get()
    return data
end

-- sessionJustStarted: true when this is the first finished round of the game.
-- session: the current Session table (score and language of the game).
function Stats.recordRound(round, scoreResult, session, sessionJustStarted)
    data.roundsPlayed = data.roundsPlayed + 1
    data.correctGuesses = data.correctGuesses + round.correctGuesses
    data.wrongGuesses = data.wrongGuesses + round.wrong
    local hints = round.revealHints + (round.textHintUsed and 1 or 0)
    data.hintsUsed = data.hintsUsed + hints
    data.playTime = data.playTime + round.elapsed
    data.totalScore = data.totalScore + scoreResult.total
    data.bestRoundScore = math.max(data.bestRoundScore, scoreResult.total)

    if round:isWon() then
        data.roundsWon = data.roundsWon + 1
        data.currentStreak = data.currentStreak + 1
        data.bestStreak = math.max(data.bestStreak, data.currentStreak)
        if round.wrong == 0 and hints == 0 then
            data.perfectRounds = data.perfectRounds + 1
        end
    else
        data.roundsLost = data.roundsLost + 1
        data.currentStreak = 0
    end

    if sessionJustStarted then
        data.gamesPlayed = data.gamesPlayed + 1
        if round.language == "ar" then
            data.arabicGames = data.arabicGames + 1
        else
            data.englishGames = data.englishGames + 1
        end
    end
    data.bestScore = math.max(data.bestScore, session.score)
end

-- Derived values -----------------------------------------------------------------------------------

-- Fraction (0..1) of finished rounds that were won.
function Stats.getWinRate()
    if data.roundsPlayed == 0 then return 0 end
    return data.roundsWon / data.roundsPlayed
end

-- Fraction (0..1) of guesses that were correct.
function Stats.getAccuracy()
    local total = data.correctGuesses + data.wrongGuesses
    if total == 0 then return 0 end
    return data.correctGuesses / total
end

-- Save section ---------------------------------------------------------------------------------------

function Stats.reset()
    data = Utils.deepCopy(DEFAULTS)
end

function Stats.load(saved)
    Stats.reset()
    if type(saved) ~= "table" then
        return
    end
    for key, default in pairs(DEFAULTS) do
        local v = saved[key]
        if type(v) == "number" and v == v and v >= 0 and v < 1e12 then
            data[key] = (key == "playTime") and v or math.floor(v)
        else
            data[key] = default
        end
    end
    -- Consistency: the totals can never be smaller than their parts.
    data.roundsPlayed = math.max(data.roundsPlayed, data.roundsWon + data.roundsLost)
    data.bestStreak = math.max(data.bestStreak, data.currentStreak)
end

function Stats.export()
    return Utils.deepCopy(data)
end

return Stats
