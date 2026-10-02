-- Gameplay: one puzzle round at a time.
--
-- Layout (640x360):
--   top bar      score (start side) / category + difficulty (end side)
--   scene        wooden frame, rope and character
--   word         letter cells
--   message      hint text or short feedback
--   keyboard     on-screen keyboard of the puzzle language
--   bottom bar   remaining attempts (start side) / hint buttons (end side)
--
-- Params: { language, category, difficulty } (defaults from Settings),
-- replayPuzzleId (play this puzzle again), restore (a saved round to continue,
-- see GameFlow.getResume).

local State = require("src.states.state")
local Config = require("src.core.config")
local Input = require("src.core.input")
local Settings = require("src.core.settings")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local PuzzleManager = require("src.managers.puzzle_manager")
local GameFlow = require("src.managers.game_flow")
local Palette = require("src.graphics.palette")
local Placeholders = require("src.graphics.placeholders")
local Renderer = require("src.graphics.renderer")
local Round = require("src.gameplay.round")
local Scoring = require("src.gameplay.scoring")
local Session = require("src.gameplay.session")
local Scene = require("src.gameplay.scene")
local WordDisplay = require("src.gameplay.word_display")
local VirtualKeyboard = require("src.ui.virtual_keyboard")
local Button = require("src.ui.button")
local StateManager = require("src.core.state_manager")
local Constants = require("src.core.constants")
local Icons = require("src.ui.icons")
local keyboards = require("data.keyboards")

local L = Localization.L

local GameplayState = State.extend("gameplay")

local VW, VH = Config.virtualWidth, Config.virtualHeight
local MARGIN = 12
local SCENE_X, SCENE_Y = math.floor((VW - Scene.WIDTH) / 2), 22
local FLOOR_Y = SCENE_Y + 138
local KEYBOARD_Y = 236
local WORD_BOTTOM = 218
local MESSAGE_Y = 221
local BOTTOM_Y = 338
local MESSAGE_TIME = 1.8

-- Setup -------------------------------------------------------------------------------------------

function GameplayState:enter(params)
    self.replayPuzzleId = params.replayPuzzleId
    self.language = params.language or Settings.get("puzzleLanguage")
    self.category = params.category or "all"
    self.difficulty = params.difficulty or Settings.get("difficulty")
    if not Config.difficulty[self.difficulty] then
        self.difficulty = "normal"
    end
    self.restoreData = params.restore
    local session = Session.get()
    if session.language == "" then
        session.language, session.difficulty, session.category = self.language, self.difficulty, self.category
    end

    self.scene = Scene.new(SCENE_X, SCENE_Y)
    self:createButtons()
    self:startRound()
end

function GameplayState:createButtons()
    self.hintButton = Button.new({
        w = 60, h = 18, autoWidth = true, textKey = "HINT", icon = "hint",
        onClick = function() self:useTextHint() end,
    })
    self.revealButton = Button.new({
        w = 60, h = 18, autoWidth = true, textKey = "HINT_REVEAL", icon = "reveal",
        onClick = function() self:useRevealHint() end,
    })
    self.buttons = { self.hintButton, self.revealButton }
    self.pauseButton = Button.new({
        w = 22, h = 18, icon = "pause", tooltipKey = "PAUSED",
        onClick = function() self:openPause() end,
    })
end

-- Parameters to start another round with the same choices.
function GameplayState:getParams()
    return { language = self.language, category = self.category, difficulty = self.difficulty }
end

function GameplayState:openPause()
    if self.round and not self.round:isFinished() then
        self:saveSnapshot()
        StateManager.push(Constants.States.PAUSE, {
            gameplayParams = self:getParams(),
            puzzleId = self.round.puzzle.id,
        })
    end
end

-- Places the bottom buttons on the end side of the interface direction.
function GameplayState:layoutButtons()
    local rtl = Localization.isRTL()
    local gap = 6
    for _, b in ipairs(self.buttons) do
        b:fit()
    end
    self.pauseButton:setPosition(rtl and MARGIN or (VW - MARGIN - self.pauseButton.w), 4)
    if rtl then
        local x = MARGIN
        for i = #self.buttons, 1, -1 do
            local b = self.buttons[i]
            b:setPosition(x, BOTTOM_Y)
            x = x + b.w + gap
        end
    else
        local x = VW - MARGIN
        for i = #self.buttons, 1, -1 do
            local b = self.buttons[i]
            x = x - b.w
            b:setPosition(x, BOTTOM_Y)
            x = x - gap
        end
    end
