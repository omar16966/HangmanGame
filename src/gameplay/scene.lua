-- The puzzle scene: a wooden frame that is built one piece per mistake, a
-- swinging rope, and the character. Kept non-graphic: on a lost round the
-- rope is tied around the character's waist and lifts it up, cartoon style.
--
-- Stages (scaled to any number of attempts, see Scene.stageFor):
--   0 nothing   1 base plank   2 post   3 top beam   4 brace
--   5 rope      6 round lost (rope lowers, ties the belt and lifts)
--
-- All coordinates are relative to a 160x144 frame (the size of one frame of
-- assets/sprites/hangman_stages.png).

local Assets = require("src.managers.asset_manager")
local Placeholders = require("src.graphics.placeholders")
local Palette = require("src.graphics.palette")
local Renderer = require("src.graphics.renderer")
local Rope = require("src.graphics.rope")
local Character = require("src.gameplay.character")

local Scene = {}
Scene.__index = Scene

Scene.WIDTH, Scene.HEIGHT = 160, 144
Scene.MAX_STAGE = 6

-- Layout inside the frame (shared with the sprite art, see ASSETS.md).
local GROUND_Y = 136
local ROPE_ANCHOR_X, ROPE_ANCHOR_Y = 112, 21
local CHARACTER_X = 112
local ROPE_SEGMENTS, ROPE_SEGMENT = 9, 6
local PIECE_DROP_TIME = 0.25

-- Placeholder pieces: stage -> draw function.
local PIECES = {
    [1] = function() Placeholders.drawPlank(14, 129, 60, 7) end,
    [2] = function() Placeholders.drawPlank(36, 16, 10, 113) end,
    [3] = function() Placeholders.drawPlank(30, 12, 96, 8) end,
    [4] = function() Placeholders.drawBrace(46, 46, 70, 20, 4) end,
}

-- Maps wrong guesses to a stage so every difficulty uses all stages:
-- the last attempt always reaches stage 6 (lost) and stage 5 is the final warning.
function Scene.stageFor(wrong, maxWrong)
    if wrong >= maxWrong then
        return Scene.MAX_STAGE
    end
    if wrong <= 0 then
        return 0
    end
    return math.min(Scene.MAX_STAGE - 1, math.ceil(wrong * (Scene.MAX_STAGE - 1) / math.max(1, maxWrong - 1)))
end

function Scene.new(x, y)
    local self = setmetatable({}, Scene)
    self.x, self.y = x, y
    self:reset()
    return self
end

function Scene:reset()
    self.stage = 0
    self.pieceTimers = {}
    self.rope = nil
    self.lossPhase = nil
    self.lossTimer = 0
    self.character = Character.new(CHARACTER_X, GROUND_Y)
end

-- Converts virtual-screen coordinates to frame coordinates.
function Scene:toLocal(x, y)
    return x - self.x, y - self.y
end

function Scene:setLookTarget(x, y)
    if x then
        self.character:setLookTarget(self:toLocal(x, y))
    else
        self.character:setLookTarget(nil, nil)
    end
end

local function moodForStage(stage)
    if stage >= 5 then return "worried" end
    if stage >= 3 then return "worried" end
    return "calm"
end

local function createRope(self)
    self.rope = Rope.new(ROPE_ANCHOR_X, ROPE_ANCHOR_Y, ROPE_SEGMENTS, ROPE_SEGMENT)
    self.rope:impulse(40, 0)
end

-- Jumps straight to a stage without animation (used when restoring a round).
function Scene:setStage(stage)
    self.stage = stage
    for s = 1, math.min(stage, 4) do
        self.pieceTimers[s] = PIECE_DROP_TIME
    end
    if stage >= 5 and not self.rope then
        createRope(self)
    end
    self.character:setBaseMood(moodForStage(stage))
end

-- Events from the gameplay -------------------------------------------------------------------------

function Scene:onCorrect()
    self.character:onCorrect()
end

function Scene:onWrong(stage)
    local previous = self.stage
    self.stage = stage
    for s = previous + 1, math.min(stage, 4) do
        self.pieceTimers[s] = 0
    end
    if stage >= 5 and not self.rope then
        createRope(self)
    elseif self.rope then
        self.rope:impulse(love.math.random() < 0.5 and -70 or 70, 0)
    end
    self.character:setBaseMood(moodForStage(stage))
    self.character:onWrong(stage >= 3)
    Renderer.shake(1, 0.2)
    if stage >= Scene.MAX_STAGE then
        self:startLoss()
    end
