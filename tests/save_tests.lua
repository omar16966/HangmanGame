-- Tests for JSON, the save system, and the data modules that use it
-- (profile, statistics, scores, progress, game flow). Plain LuaJIT with an
-- in-memory filesystem.
-- Run from the project root:  luajit tests/save_tests.lua
package.path = "./?.lua;" .. package.path

local Fake = require("tests.fake_love")
Fake.install()

local JSON = require("src.core.json")
local Config = require("src.core.config")
local Settings = require("src.core.settings")
local SaveManager = require("src.managers.save_manager")
local Profile = require("src.managers.profile_manager")
local Stats = require("src.managers.stats_manager")
local Scores = require("src.managers.score_manager")
local Progress = require("src.managers.progress_manager")
local PuzzleManager = require("src.managers.puzzle_manager")
local Session = require("src.gameplay.session")
local Round = require("src.gameplay.round")
local Scoring = require("src.gameplay.scoring")
local GameFlow = require("src.managers.game_flow")
require("src.managers.localization_manager").init()

local passed, failed = 0, 0
local function check(name, actual, expected)
    if actual == expected then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("FAIL %s\n  expected: %s\n  actual:   %s", name, tostring(expected), tostring(actual)))
    end
end

-- JSON ------------------------------------------------------------------------------------------------
local sample = { name = 'لاعب "1"\n\t\\', list = { 1, 2.5, -3, 0 }, nested = { a = { b = { true, false } } },
    empty = {}, text = "برمجة", big = 123456789012, tiny = 0.000123 }
for _, indent in ipairs({ false, 2 }) do
    local text = JSON.encode(sample, { indent = indent or nil })
    local back, err = JSON.decode(text)
    check("json roundtrip " .. tostring(indent), err, nil)
    check("json string with escapes", back.name, sample.name)
    check("json arabic", back.text, "برمجة")
    check("json number list", back.list[2], 2.5)
    check("json big int", back.big, 123456789012)
    check("json tiny", back.tiny, 0.000123)
    check("json nested bool", back.nested.a.b[2], false)
    check("json empty table", next(back.empty), nil)