end

function GameplayState:startRound()
    self.finishTimer = nil
    self.message = nil
    self.hintText = nil
    self.scoreResult = nil

    -- A saved round (Continue): rebuild it by replaying the saved guesses.
    local restored = nil
    local restore = self.restoreData
    self.restoreData = nil
    if restore then
        local saved = PuzzleManager.get(restore.puzzleId)
        if saved then
            restored = Round.restore(saved, restore, { random = love.math.random })
            if restored:isFinished() then
                restored = nil
            end
        end
    end

    if restored then
        self.round = restored
        self.noPuzzles = false
    else
        -- "Replay" / "Restart round" play the same puzzle again.
        local puzzle = self.replayPuzzleId and PuzzleManager.get(self.replayPuzzleId)
        self.replayPuzzleId = nil
        puzzle = puzzle or PuzzleManager.pick({
            language = self.language,
            category = self.category,
            difficulty = self.difficulty,
        })
        if not puzzle then
            self.round = nil
            self.noPuzzles = true
            return
        end
        self.noPuzzles = false
        PuzzleManager.markPlayed(puzzle.id)
        self.round = Round.new(puzzle, {
            maxWrongAttempts = Config.difficulty[self.difficulty].maxWrongAttempts,
            random = love.math.random,
        })
    end
    self.scene:reset()
    if restored then
        self.scene:setStage(Scene.stageFor(restored.wrong, restored.maxWrong))
        if restored.textHintUsed then
            self.hintText = PuzzleManager.getHint(restored.puzzle, Localization.getLanguage())
        end
    end
    self.wordDisplay = WordDisplay.new(self.round, { centerX = VW / 2, y = 0, maxWidth = VW - 2 * MARGIN })
    self.wordDisplay.area.y = WORD_BOTTOM - self.wordDisplay:getHeight()
    self.wordDisplay:layout()

    if not self.keyboard or self.keyboard.language ~= self.language then
        self.keyboard = VirtualKeyboard.new({
            language = self.language,
            centerX = VW / 2,
            y = KEYBOARD_Y,
            onPress = function(key) self:guess(key) end,
        })
    end
    self.keyboard:setEnabled(true)
    self.keyboard:setStateProvider(function(key) return self.round:getKeyState(key) end)
    self:updateButtons()
    self:saveSnapshot()
end

-- Remembers the round in progress, so the game can be continued later
-- (also after the application was closed).
function GameplayState:saveSnapshot()
    if self.round and not self.round:isFinished() then
        GameFlow.snapshot(self:getParams(), self.round)
    end
end

function GameplayState:onQuit()
    self:saveSnapshot()
end

function GameplayState:updateButtons()
    local round = self.round
    local playing = round and not round:isFinished()
    self.hintButton:setEnabled(playing and round:hasTextHint() or false)
    self.revealButton:setEnabled(playing and round:canRevealLetter() or false)
end

-- Gameplay actions -----------------------------------------------------------------------------------

function GameplayState:showMessage(key)
    self.message = { key = key, time = MESSAGE_TIME }
end

function GameplayState:guess(input)
    local round = self.round
    if not round or round:isFinished() then
        return
    end
    local result = round:guess(input)
    if result.status == "correct" then
        self.keyboard:flashKey(result.key)
        self.wordDisplay:onReveal(result.positions)
        self.scene:onCorrect()
        self:saveSnapshot()
    elseif result.status == "wrong" then
        self.keyboard:flashKey(result.key)
        self.scene:onWrong(Scene.stageFor(round.wrong, round.maxWrong))
        self:saveSnapshot()
    elseif result.status == "repeat" then
        self:showMessage("ALREADY_GUESSED")
    elseif result.status == "invalid" then
        self:showMessage(self.language == "ar" and "TYPE_ARABIC" or "TYPE_ENGLISH")
    end
    if round:isFinished() then
        self:finishRound()
    end
    self:updateButtons()
