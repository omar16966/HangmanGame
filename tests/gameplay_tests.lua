-- Pure-Lua unit tests for gameplay rules (normalization, rounds, scoring,
-- puzzle validation and selection).
-- Run from the project root:  luajit tests/gameplay_tests.lua
package.path = "./?.lua;" .. package.path

local Normalizer = require("src.gameplay.normalizer")
local Round = require("src.gameplay.round")
local Scoring = require("src.gameplay.scoring")
local Session = require("src.gameplay.session")
local PuzzleManager = require("src.managers.puzzle_manager")
local Config = require("src.core.config")
local Utf8 = require("src.localization.utf8_util")

local passed, failed = 0, 0
local function check(name, actual, expected)
    if actual == expected then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("FAIL %s\n  expected: %s\n  actual:   %s", name, tostring(expected), tostring(actual)))
    end
end

local function cp(s) return Utf8.decode(s)[1] end
local function hidden(round)
    local out = {}
    for _, cell in ipairs(round.cells) do
        out[#out + 1] = cell.revealed and Utf8.char(cell.cp) or "_"
    end
    return table.concat(out)
end
local function fixedRandom(n) return 1 end

-- Normalizer ---------------------------------------------------------------------------------
Normalizer.configure(Config.normalization.arabic)
check("en lowercase key", Normalizer.key(cp("a"), "en"), cp("A"))
check("en digit not guessable", Normalizer.key(cp("7"), "en"), nil)
check("en arabic letter not guessable", Normalizer.key(cp("ب"), "en"), nil)
check("ar alef hamza above", Normalizer.key(cp("أ"), "ar"), cp("ا"))
check("ar alef hamza below", Normalizer.key(cp("إ"), "ar"), cp("ا"))
check("ar alef madda", Normalizer.key(cp("آ"), "ar"), cp("ا"))
check("ar alef maqsura kept by default", Normalizer.key(cp("ى"), "ar"), cp("ى"))
check("ar ta marbuta kept by default", Normalizer.key(cp("ة"), "ar"), cp("ة"))
check("ar latin not guessable", Normalizer.key(cp("a"), "ar"), nil)
check("ar diacritic ignored", Normalizer.isIgnored(cp("َ"), "ar"), true)
check("ar tatweel ignored", Normalizer.isIgnored(cp("ـ"), "ar"), true)
Normalizer.configure({ alefMaqsura = true, taMarbuta = true })
check("ar optional maqsura rule", Normalizer.key(cp("ى"), "ar"), cp("ي"))
check("ar optional ta marbuta rule", Normalizer.key(cp("ة"), "ar"), cp("ه"))
check("ar merged key not canonical", Normalizer.isCanonical(cp("ى"), "ar"), false)
Normalizer.configure(Config.normalization.arabic)

-- Round: English ------------------------------------------------------------------------------
local en = { id = "T1", answer = "Video Game!", language = "en", category = "games", difficulty = "easy" }
local r = Round.new(en, { maxWrongAttempts = 3 })
check("en cells skip space", #r.cells, 10)
check("en words", #r.words, 2)
check("en punctuation auto revealed", hidden(r), "_________!")
check("en letter count", r.letterCount, 9)
check("en guess lowercase", r:guess("e").status, "correct")
check("en duplicates revealed", hidden(r), "___e____e!")
check("en repeat no penalty", r:guess("E").status, "repeat")
check("en repeat wrong count", r.wrong, 0)
check("en invalid digit", r:guess("5").status, "invalid")
check("en wrong guess", r:guess("z").status, "wrong")
check("en wrong repeat", r:guess("Z").status, "repeat")
check("en wrong counted once", r.wrong, 1)
for _, c in ipairs({ "v", "i", "d", "o", "g", "a" }) do r:guess(c) end
check("en not yet won", r:isWon(), false)
check("en last letter", r:guess("m").status, "correct")
check("en won", r:isWon(), true)
check("en finished ignores guesses", r:guess("q").status, "finished")
check("en accuracy", string.format("%.3f", r:getAccuracy()), string.format("%.3f", 8 / 9))

local lose = Round.new({ id = "T2", answer = "ABC", language = "en", category = "games" }, { maxWrongAttempts = 2 })
lose:guess("x"); lose:guess("y")
check("en lost", lose:isLost(), true)
lose:revealAll()
check("en reveal all after loss", hidden(lose), "ABC")

-- Round: Arabic ------------------------------------------------------------------------------
local ar = { id = "T3", answer = "الذَّكاء الاصطناعي", language = "ar", category = "technology", hint = "AI" }
local a = Round.new(ar, { maxWrongAttempts = 6, random = fixedRandom })
check("ar diacritics not cells", #a.cells, 15)
check("ar words", #a.words, 2)
check("ar hamza guessable", a.cells[6].isLetter, true)
check("ar guess plain alef matches", a:guess("ا").status, "correct")
check("ar alef revealed count", a.lettersFound, 5)
check("ar guess hamza-alef = repeat", a:guess("أ").status, "repeat")
check("ar wrong", a:guess("ق").status, "wrong")
check("ar text hint", a:useTextHint(), true)
check("ar text hint used", a.textHintUsed, true)
local reveal = a:revealLetter()
check("ar reveal letter", reveal ~= nil, true)
check("ar reveal counted", a.revealHints, 1)
check("ar revealed key marked as hint", a:getKeyState(reveal.key), "hint")

-- Hints never solve the puzzle.
local two = Round.new({ id = "T4", answer = "AB", language = "en", category = "games" }, { random = fixedRandom })
check("reveal allowed with 2 hidden", two:revealLetter() ~= nil, true)
check("reveal refused with 1 hidden", two:revealLetter(), nil)

-- Save / restore.
local saved = a:serialize()
local restored = Round.restore(ar, saved, { random = fixedRandom })
check("restore cells", hidden(restored), hidden(a))
check("restore wrong", restored.wrong, a.wrong)
check("restore hints", restored.revealHints, a.revealHints)
check("restore text hint", restored.textHintUsed, true)

-- Scoring --------------------------------------------------------------------------------------
local s = Config.score
local win = Round.new({ id = "T5", answer = "CAT", language = "en", category = "animals" }, { maxWrongAttempts = 6 })
win:guess("x"); win:guess("c"); win:guess("a"); win:guess("t")
win.elapsed = 0
local res = Scoring.calculate(win, "normal")
local expected = s.completePuzzle + 3 * s.correctLetter + 5 * s.remainingAttemptBonus + s.speedBonusMax - s.wrongGuessPenalty
check("score subtotal", res.subtotal, expected)
check("score multiplier", res.total, math.floor(expected * Config.difficulty.normal.scoreMultiplier + 0.5))
win.elapsed = 1000
check("speed bonus decays to 0", Scoring.speedBonus(win), 0)
local res2 = Scoring.calculate(lose, "hard")
check("lost round never negative", res2.total, 0)

Session.start()
Session.recordRound(win, res)
Session.recordRound(lose, res2)
check("session rounds", Session.get().roundsPlayed, 2)
check("session streak reset", Session.get().streak, 0)
check("session score", Session.get().score, res.total)

-- Puzzle validation and selection ----------------------------------------------------------------
local added, rejected = PuzzleManager.addPuzzles({
    { id = "P1", answer = "DOG", category = "animals", difficulty = "easy" },
    { id = "P2", answer = "  BIG   CAT ", category = "animals", difficulty = "hard" },
    { id = "P1", answer = "DUPLICATE", category = "animals" },
    { id = "P3", answer = "", category = "animals" },
    { id = "P4", answer = "COW", category = "nope" },
    { id = "P5", answer = "CAFÉ", category = "food" },
    { id = "P6", answer = "123", category = "general" },
    { answer = "NOID", category = "general" },
    { id = "P7", answer = "HORSE", category = "animals", difficulty = "extreme" },
    { id = "P8", answer = "FOX", category = "animals" },
}, "test", { language = "en" })
check("valid puzzles added", added, 3)
check("invalid puzzles rejected", rejected, 7)
check("answer whitespace cleaned", PuzzleManager.get("P2").answer, "BIG CAT")
check("default difficulty", PuzzleManager.get("P8").difficulty, "normal")
check("arabic pack in english rejected", (PuzzleManager.addPuzzles({ { id = "P9", answer = "قطة", category = "animals" } }, "test", { language = "en" })), 0)

check("pick prefers difficulty", PuzzleManager.pick({ language = "en", difficulty = "hard" }, fixedRandom).id, "P2")
check("pick falls back when no difficulty match",
    PuzzleManager.pick({ language = "en", category = "animals", difficulty = "missing" }, fixedRandom) ~= nil, true)
check("pick none for empty language", PuzzleManager.pick({ language = "ar" }, fixedRandom), nil)

-- Recent history: never repeats while alternatives exist.
PuzzleManager.setRecentHistory({})
local seen, repeats = nil, 0
for _ = 1, 20 do
    local p = PuzzleManager.pick({ language = "en", category = "animals" }, function(n) return n end)
    if p.id == seen then repeats = repeats + 1 end
    seen = p.id
    PuzzleManager.markPlayed(p.id)
end
check("no immediate repeats", repeats, 0)

-- Scene stage mapping: every difficulty walks through all stages ----------------------------------
local Scene = require("src.gameplay.scene")
local function stages(maxWrong)
    local out = {}
    for w = 0, maxWrong do out[#out + 1] = Scene.stageFor(w, maxWrong) end
    return table.concat(out, ",")
end
check("stages normal (6)", stages(6), "0,1,2,3,4,5,6")
check("stages easy (8)", stages(8), "0,1,2,3,3,4,5,5,6")
check("stages hard (5)", stages(5), "0,2,3,4,5,6")
check("stages tiny (2)", stages(2), "0,5,6")

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