end
check("json deterministic", JSON.encode({ b = 1, a = 2 }), '{"a":2,"b":1}')
check("json bom ignored", JSON.decode('\239\187\191{"x":1}').x, 1)
check("json surrogate pair", JSON.decode('"\\ud83d\\ude00"'), "😀")
check("json \\u escape", JSON.decode('"\\u0628"'), "ب")
check("json null in object", JSON.decode('{"a":null,"b":1}').a, nil)
check("json null in array skipped", #JSON.decode("[1,null,2]"), 2)
for _, bad in ipairs({ "", "{", '{"a":}', "[1,2", '{"a" 1}', "nul", "[1 2]", '"abc', "{}x", "01x", "1e", '{"a":1,}' }) do
    local value, err = JSON.decode(bad)
    check("json rejects " .. string.format("%q", bad), value == nil and type(err) == "string", true)
end
check("json too deep rejected", JSON.decode(string.rep("[", 100) .. string.rep("]", 100)), nil)
check("json encode function fails", pcall(JSON.encode, { f = print }), false)
check("json encode nan fails", pcall(JSON.encode, { n = 0 / 0 }), false)
check("json not a string", JSON.decode(nil), nil)

-- Helpers ------------------------------------------------------------------------------------------------
local function freshWorld(profile)
    Fake.install()
    Settings.reset(); Profile.reset(); Stats.reset(); Scores.reset(); Progress.reset(); Session.clear()
    SaveManager.init({ profile = profile })
    return Fake.files
end

local function registerAll()
    SaveManager.register("player", Profile)
    SaveManager.register("settings", Settings)
    SaveManager.register("stats", Stats)
    SaveManager.register("scores", Scores)
    SaveManager.register("progress", Progress)
end
registerAll()

PuzzleManager.addPuzzles({
    { id = "T_001", answer = "CAT", category = "animals", hint = "Says meow" },
    { id = "T_002", answer = "FOX", category = "animals" },
    { id = "T_003", answer = "قطة", category = "animals", language = "ar" },
}, "test", { language = "en" })

local function finishedRound(answer, guesses)
    local round = Round.new({ id = "R", answer = answer, language = "en", category = "animals" }, { maxWrongAttempts = 6 })
    for _, g in ipairs(guesses) do round:guess(g) end
    round.elapsed = 12
    return round
end

-- Save and load -------------------------------------------------------------------------------------------
local files = freshWorld()
local report = SaveManager.load()
check("no file = new", report.status, "new")
check("first launch", SaveManager.isFirstLaunch(), true)

Profile.setName("  Omar   Ali ")
Settings.set("interfaceLanguage", "en")
Settings.set("musicVolume", 0.3)
SaveManager.save("test")
check("save.json written", files["save.json"] ~= nil, true)
check("temp file removed", files["save.tmp"], nil)
check("saved file is valid JSON", type(JSON.decode(files["save.json"])), "table")
check("saved version", JSON.decode(files["save.json"]).version, 1)

freshWorld(); files = Fake.files
Fake.files["save.json"] = nil
check("a reset world has no save", SaveManager.load().status, "new")

-- Round trip through the real file.
freshWorld()
Profile.setName("Omar Ali"); Settings.set("interfaceLanguage", "en"); Settings.set("musicVolume", 0.3)
local snapshot = {}
SaveManager.load(); Profile.setName("Omar Ali"); Settings.set("interfaceLanguage", "en"); Settings.set("musicVolume", 0.3)
SaveManager.save("x")
local savedFiles = {}
for k, v in pairs(Fake.files) do savedFiles[k] = v end
Settings.reset(); Profile.reset()
for k, v in pairs(savedFiles) do Fake.files[k] = v end
check("existing save = ok", SaveManager.load().status, "ok")
check("first launch false", SaveManager.isFirstLaunch(), false)
check("name restored", Profile.getName(), "Omar Ali")
check("setting restored", Settings.get("interfaceLanguage"), "en")
check("volume restored", string.format("%.1f", Settings.get("musicVolume")), "0.3")
check("start backup written", Fake.files["save.start.bak"] ~= nil, true)

-- Backups and damaged files ----------------------------------------------------------------------------------
Profile.setName("Second"); SaveManager.save("second")
check("previous save kept as backup", JSON.decode(Fake.files["save.bak"]).player.name, "Omar Ali")

-- Main file damaged -> recovered from save.bak, damaged copy kept.
Fake.files["save.json"] = '{"version": 1, "player": {"name": "Brok'
Profile.reset(); Settings.reset()
local r = SaveManager.load()
check("damaged main -> recovered", r.status, "recovered")
check("recovered from backup", r.source, "save.bak")
check("recovered data", Profile.getName(), "Omar Ali")
check("notice for the player", SaveManager.consumeNotice(), "SAVE_RECOVERED")
check("notice only once", SaveManager.consumeNotice(), nil)
local corruptKept = 0
for name in pairs(Fake.files) do if name:match("^save%.corrupt%-") then corruptKept = corruptKept + 1 end end
check("damaged file preserved", corruptKept, 1)
check("main file repaired", type(JSON.decode(Fake.files["save.json"])), "table")

-- Everything damaged -> defaults, no crash.
Fake.files["save.json"] = "garbage"
Fake.files["save.bak"] = "{{{"
Fake.files["save.start.bak"] = ""
Profile.setName("Gone"); Settings.set("interfaceLanguage", "en")
r = SaveManager.load()
check("all damaged -> reset", r.status, "reset")
check("defaults used", Profile.getName(), "")
check("default language", Settings.get("interfaceLanguage"), "ar")
check("reset counts as first launch", SaveManager.isFirstLaunch(), true)
check("reset notice", SaveManager.consumeNotice(), "SAVE_RESET")

-- Not-an-object and missing version are damage too.
for _, content in ipairs({ "[1,2,3]", '"text"', '{"player":{}}', '{"version":"1"}', '{"version":0}' }) do
    freshWorld(); Fake.files["save.json"] = content
    check("unusable save: " .. content, SaveManager.load().status, "reset")
end

-- One bad section does not spoil the others.
freshWorld()
Fake.files["save.json"] = JSON.encode({ version = 1, player = { name = 42 }, stats = "oops",
    settings = { interfaceLanguage = "en", masterVolume = 99 }, scores = { { score = "x" }, { name = "A", score = 50, rounds = 2, correct = 1, language = "ar", difficulty = "hard" } },
    progress = { level = -5, xp = "a" } })
check("partly bad save loads", SaveManager.load().status, "ok")
check("valid setting kept", Settings.get("interfaceLanguage"), "en")
check("invalid volume reset", Settings.get("masterVolume"), 1)
check("bad name ignored", Profile.getName(), "")
check("bad stats ignored", Stats.get().roundsPlayed, 0)
check("one valid score kept", Scores.count(), 1)
check("bad level reset", Progress.get().level, 1)

-- Newer version is kept as a copy and still read.
freshWorld()
Fake.files["save.json"] = JSON.encode({ version = 99, player = { name = "Future" } })
check("newer save is read", SaveManager.load().status, "ok")
check("newer save copied", Fake.files["save.future.bak"] ~= nil, true)
check("newer data read", Profile.getName(), "Future")

-- Migration ------------------------------------------------------------------------------------------------------------
freshWorld()
local T = SaveManager._test
T.setCurrentVersion(3)
T.migrations[1] = function(d) d.player = { name = (d.playerName or "") .. "+v2" } return d end
T.migrations[2] = function(d) d.player.name = d.player.name .. "+v3" return d end
Fake.files["save.json"] = JSON.encode({ version = 1, playerName = "Old" })
check("migration load ok", SaveManager.load().status, "ok")
check("migrated through two steps", Profile.getName(), "Old+v2+v3")
SaveManager.save("after migration")
check("saved with new version", JSON.decode(Fake.files["save.json"]).version, 3)
-- A migration that fails: file counts as unusable, other backups tried.
freshWorld()
T.migrations[1] = function() error("boom") end
Fake.files["save.json"] = JSON.encode({ version = 1 })
check("failed migration -> reset", SaveManager.load().status, "reset")
T.migrations[1], T.migrations[2] = nil, nil
T.setCurrentVersion(1)

-- Failed writes ----------------------------------------------------------------------------------------------------------
freshWorld()
SaveManager.load()
Profile.setName("Safe"); SaveManager.save("ok")
local good = Fake.files["save.json"]
Fake.failWrites = true
Profile.setName("Lost")
check("write failure reported", SaveManager.save("fail"), false)
check("old save untouched", Fake.files["save.json"], good)
check("failure notice", SaveManager.consumeNotice(), "SAVE_FAILED")
Fake.failWrites = false
-- Failure while writing the real file keeps the verified temporary copy.
Fake.failWriteTo = "save.json"
check("main write failure reported", SaveManager.save("fail2"), false)
check("verified temp copy kept", type(JSON.decode(Fake.files["save.tmp"] or "")), "table")
Fake.failWriteTo = nil

-- Autosave debounce -------------------------------------------------------------------------------------------------------
freshWorld()
SaveManager.load()
Fake.writes = 0
SaveManager.markDirty()
SaveManager.update(0.5)
check("not saved before the delay", Fake.writes, 0)
SaveManager.markDirty()
SaveManager.update(0.6)
check("still waiting (changed again)", Fake.writes, 0)
SaveManager.update(0.6)
check("saved after the delay", Fake.writes > 0, true)
check("clean after saving", SaveManager.isDirty(), false)
-- Continuous changes are saved anyway after the maximum wait.
Fake.writes = 0
for _ = 1, 100 do SaveManager.markDirty(); SaveManager.update(0.1) end
check("max wait forces a save", Fake.writes > 0, true)
-- Retry only after the retry delay when writing fails.
Fake.failWrites = true
SaveManager.markDirty(); SaveManager.update(1.1)
Fake.writes = 0
SaveManager.update(1.0)
check("no hammering after a failure", Fake.writes, 0)
Fake.failWrites = false
SaveManager.update(6.0)
check("retries later", SaveManager.isDirty(), false)

-- Read-only mode (development) -------------------------------------------------------------------------------------------
Fake.install(); SaveManager.init({ readOnly = true })
Profile.reset(); SaveManager.load(); SaveManager.markDirty(); SaveManager.update(10); SaveManager.save("x")
check("read-only writes nothing", next(Fake.files), nil)

-- Profile folders ---------------------------------------------------------------------------------------------------------
freshWorld("test one")
SaveManager.load(); Profile.setName("P"); SaveManager.save("x")
check("profile folder used", Fake.files["profiles/test_one/save.json"] ~= nil, true)

-- Profile names -------------------------------------------------------------------------------------------------------------
check("name trimmed and collapsed", Profile.sanitizeName("  a   b  "), "a b")
check("name length limited", Profile.nameLength(Profile.sanitizeName(string.rep("x", 40))), Config.save.nameMaxLength)
check("name arabic kept", Profile.sanitizeName("عمر"), "عمر")
check("name control chars removed", Profile.sanitizeName("a\1b\n\tc"), "abc")
check("name bidi override removed", Profile.sanitizeName("a\226\128\174b"), "ab")
check("name empty", Profile.sanitizeName("   "), "")
check("typing keeps one trailing space", Profile.filterTyping("ab "), "ab ")
check("typing drops leading space", Profile.filterTyping("  ab"), "ab")
check("typing removes bidi controls", Profile.filterTyping("a\226\128\174"), "a")
check("stored name has no trailing space", Profile.sanitizeName("ab "), "ab")
check("name not a string", Profile.sanitizeName(nil), "")

-- Statistics ------------------------------------------------------------------------------------------------------------------
Stats.reset(); Session.start({ language = "en", difficulty = "normal", category = "animals" })
local winRound = finishedRound("CAT", { "x", "c", "a", "t" })
local sr = Scoring.calculate(winRound, "normal")
local session = Session.recordRound(winRound, sr)
Stats.recordRound(winRound, sr, session, true)
local st = Stats.get()
check("stats rounds", st.roundsPlayed, 1)
check("stats won", st.roundsWon, 1)
check("stats games", st.gamesPlayed, 1)
check("stats english games", st.englishGames, 1)
check("stats correct", st.correctGuesses, 3)
check("stats wrong", st.wrongGuesses, 1)
check("stats streak", st.currentStreak, 1)
check("stats play time", st.playTime, 12)
check("stats best score", st.bestScore, session.score)
check("stats not perfect (one wrong)", st.perfectRounds, 0)
local perfect = finishedRound("CAT", { "c", "a", "t" })
local sr2 = Scoring.calculate(perfect, "normal")
Stats.recordRound(perfect, sr2, Session.recordRound(perfect, sr2), false)
check("perfect round counted", Stats.get().perfectRounds, 1)
check("games only counted once", Stats.get().gamesPlayed, 1)
check("streak grows", Stats.get().bestStreak, 2)
local lost = finishedRound("CAT", { "x", "y", "z", "q", "w", "v" })
local sr3 = Scoring.calculate(lost, "normal")
Stats.recordRound(lost, sr3, Session.recordRound(lost, sr3), false)
check("loss resets streak", Stats.get().currentStreak, 0)
check("best streak kept", Stats.get().bestStreak, 2)
check("rounds lost", Stats.get().roundsLost, 1)
check("win rate", string.format("%.2f", Stats.getWinRate()), "0.67")
local before = Stats.export()
Stats.load({ roundsPlayed = -5, roundsWon = "x", bestScore = 1e99, playTime = 12.5, gamesPlayed = 3.7 })
check("stats invalid values reset", Stats.get().roundsPlayed, 0)
check("stats huge value reset", Stats.get().bestScore, 0)
check("stats play time keeps fraction", Stats.get().playTime, 12.5)
check("stats counters are whole", Stats.get().gamesPlayed, 3)
Stats.load(before)
check("stats export/load", Stats.get().roundsPlayed, 3)

-- Scores ------------------------------------------------------------------------------------------------------------------------
Scores.reset()
local function sess(score, language, difficulty, rounds, won)
    return { score = score, roundsPlayed = rounds or 3, roundsWon = won or 2, language = language or "ar", difficulty = difficulty or "normal" }
end
check("zero score not recorded", Scores.submit(sess(0), "A"), nil)
check("no rounds not recorded", Scores.submit(sess(50, "ar", "normal", 0), "A"), nil)
Scores.submit(sess(300, "ar", "hard"), "Ali", 100)
Scores.submit(sess(500, "en", "easy"), "Sara", 200)
Scores.submit(sess(300, "ar", "easy"), "Omar", 50)
Scores.submit(sess(120, "en", "normal"), "Lina", 300)
check("scores count", Scores.count(), 4)
check("best first", Scores.getTop({}, 10)[1].name, "Sara")
check("tie: earlier first", Scores.getTop({}, 10)[2].name, "Omar")
check("filter language", #Scores.getTop({ language = "en" }, 10), 2)
check("filter difficulty", Scores.getTop({ difficulty = "easy" }, 10)[2].name, "Omar")
check("filter both", #Scores.getTop({ language = "ar", difficulty = "hard" }, 10), 1)
check("limit", #Scores.getTop({}, 2), 2)
check("last entry remembered", Scores.lastEntry.name, "Lina")
local exported = Scores.export()
Scores.load(exported)
check("scores export/load", Scores.count(), 4)
Scores.load({ { score = 10, rounds = 1, correct = 5, language = "ar", difficulty = "easy" },
    { score = 10, rounds = 1, correct = 1, language = "xx", difficulty = "easy" },
    { score = 10, rounds = 1, correct = 1, language = "ar", difficulty = "order" }, "junk", 5,
    { score = 77, rounds = 1, correct = 1, language = "ar", difficulty = "easy", name = "OK" } })
check("invalid score entries dropped", Scores.count(), 1)
for i = 1, Config.save.maxScores + 20 do Scores.submit(sess(i), "N", i) end
check("scores limited", Scores.count(), Config.save.maxScores)

-- Game flow ------------------------------------------------------------------------------------------------------------------------
freshWorld(); SaveManager.load(); Profile.setName("Tester")
GameFlow.startNewGame({ language = "en", difficulty = "normal", category = "animals" })
check("new game session", Session.peek().language, "en")

local round = Round.new(PuzzleManager.get("T_001"), { maxWrongAttempts = 6, random = function() return 1 end })
round:guess("c"); round:guess("z"); round:useTextHint(); round.elapsed = 7
local params = { language = "en", difficulty = "normal", category = "animals" }
GameFlow.snapshot(params, round)
check("snapshot stored", SaveManager.getSuspended() ~= nil, true)
check("resume available", GameFlow.hasResume(), true)
SaveManager.save("x")

-- Restart the world from the saved file and continue.
local persisted = {}
for k, v in pairs(Fake.files) do persisted[k] = v end
freshWorld(); for k, v in pairs(persisted) do Fake.files[k] = v end
SaveManager.load()
check("suspended game loaded", SaveManager.getSuspended() ~= nil, true)
local resume = GameFlow.getResume()
check("resume params", resume and resume.language, "en")
local restored = Round.restore(PuzzleManager.get(resume.restore.puzzleId), resume.restore, {})
check("restored guesses", restored.wrong, 1)
check("restored elapsed", restored.elapsed, 7)
check("restored hint flag", restored.textHintUsed, true)
check("restored letters", restored.cells[1].revealed, true)

-- A saved round whose puzzle no longer exists is dropped.
SaveManager.setSuspended({ round = { puzzleId = "GONE", maxWrong = 6, guessOrder = {}, hintKeys = {}, elapsed = 0 },
    params = params, session = {}, savedAt = 0 })
check("resume of missing puzzle refused", GameFlow.getResume(), nil)
check("and discarded", SaveManager.getSuspended(), nil)

-- Validation of damaged suspended data.
local good = { round = { puzzleId = "T_001", maxWrong = 6, guessOrder = { 67 }, hintKeys = {}, elapsed = 3 }, params = params, session = {} }
check("suspended valid", T.cleanSuspended(good) ~= nil, true)
for name, mutate in pairs({
    noRound = function(d) d.round = nil end,
    badPuzzle = function(d) d.round.puzzleId = 5 end,
    badMax = function(d) d.round.maxWrong = 0 end,
    hugeMax = function(d) d.round.maxWrong = 1000 end,
    badGuesses = function(d) d.round.guessOrder = { "a" } end,
    tooManyGuesses = function(d) d.round.guessOrder = (function() local t = {} for i = 1, 300 do t[i] = 65 end return t end)() end,
    badLanguage = function(d) d.params.language = "xx" end,
    badDifficulty = function(d) d.params.difficulty = "order" end,
}) do
    local copy = JSON.decode(JSON.encode(good))
    mutate(copy)
    check("suspended rejects " .. name, T.cleanSuspended(copy), nil)
end

-- Ending a game records the score once, and the session is cleared.
freshWorld(); SaveManager.load(); Profile.setName("Hero")
GameFlow.startNewGame({ language = "en", difficulty = "hard", category = "all" })
local won = finishedRound("CAT", { "c", "a", "t" })
GameFlow.recordRound(won, Scoring.calculate(won, "hard"))
check("round recorded in stats", Stats.get().roundsPlayed, 1)
check("recording saved immediately", type(JSON.decode(Fake.files["save.json"])), "table")
check("no score before the game ends", Scores.count(), 0)
GameFlow.endSession()
check("score recorded at game end", Scores.count(), 1)
check("score has name", Scores.getTop({}, 1)[1].name, "Hero")
check("score has difficulty", Scores.getTop({}, 1)[1].difficulty, "hard")
check("session cleared", Session.peek(), nil)
GameFlow.endSession()
check("no double entry", Scores.count(), 1)

-- Quitting: a saved round keeps the game open; otherwise the score is kept.
freshWorld(); SaveManager.load()
GameFlow.startNewGame({ language = "en", difficulty = "normal", category = "all" })
GameFlow.recordRound(won, Scoring.calculate(won, "normal"))
local active = Round.new(PuzzleManager.get("T_002"), { maxWrongAttempts = 6 })
GameFlow.snapshot(params, active)
GameFlow.finalizeOnQuit()
check("quit with saved round keeps the game open", Scores.count(), 0)
check("saved round survives", JSON.decode(Fake.files["save.json"]).suspended ~= nil, true)
SaveManager.setSuspended(nil)
GameFlow.finalizeOnQuit()
check("quit without saved round ends the game", Scores.count(), 1)

-- Starting a new game over an old one ends the old one.
freshWorld(); SaveManager.load()
GameFlow.startNewGame({ language = "ar", difficulty = "easy", category = "all" })
GameFlow.recordRound(won, Scoring.calculate(won, "easy"))
GameFlow.startNewGame({ language = "en", difficulty = "easy", category = "all" })
check("old game scored when replaced", Scores.count(), 1)
check("new session empty", Session.peek().roundsPlayed, 0)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