end

function GameplayState:useTextHint()
    if not self.round or not self.round:useTextHint() then
        self:showMessage("NO_HINT")
        return
    end
    self.hintText = PuzzleManager.getHint(self.round.puzzle, Localization.getLanguage())
    self:updateButtons()
    self:saveSnapshot()
end

function GameplayState:useRevealHint()
    local reveal = self.round and self.round:revealLetter()
    if not reveal then
        self:showMessage("NOTHING_TO_REVEAL")
        return
    end
    self.keyboard:flashKey(reveal.key)
    self.wordDisplay:onReveal(reveal.positions)
    self.scene:onCorrect()
    self:updateButtons()
    self:saveSnapshot()
end

function GameplayState:finishRound()
    local round = self.round
    if round:isLost() then
        round:revealAll()
    else
        self.scene:onWin()
    end
    self.wordDisplay:setFinished(round.status)
    self.scoreResult = Scoring.calculate(round, self.difficulty)
    GameFlow.recordRound(round, self.scoreResult)
    self.keyboard:setEnabled(false)
    self.finishTimer = round:isWon() and Config.gameplay.resultDelayWin or Config.gameplay.resultDelayLoss
    if round:isWon() then
        Renderer.shake(1, 0.25)
    end
end

-- Update ---------------------------------------------------------------------------------------------

function GameplayState:update(dt)
    Session.update(dt)
    self:layoutButtons()
    for _, b in ipairs(self.buttons) do
        b:update(dt)
    end
    self.pauseButton:update(dt)
    if not self.round then
        return
    end

    self.round:update(dt)
    self.scene:update(dt)
    self.wordDisplay:update(dt)
    self.keyboard:update(dt)

    -- The character looks at the hovered/focused key, else at the cursor.
    local key = self.keyboard:getHoveredKey()
    if not key and Input.lastDevice == "keyboard" then
        key = self.keyboard:getFocusedKey()
    end
    if key then
        self.scene:setLookTarget(key.x + self.keyboard.keyW / 2, key.y)
    else
        local mx, my, inside = Input.getMousePosition()
        self.scene:setLookTarget(inside and mx or nil, my)
    end

    if self.message then
        self.message.time = self.message.time - dt
        if self.message.time <= 0 then
            self.message = nil
        end
    end

    if self.finishTimer then
        self.finishTimer = self.finishTimer - dt
        if self.finishTimer <= 0 then
            self.finishTimer = nil
            StateManager.switch(Constants.States.RESULT, {
                round = self.round,
                scoreResult = self.scoreResult,
                gameplayParams = self:getParams(),
            })
        end
    end
end

-- Input --------------------------------------------------------------------------------------------------

-- Letters arrive through textinput (works with any OS keyboard layout).
function GameplayState:textinput(text)
    if not self.round or self.round:isFinished() then
        return true
    end
    if self.language == "ar" then
        local mapped = keyboards.ar.latinToArabic[text:lower()]
        if mapped then
            text = mapped
        end
    end
    self:guess(text)
    return true
end

function GameplayState:keypressed(key)
    -- Single printable keys are letters for the puzzle: stop them from also
    -- triggering actions (e.g. "p" = pause). Their text comes via textinput.
    if #key == 1 then
        return true
    end
    return false
end

function GameplayState:action(action)
    local A = Input.Actions
    if self.noPuzzles then
        if action == A.CONFIRM or action == A.BACK then
            StateManager.switch(Constants.States.CATEGORY)
        end
        return true
    end
    if action == A.BACK or action == A.PAUSE then
        self:openPause()
        return true
    end
    if not self.round or self.round:isFinished() then
        return true
    end
    if action == A.LEFT then
        self.keyboard:moveFocus(-1, 0)
    elseif action == A.RIGHT then
        self.keyboard:moveFocus(1, 0)
    elseif action == A.UP then
        self.keyboard:moveFocus(0, -1)
    elseif action == A.DOWN then
        self.keyboard:moveFocus(0, 1)
    elseif action == A.CONFIRM then
        self.keyboard:pressFocused()
    end
    return true
end

