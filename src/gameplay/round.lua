-- Round: the rules of one puzzle (no drawing, no input devices).
--
--   local round = Round.new(puzzle, { maxWrongAttempts = 6 })
--   local result = round:guess("ب")   -- result.status: correct | wrong | repeat | invalid | finished
--   round:isWon(), round:isLost()
--
-- The answer is split into cells (one per character). Letter cells start
-- hidden; spaces separate words; digits, punctuation and hyphens are
-- revealed from the start. Guesses are compared through the Normalizer, so
-- "a" matches "A" and "ا" matches "أ" (with the default Arabic rules).
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Utf8 = require("src.localization.utf8_util")
local Normalizer = require("src.gameplay.normalizer")

local unpack = unpack or table.unpack

local Round = {}
Round.__index = Round

local SPACE = 0x20

-- Builds the cells and word ranges of an answer.
local function buildCells(answer, language)
    local cells, words = {}, {}
    local wordStart = nil
    for _, cp in ipairs(Utf8.decode(answer)) do
        if cp == SPACE then
            if wordStart then
                words[#words + 1] = { wordStart, #cells }
                wordStart = nil
            end
        elseif not Normalizer.isIgnored(cp, language) then
            local key = Normalizer.key(cp, language)
            cells[#cells + 1] = {
                cp = cp,
                key = key,
                isLetter = key ~= nil,
                revealed = key == nil,
                revealedBy = key == nil and "auto" or nil,
            }
            wordStart = wordStart or #cells
        end
    end
    if wordStart then
        words[#words + 1] = { wordStart, #cells }
    end
    return cells, words
end

-- puzzle:  { id, answer, language, category, difficulty, hint }
-- options: { maxWrongAttempts = n, random = function(n) -> 1..n }
function Round.new(puzzle, options)
    options = options or {}
    local self = setmetatable({}, Round)
    self.puzzle = puzzle
    self.language = puzzle.language
    self.maxWrong = options.maxWrongAttempts or 6
    self.random = options.random or math.random
    self.cells, self.words = buildCells(puzzle.answer, puzzle.language)

    self.guessed = {}          -- key -> "correct" | "wrong" | "hint"
    self.guessOrder = {}       -- keys in the order they were guessed (for saving)
    self.wrong = 0
    self.correctGuesses = 0    -- distinct correct letters guessed by the player
    self.lettersFound = 0      -- letter cells revealed by the player's guesses
    self.textHintUsed = false
    self.revealHints = 0
    self.elapsed = 0
    self.status = "playing"

    self.letterCount = 0
    local distinct = {}
    self.distinctKeys = 0
    for _, cell in ipairs(self.cells) do
        if cell.isLetter then
            self.letterCount = self.letterCount + 1
            if not distinct[cell.key] then
                distinct[cell.key] = true
                self.distinctKeys = self.distinctKeys + 1
            end
        end
    end
    return self
end

-- Converts a guess (codepoint or string) to its comparison key.
function Round:keyFor(input)
    local cp = input
    if type(input) == "string" then
        cp = Utf8.decode(input)[1]
    end
    if not cp then
        return nil
    end
    return Normalizer.key(cp, self.language)
end

local function revealKey(self, key, by)
    local positions = {}
    for i, cell in ipairs(self.cells) do
        if cell.key == key and not cell.revealed then
            cell.revealed = true
            cell.revealedBy = by
            positions[#positions + 1] = i
        end
    end
    return positions
end

local function updateStatus(self)
    if self.wrong >= self.maxWrong then
        self.status = "lost"
        return
    end
    for _, cell in ipairs(self.cells) do
        if not cell.revealed then
            return
        end
    end
    self.status = "won"
end

-- Guesses a letter. Repeated or invalid guesses never cost an attempt.
-- Returns { status, key, positions }.
function Round:guess(input)
    if self.status ~= "playing" then
        return { status = "finished" }
    end
    local key = self:keyFor(input)
    if not key then
        return { status = "invalid" }
    end
    if self.guessed[key] then
        return { status = "repeat", key = key }
    end

    self.guessOrder[#self.guessOrder + 1] = key
    local positions = revealKey(self, key, "guess")
    if #positions > 0 then
        self.guessed[key] = "correct"
        self.correctGuesses = self.correctGuesses + 1
        self.lettersFound = self.lettersFound + #positions
        updateStatus(self)
        return { status = "correct", key = key, positions = positions }
    end

    self.guessed[key] = "wrong"
    self.wrong = self.wrong + 1
    updateStatus(self)
    return { status = "wrong", key = key, positions = positions }
end

function Round:hasTextHint()
    local hint = self.puzzle.hint
    return hint ~= nil and hint ~= ""
end

-- Marks the text hint as used (only the first use counts and costs points).
-- Returns false when the puzzle has no hint.
function Round:useTextHint()
    if not self:hasTextHint() then
        return false
    end
    if not self.textHintUsed and self.status == "playing" then
        self.textHintUsed = true
    end
    return true
end

-- True if revealing a letter is allowed: the round is running and at least
-- two different letters are still hidden (a hint never solves the puzzle).
function Round:canRevealLetter()
    if self.status ~= "playing" then
        return false
    end
    local hidden = {}
    local count = 0
    for _, cell in ipairs(self.cells) do
        if not cell.revealed and not hidden[cell.key] then
            hidden[cell.key] = true
            count = count + 1
        end
    end
    return count >= 2
end

-- Reveals every cell of one random hidden letter.
-- Returns { key, positions } or nil when not allowed.
function Round:revealLetter()
    if not self:canRevealLetter() then
        return nil
    end
    local keys, seen = {}, {}
    for _, cell in ipairs(self.cells) do
        if not cell.revealed and not seen[cell.key] then
            seen[cell.key] = true
            keys[#keys + 1] = cell.key
        end
    end
    local key = keys[self.random(#keys)]
    self.guessed[key] = "hint"
    self.guessOrder[#self.guessOrder + 1] = key
    self.revealHints = self.revealHints + 1
    local positions = revealKey(self, key, "hint")
    updateStatus(self)
    return { key = key, positions = positions }
end

-- Reveals the remaining cells (shown after a lost round).
function Round:revealAll()
    for _, cell in ipairs(self.cells) do
        if not cell.revealed then
            cell.revealed = true
            cell.revealedBy = "end"
        end
    end
end

function Round:update(dt)
    if self.status == "playing" then
        self.elapsed = self.elapsed + dt
    end
end

function Round:isWon() return self.status == "won" end
function Round:isLost() return self.status == "lost" end
function Round:isFinished() return self.status ~= "playing" end

function Round:getRemainingAttempts()
    return math.max(0, self.maxWrong - self.wrong)
end

-- "correct" | "wrong" | "hint" | nil for a key (used by the keyboard).
function Round:getKeyState(key)
    return self.guessed[key]
end

-- Fraction of the player's guesses that were correct (0..1).
function Round:getAccuracy()
    local total = self.correctGuesses + self.wrong
    if total == 0 then
        return 1
    end
    return self.correctGuesses / total
end

-- Saving / restoring (used by the Continue feature) -------------------------------------

function Round:serialize()
    local hintKeys = {}
    for key, state in pairs(self.guessed) do
        if state == "hint" then hintKeys[#hintKeys + 1] = key end
    end
    return {
        puzzleId = self.puzzle.id,
        maxWrong = self.maxWrong,
        guessOrder = { unpack(self.guessOrder) },
        hintKeys = hintKeys,
        textHintUsed = self.textHintUsed,
        elapsed = self.elapsed,
    }
end

-- Rebuilds a round from serialize() data by replaying the guesses.
function Round.restore(puzzle, data, options)
    options = options or {}
    options.maxWrongAttempts = data.maxWrong or options.maxWrongAttempts
    local round = Round.new(puzzle, options)
    local isHint = {}
    for _, key in ipairs(data.hintKeys or {}) do isHint[key] = true end
    for _, key in ipairs(data.guessOrder or {}) do
        if isHint[key] then
            if not round.guessed[key] then
                round.guessed[key] = "hint"
                round.guessOrder[#round.guessOrder + 1] = key
                round.revealHints = round.revealHints + 1
                revealKey(round, key, "hint")
                updateStatus(round)
            end
        else
            round:guess(key)
        end
    end
    round.textHintUsed = data.textHintUsed == true
    round.elapsed = tonumber(data.elapsed) or 0
    return round
end

return Round
