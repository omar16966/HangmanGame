-- Session: data for the current play session (since the game was started
-- or the player pressed Play), kept separate from lifetime statistics.
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Session = {}

local data

function Session.start()
    data = {
        score = 0,
        streak = 0,
        roundsPlayed = 0,
        roundsWon = 0,
        hintsUsed = 0,
        time = 0,
    }
    return data
end

function Session.get()
    return data or Session.start()
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

function Session.load(saved)
    Session.start()
    if type(saved) == "table" then
        for k in pairs(data) do
            if type(saved[k]) == type(data[k]) then
                data[k] = saved[k]
            end
        end
    end
    return data
end

return Session