end

function Scene:onWin()
    self.character:celebrate()
    if self.rope then
        self.rope:impulse(90, -40)
    end
end

function Scene:startLoss()
    if not self.rope then
        createRope(self)
    end
    self.lossPhase = "lower"
    self.lossTimer = 0
    self.character:setBaseMood("scared")
end

-- Loss sequence: lower the rope to the waist, tie it, then lift.
local LOWER_TIME, TIE_TIME, LIFT_TIME = 0.7, 0.35, 1.1

local function updateLoss(self, dt)
    local rope = self.rope
    self.lossTimer = self.lossTimer + dt
    if self.lossPhase == "lower" then
        local wx, wy = self.character:getWaist()
        local t = math.min(1, self.lossTimer / LOWER_TIME)
        local fullLength = (wy - ROPE_ANCHOR_Y) / ROPE_SEGMENTS
        rope:setSegmentLength(ROPE_SEGMENT + (fullLength - ROPE_SEGMENT) * t)
        local ex, ey = rope:getEnd()
        rope:pinEnd(ex + (wx - ex) * t, ey + (wy - ey) * t)
        if t >= 1 then
            self.lossPhase, self.lossTimer = "tie", 0
            self.character:tieBelt()
        end
    elseif self.lossPhase == "tie" then
        rope:pinEnd(self.character:getWaist())
        if self.lossTimer >= TIE_TIME then
            self.lossPhase, self.lossTimer = "lift", 0
            self.liftStart = rope.segmentLength
            rope:releaseEnd()
            rope.endMass = 6
            self.character:hangFrom(rope)
            rope:impulse(50, 0)
        end
    elseif self.lossPhase == "lift" then
        local t = math.min(1, self.lossTimer / LIFT_TIME)
        local eased = 1 - (1 - t) * (1 - t)
        rope:setSegmentLength(self.liftStart + (8 - self.liftStart) * eased)
        if t >= 1 then
            self.lossPhase = "hanging"
        end
    end
end

function Scene:update(dt)
    for s, t in pairs(self.pieceTimers) do
        if t < PIECE_DROP_TIME then
            self.pieceTimers[s] = math.min(PIECE_DROP_TIME, t + dt)
        end
    end
    if self.lossPhase then
        updateLoss(self, dt)
    end
    if self.rope then
        self.rope:update(dt)
    end
    self.character:update(dt)
end

-- Drawing --------------------------------------------------------------------------------------------

local function drawRopeLoop(rope)
    local ex, ey = rope:getEnd()
    ex, ey = math.floor(ex), math.floor(ey)
    love.graphics.setColor(Palette.black)
    love.graphics.circle("line", ex + 0.5, ey + 4.5, 5, 16)
    love.graphics.circle("line", ex + 0.5, ey + 4.5, 3, 12)
    love.graphics.setColor(Palette.rope)
    love.graphics.circle("line", ex + 0.5, ey + 4.5, 4, 14)
end

function Scene:drawStructure()
    local frames = Assets.images.hangmanStages
    if frames then
        -- Sprite art: one 160x144 frame per stage.
        if not self.stageQuads then
            local iw, ih = frames:getDimensions()
            self.stageQuads = {}
            for s = 0, Scene.MAX_STAGE do
                self.stageQuads[s] = love.graphics.newQuad(s * Scene.WIDTH, 0, Scene.WIDTH, Scene.HEIGHT, iw, ih)
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(frames, self.stageQuads[self.stage], 0, 0)
        return
    end

    -- Placeholder pieces drop into place when they appear.
    for s = 1, 4 do
        local t = self.pieceTimers[s]
        if t then
            local k = t / PIECE_DROP_TIME
            local offset = math.floor(-8 * (1 - k) * (1 - k))
            love.graphics.push()
            love.graphics.translate(0, offset)
            PIECES[s]()
            love.graphics.pop()
        end
    end
end

function Scene:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)

    -- Ground shadow under the character.
    local cx = math.floor(self.character:getBodyCenter())
    love.graphics.setColor(Palette.withAlpha(Palette.black, 0.5))
    love.graphics.ellipse("fill", cx, GROUND_Y + 1, 12, 2, 16)

    self:drawStructure()

    if self.rope then
        self.rope:draw(Palette.rope, Palette.black)
        if not self.lossPhase then
            drawRopeLoop(self.rope)
        end
    end

    self.character:draw()

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

return Scene
