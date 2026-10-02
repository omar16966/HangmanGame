-- The puzzle character: a small round creature with a leaf on its head,
-- animated with simple spring physics.
--
--   idle      gentle breathing (squash spring), blinking, looks at the cursor
--   correct   a happy hop
--   wrong     a startled jump with a sideways wobble (+ sweat when worried)
--   win       repeated happy hops
--   loss      lifted by the rope tied around its waist, dangling and swinging
--
-- Physics state lives here; drawing uses assets/sprites/character*.png when
-- present (see ASSETS.md), otherwise the placeholder in placeholders.lua.

local Assets = require("src.managers.asset_manager")
local Placeholders = require("src.graphics.placeholders")

local Character = {}
Character.__index = Character

local BODY_RX, BODY_RY = 14, 12
local FOOT_H = 3
local GRAVITY = 700
local SQUASH_K, SQUASH_C = 220, 12
local SWAY_K, SWAY_C = 160, 9
local LEAF_K, LEAF_C = 90, 5
local LEAF_LENGTH = 8

function Character.new(x, groundY)
    local self = setmetatable({}, Character)
    self.x, self.groundY = x, groundY
    self.h, self.vh = 0, 0              -- height above the ground and vertical speed
    self.squash, self.squashV = 0, 0    -- >0 flattened, <0 stretched
    self.sway, self.swayV = 0, 0        -- sideways offset (wobble)
    self.leaf, self.leafV = 0, 0        -- leaf angle (radians)
    self.time = 0
    self.baseMood = "calm"
    self.mood = "calm"
    self.moodTimer = 0
    self.blinkTimer = 2
    self.blink = false
    self.sweatTimer = 0
    self.lookX, self.lookY = 0, 0
    self.targetX, self.targetY = nil, nil
    self.celebrating = false
    self.celebrateTimer = 0
    self.hanging = nil                  -- rope while lifted by it
    self.belt = false
    self.feetLag, self.feetLagV = 0, 0
    return self
end

-- Mood used when no reaction is playing (set by the scene from the stage).
function Character:setBaseMood(mood)
    self.baseMood = mood
end

function Character:react(mood, duration)
    self.mood = mood
    self.moodTimer = duration
end

function Character:setLookTarget(x, y)
    self.targetX, self.targetY = x, y
end

function Character:jump(speed)
    if self.hanging then
        return
    end
    self.vh = speed
    self.squashV = self.squashV - 6 -- push off: stretch
end

function Character:onCorrect()
    self:jump(120)
    self:react("happy", 0.8)
end

function Character:onWrong(worried)
    self:jump(160)
    self.swayV = self.swayV + (love.math.random() < 0.5 and -1 or 1) * 90
    self:react("scared", 1.0)
    if worried then
        self.sweatTimer = 1.2
    end
end

function Character:celebrate()
    self.celebrating = true
    self.celebrateTimer = 0
    self.baseMood = "happy"
    self:react("happy", 999)
end

-- Ties the character to the rope (belt) without lifting it yet.
function Character:tieBelt()
    self.belt = true
    self.baseMood = "sad"
    self:react("scared", 0.6)
end

-- From now on the character follows the rope end.
function Character:hangFrom(rope)
    self.hanging = rope
    self.belt = true
    self.baseMood = "sad"
    self.h, self.vh = 0, 0
end

-- Position where the rope should attach (the waist).
function Character:getWaist()
    local bodyY = self.groundY - FOOT_H - BODY_RY - self.h
    return self.x + self.sway, bodyY + 3
end

function Character:getHeadTop()
    local bodyY = self.groundY - FOOT_H - BODY_RY - self.h
    return self.x, bodyY - BODY_RY
end

-- Physics ------------------------------------------------------------------------------------------

function Character:update(dt)
    self.time = self.time + dt

    -- Mood reactions wear off.
    if self.moodTimer > 0 then
        self.moodTimer = self.moodTimer - dt
        if self.moodTimer <= 0 then
            self.mood = self.baseMood
        end
    else
        self.mood = self.baseMood
    end

    -- Blinking.
    self.blinkTimer = self.blinkTimer - dt
    if self.blinkTimer <= 0 then
        if self.blink then
            self.blink = false
            self.blinkTimer = 1.5 + love.math.random() * 3
        else
            self.blink = true
            self.blinkTimer = 0.12
        end
    end

    if self.sweatTimer > 0 then
        self.sweatTimer = self.sweatTimer - dt
    end

    local prevSwayV = self.swayV
    if self.hanging then
        -- Follow the rope; the feet lag behind the swing.
        local ex, ey = self.hanging:getEnd()
        local vx = self.hanging:getEndVelocity()
        self.hangX, self.hangY = ex, ey
        local fa = -SWAY_K * (self.feetLag + vx * 0.03) - SWAY_C * self.feetLagV
        self.feetLagV = self.feetLagV + fa * dt
        self.feetLag = self.feetLag + self.feetLagV * dt
        self.squash = self.squash + (math.sin(self.time * 1.7) * 0.15 - self.squash) * dt * 4
    else
        -- Celebrate: keep hopping.
        if self.celebrating then
            self.celebrateTimer = self.celebrateTimer - dt
            if self.celebrateTimer <= 0 and self.h <= 0 then
                self:jump(150)
                self.celebrateTimer = 0.25
            end
        end

        -- Jumping and landing.
        if self.h > 0 or self.vh > 0 then
            self.vh = self.vh - GRAVITY * dt
            self.h = self.h + self.vh * dt
            if self.h <= 0 then
                self.h = 0
                self.squashV = self.squashV + math.min(12, -self.vh * 0.06) -- landing squash
                self.vh = 0
            end
        end

        -- Squash & stretch spring around a breathing target.
        local breathe = math.sin(self.time * 2.4) * 0.18
        local stretch = math.min(0.6, math.abs(self.vh) / 300)
        local target = breathe - stretch
        local a = -SQUASH_K * (self.squash - target) - SQUASH_C * self.squashV
        self.squashV = self.squashV + a * dt
        self.squash = self.squash + self.squashV * dt

        -- Sideways wobble.
        local sa = -SWAY_K * self.sway - SWAY_C * self.swayV
        self.swayV = self.swayV + sa * dt
        self.sway = self.sway + self.swayV * dt
    end
    self.squash = math.max(-0.8, math.min(0.8, self.squash))

    -- The leaf reacts to the body's movement.
    local accelX = (self.swayV - prevSwayV) / math.max(dt, 1e-4)
    local la = -LEAF_K * self.leaf - LEAF_C * self.leafV - accelX * 0.0006 + self.squashV * 0.05
    if self.hanging then
        la = la - self.feetLagV * 0.02
    end
    self.leafV = self.leafV + la * dt
    self.leaf = math.max(-0.9, math.min(0.9, self.leaf + self.leafV * dt))

    -- Eyes follow the target.
    local bx, by = self:getBodyCenter()
    local tx, ty = self.targetX, self.targetY
    local lx, ly = 0, 0
    if tx then
        local dx, dy = tx - bx, ty - by
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 1 then
            lx, ly = dx / len * 1.5, dy / len * 1.5
        end
    end
    self.lookX = self.lookX + (lx - self.lookX) * math.min(1, dt * 10)
    self.lookY = self.lookY + (ly - self.lookY) * math.min(1, dt * 10)
