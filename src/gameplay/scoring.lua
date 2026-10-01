-- Scoring rules. All values come from Config.score and Config.difficulty.
--
--   subtotal = completePuzzle (if solved)
--            + correctLetter * letters found by guessing
--            + remainingAttemptBonus * unused attempts (if solved)
--            + speed bonus (if solved)
--            - wrongGuessPenalty * wrong guesses
--            - hint penalties
--   total    = max(0, subtotal * difficulty multiplier)
--
-- A round score is never negative.
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Config = require("src.core.config")

local Scoring = {}

-- Speed bonus: full when solved instantly, falling linearly to 0 after
-- speedSecondsPerLetter seconds for every letter cell.
function Scoring.speedBonus(round)
    local s = Config.score
    local limit = math.max(1, round.letterCount * s.speedSecondsPerLetter)
    local factor = math.max(0, 1 - round.elapsed / limit)
    return math.floor(s.speedBonusMax * factor + 0.5)
end

-- Points shown while the round is running (no bonuses or multiplier yet).
function Scoring.running(round)
    local s = Config.score
    local points = round.lettersFound * s.correctLetter
        - round.wrong * s.wrongGuessPenalty
        - (round.textHintUsed and s.textHintPenalty or 0)
        - round.revealHints * s.revealHintPenalty
    return math.max(0, points)
end

-- Full breakdown of a finished round.
-- difficulty: "easy" | "normal" | "hard" (the difficulty the player chose)
function Scoring.calculate(round, difficulty)
    local s = Config.score
    local diff = Config.difficulty[difficulty] or Config.difficulty.normal
    local won = round:isWon()

    local result = {
        won = won,
        base = won and s.completePuzzle or 0,
        letters = round.lettersFound * s.correctLetter,
        remainingBonus = won and round:getRemainingAttempts() * s.remainingAttemptBonus or 0,
        speedBonus = won and Scoring.speedBonus(round) or 0,
        wrongPenalty = round.wrong * s.wrongGuessPenalty,
        hintPenalty = (round.textHintUsed and s.textHintPenalty or 0) + round.revealHints * s.revealHintPenalty,
        multiplier = diff.scoreMultiplier,
    }
    result.bonus = result.remainingBonus + result.speedBonus
    result.subtotal = result.base + result.letters + result.bonus - result.wrongPenalty - result.hintPenalty
    result.total = math.max(0, math.floor(result.subtotal * result.multiplier + 0.5))
    return result
end

return Scoring