function GameplayState:mousepressed(x, y, button)
    if self.pauseButton:mousepressed(x, y, button) then
        return true
    end
    for _, b in ipairs(self.buttons) do
        if b:mousepressed(x, y, button) then return true end
    end
    if self.keyboard and self.keyboard:mousepressed(x, y, button) then
        return true
    end
    return false
end

function GameplayState:mousereleased(x, y, button)
    if self.pauseButton:mousereleased(x, y, button) then
        return true
    end
    for _, b in ipairs(self.buttons) do
        if b:mousereleased(x, y, button) then return true end
    end
    if self.keyboard then
        self.keyboard:mousereleased(x, y, button)
    end
    return true
end

function GameplayState:debugInfo()
    local round = self.round
    if not round then
        return { "Gameplay: no puzzle" }
    end
    return {
        string.format("Puzzle %s [%s/%s/%s]  answer: %s", round.puzzle.id, round.language,
            round.puzzle.category, round.puzzle.difficulty, round.puzzle.answer),
        string.format("Wrong %d/%d  stage %d  elapsed %.1fs  status %s", round.wrong, round.maxWrong,
            self.scene.stage, round.elapsed, round.status),
    }
end

-- Drawing -----------------------------------------------------------------------------------------------

function GameplayState:drawBackground()
    local image = Assets.images.backgroundGameplay
    love.graphics.setColor(1, 1, 1, 1)
    if image then
        love.graphics.draw(image, 0, 0)
    else
        Placeholders.drawGameplayBackground(VW, VH, FLOOR_Y)
    end
end

function GameplayState:drawTopBar()
    local session = Session.get()
    local running = self.round and not self.round:isFinished() and Scoring.running(self.round) or 0
    local opts = { width = VW - 2 * MARGIN, color = Palette.text, shadowColor = Palette.black }

    opts.align = "start"
    Localization.draw("SCORE_VALUE", MARGIN, 5, opts, { value = session.score + running })

    if self.round then
        -- Category and difficulty on the end side, next to the pause button.
        local inset = self.pauseButton.w + 6
        local x = Localization.isRTL() and (MARGIN + inset) or MARGIN
        opts.width = VW - 2 * MARGIN - inset
        opts.align = "end"
        opts.color = Palette.primary
        Localization.drawText(PuzzleManager.getCategoryName(self.round.puzzle.category, Localization.getLanguage()),
            x, 5, opts)
        opts.color = Palette.textDim
        Localization.draw("DIFFICULTY_" .. self.difficulty:upper(), x, 18, opts)
    end
end

function GameplayState:drawAttempts()
    local round = self.round
    local remaining = round:getRemainingAttempts()
    local rtl = Localization.isRTL()
    local step = Icons.SIZE + 2
    for i = 1, round.maxWrong do
        local filled = i <= remaining
        local x
        if rtl then
            x = VW - MARGIN - i * step + 2
        else
            x = MARGIN + (i - 1) * step
        end
        Icons.draw(filled and "heart" or "heart_empty", x, BOTTOM_Y + 1,
            filled and Palette.incorrect or Palette.textDim)
    end
end

function GameplayState:drawMessage()
    local text, color
    if self.message then
        text, color = L(self.message.key), Palette.highlight
    elseif self.hintText then
        text, color = self.hintText, Palette.secondary
    end
    if text then
        Localization.drawText(text, MARGIN, MESSAGE_Y, {
            width = VW - 2 * MARGIN, align = "center", color = color, shadowColor = Palette.black,
        })
    end
end

function GameplayState:draw()
    self:drawBackground()
    self:drawTopBar()

    if self.noPuzzles or not self.round then
        Localization.draw("NO_PUZZLES", 0, VH / 2 - 8, { width = VW, align = "center", color = Palette.text })
        Localization.draw("BACK", 0, VH / 2 + 8, { width = VW, align = "center", color = Palette.textDim })
        return
    end

    self.scene:draw()
    self.wordDisplay:draw()
    self:drawMessage()
    self.keyboard:draw()
    self:drawAttempts()
    for _, b in ipairs(self.buttons) do
        b:draw()
    end
    self.pauseButton:draw()
end

return GameplayState