end

function Character:getRadii()
    local s = math.floor(self.squash * 4 + 0.5)
    return BODY_RX + s, BODY_RY - s
end

function Character:getBodyCenter()
    local rx, ry = self:getRadii()
    if self.hanging and self.hangX then
        return self.hangX, self.hangY - 3
    end
    return self.x + self.sway, self.groundY - FOOT_H - ry - self.h
end

-- Drawing -------------------------------------------------------------------------------------------

function Character:getPose()
    local rx, ry = self:getRadii()
    local x, y = self:getBodyCenter()
    local feet
    if self.hanging then
        local lag = self.feetLag
        feet = { { x - 6 + lag, y + ry + 3 }, { x + 6 + lag * 1.3, y + ry + 4 } }
    else
        local fy = y + ry + 1
        feet = { { self.x - 7 + self.sway * 0.3, fy }, { self.x + 7 + self.sway * 0.3, fy } }
    end
    local stemX, stemY = x, y - ry
    local leaf = {
        stemX, stemY,
        stemX + math.sin(self.leaf) * LEAF_LENGTH, stemY - math.cos(self.leaf) * LEAF_LENGTH,
    }
    local sweat = nil
    if self.sweatTimer > 0 then
        local t = 1.2 - self.sweatTimer
        sweat = { x + rx - 2, y - ry + 2 + t * 10 }
    end
    return {
        x = x, y = y, rx = rx, ry = ry,
        mood = self.mood, blink = self.blink,
        lookX = self.lookX, lookY = self.lookY,
        feet = feet, leaf = leaf, sweat = sweat, belt = self.belt,
    }
end

function Character:draw()
    local pose = self:getPose()
    if Assets.images.character then
        -- Sprite version (see ASSETS.md): body frame chosen by mood/squash,
        -- positioned by the same physics.
        self:drawSprite(pose)
    else
        Placeholders.drawCharacter(pose)
    end
end

-- Sprite sheet layout (assets/sprites/character.png, frames of 32x32):
-- calm, blink, happy, worried, scared, sad, squash, stretch, foot, leaf.
local FRAME = 32
local FRAMES = { calm = 1, blink = 2, happy = 3, worried = 4, scared = 5, sad = 6, squash = 7, stretch = 8, foot = 9, leaf = 10 }
local quads

function Character:drawSprite(pose)
    local image = Assets.images.character
    if not quads then
        quads = {}
        local iw, ih = image:getDimensions()
        for name, index in pairs(FRAMES) do
            quads[name] = love.graphics.newQuad((index - 1) * FRAME, 0, FRAME, FRAME, iw, ih)
        end
    end
    local floor = math.floor
    love.graphics.setColor(1, 1, 1, 1)
    for _, f in ipairs(pose.feet) do
        love.graphics.draw(image, quads.foot, floor(f[1]) - FRAME / 2, floor(f[2]) - FRAME / 2)
    end
    -- The leaf frame has its stem base at the frame center; it slides sideways
    -- with the sway instead of rotating (keeps the pixel art intact).
    local leafX = pose.leaf[1] + (pose.leaf[3] - pose.leaf[1])
    love.graphics.draw(image, quads.leaf, floor(leafX) - FRAME / 2, floor(pose.leaf[2]) - FRAME / 2)
    local frame = pose.mood
    if pose.blink and (frame == "calm" or frame == "worried") then
        frame = "blink"
    end
    if self.squash > 0.45 then
        frame = "squash"
    elseif self.squash < -0.45 then
        frame = "stretch"
    end
    love.graphics.draw(image, quads[frame] or quads.calm, floor(pose.x) - FRAME / 2, floor(pose.y) - FRAME / 2)
    if pose.belt then
        Placeholders.drawBelt(pose)
    end
    if pose.sweat then
        Placeholders.drawSweat(pose.sweat[1], pose.sweat[2])
    end
end

return Character
