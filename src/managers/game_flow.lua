-- GameFlow: what happens to the player's data around a game.
--
--   startNewGame(params)   begin a game (ends the previous one)
--   recordRound(...)       a round finished: session, statistics, save
--   snapshot(...)          remember the round in progress (for Continue)
--   getResume()            parameters to continue the saved round
--   endSession()           the game is over: add its score to the high scores
--   finalizeOnQuit()       called when the application closes
--
-- A "game" (session) is a series of rounds. The high-score entry is created
-- when the game ends. A game that is paused and left through the menu is
-- NOT ended: it is stored as a suspended game and continued later.

local Logger = require("src.core.logger")
local Session = require("src.gameplay.session")
local Stats = require("src.managers.stats_manager")
local Scores = require("src.managers.score_manager")
local Profile = require("src.managers.profile_manager")
local SaveManager = require("src.managers.save_manager")
local PuzzleManager = require("src.managers.puzzle_manager")

local GameFlow = {}

-- Starts a game with params { language, difficulty, category }.
function GameFlow.startNewGame(params)
    GameFlow.endSession()
    Session.start(params)
end

-- Records a finished round everywhere and saves immediately.
function GameFlow.recordRound(round, scoreResult)
    local session = Session.recordRound(round, scoreResult)
    Stats.recordRound(round, scoreResult, session, session.roundsPlayed == 1)
    SaveManager.setSuspended(nil) -- the round is over: nothing to continue
    SaveManager.save("round finished")
end

-- Remembers the round in progress. Written with the next autosave.
function GameFlow.snapshot(params, round)
    if not round or round:isFinished() then
        return
    end
    SaveManager.setSuspended({
        round = round:serialize(),
        params = { language = params.language, difficulty = params.difficulty, category = params.category },
        session = Session.export(),
        savedAt = os.time(),
    })
end

-- True when a saved round exists and its puzzle can still be found.
function GameFlow.hasResume()
    local saved = SaveManager.getSuspended()
    return saved ~= nil and PuzzleManager.get(saved.round.puzzleId) ~= nil
end

-- Restores the session and returns the parameters for the gameplay state,
-- or nil if there is nothing valid to continue.
function GameFlow.getResume()
    local saved = SaveManager.getSuspended()
    if not saved then
        return nil
    end
    if not PuzzleManager.get(saved.round.puzzleId) then
        Logger.warning("Saved round uses an unknown puzzle (%s); discarded", saved.round.puzzleId)
        SaveManager.setSuspended(nil)
        return nil
    end
    Session.load(saved.session)
    local params = saved.params
    return {
        language = params.language,
        category = params.category,
        difficulty = params.difficulty,
        restore = saved.round,
    }
end

-- Ends the current game: its score goes to the high scores (if it earned
-- points), and any saved round is discarded.
function GameFlow.endSession(defaults)
    local session = Session.peek()
    if session and session.roundsPlayed > 0 and not session.submitted then
        session.submitted = true
        local meta = defaults or {}
        local entry = Scores.submit({
            score = session.score,
            roundsPlayed = session.roundsPlayed,
            roundsWon = session.roundsWon,
            language = session.language ~= "" and session.language or meta.language or "ar",
            difficulty = session.difficulty ~= "" and session.difficulty or meta.difficulty or "normal",
        }, Profile.getDisplayName())
        if entry then
            Logger.info("High score recorded: %d points", entry.score)
        end
    end
    Session.clear()
    SaveManager.setSuspended(nil)
    SaveManager.save("game ended")
end

-- Called when the application closes. A game with a saved round stays open
-- (Continue); any other game that scored is ended so its score is kept.
function GameFlow.finalizeOnQuit(defaults)
    if not SaveManager.getSuspended() then
        local session = Session.peek()
        if session and session.roundsPlayed > 0 and not session.submitted then
            GameFlow.endSession(defaults)
        end
    end
    SaveManager.save("quit")
end

return GameFlow
