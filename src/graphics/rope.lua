-- Rope: a small Verlet-integrated chain of points (used for the swinging
-- rope in the scene). The first point is pinned to an anchor; the last one
-- can be pinned to a moving target or left free.
--
--   local rope = Rope.new(anchorX, anchorY, 10, 6)   -- 10 segments of 6px
--   rope:update(dt)
--   rope:draw(color)

local Rope = {}
Rope.__index = Rope

local GRAVITY = 420         -- px/s²
local DAMPING = 0.985
local ITERATIONS = 8
local STEP = 1 / 120        -- fixed physics step for stable results

function Rope.new(ax, ay, segments, segmentLength)
    local self = setmetatable({}, Rope)
    self.anchorX, self.anchorY = ax, ay
    self.segmentLength = segmentLength
    self.points = {}
    for i = 0, segments do
        local y = ay + i * segmentLength
        self.points[i + 1] = { x = ax, y = y, px = ax, py = y }
    end
    self.accumulator = 0
    self.endPin = nil      -- { x, y } when the last point is held
    self.endMass = 1       -- >1 makes the last point resist the rope (a hanging weight)
    return self
end

function Rope:setSegmentLength(length)
    self.segmentLength = length
end

function Rope:getEnd()
    local p = self.points[#self.points]
    return p.x, p.y
end

-- Velocity of the last point (pixels per second).
function Rope:getEndVelocity()
    local p = self.points[#self.points]
    return (p.x - p.px) / STEP, (p.y - p.py) / STEP
end

function Rope:pinEnd(x, y)
    self.endPin = { x = x, y = y }
end

function Rope:releaseEnd()
    self.endPin = nil
end

-- Pushes every point (scaled towards the free end) by vx, vy px/s.
function Rope:impulse(vx, vy)
    local n = #self.points
    for i, p in ipairs(self.points) do
        local t = (i - 1) / (n - 1)
        p.px = p.px - vx * STEP * t
        p.py = p.py - (vy or 0) * STEP * t
    end
end

local function step(self)
    local pts = self.points
    for i = 2, #pts do
        local p = pts[i]
        local vx = (p.x - p.px) * DAMPING
        local vy = (p.y - p.py) * DAMPING
        p.px, p.py = p.x, p.y
        p.x = p.x + vx
        p.y = p.y + vy + GRAVITY * STEP * STEP
    end

    local first = pts[1]
    first.x, first.y, first.px, first.py = self.anchorX, self.anchorY, self.anchorX, self.anchorY

    for _ = 1, ITERATIONS do
        for i = 1, #pts - 1 do
            local a, b = pts[i], pts[i + 1]
            local dx, dy = b.x - a.x, b.y - a.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                local diff = (dist - self.segmentLength) / dist
                -- The anchor never moves; a heavy end moves less.
                local wa = (i == 1) and 0 or 1
                local wb = (i + 1 == #pts) and (1 / self.endMass) or 1
                local total = wa + wb
                if total > 0 then
                    a.x = a.x + dx * diff * (wa / total)
                    a.y = a.y + dy * diff * (wa / total)
                    b.x = b.x - dx * diff * (wb / total)
                    b.y = b.y - dy * diff * (wb / total)
                end
            end
        end
        if self.endPin then
            local last = pts[#pts]
            last.x, last.y = self.endPin.x, self.endPin.y
        end
        first.x, first.y = self.anchorX, self.anchorY
    end
end

function Rope:update(dt)
    self.accumulator = math.min(self.accumulator + dt, 0.1)
    while self.accumulator >= STEP do
        step(self)
        self.accumulator = self.accumulator - STEP
    end
end

-- Draws the rope as a 2px pixel line with a dark outline.
function Rope:draw(color, outline)
    local floor = math.floor
    local pts = self.points
    local function segment(a, b, ox, oy)
        local x1, y1 = floor(a.x) + ox, floor(a.y) + oy
        local x2, y2 = floor(b.x) + ox, floor(b.y) + oy
        local steps = math.max(math.abs(x2 - x1), math.abs(y2 - y1), 1)
        for s = 0, steps do
            local t = s / steps
            love.graphics.rectangle("fill", floor(x1 + (x2 - x1) * t + 0.5), floor(y1 + (y2 - y1) * t + 0.5), 2, 2)
        end
    end
    love.graphics.setColor(outline)
    for i = 1, #pts - 1 do
        segment(pts[i], pts[i + 1], -1, 0)
        segment(pts[i], pts[i + 1], 1, 0)
    end
    love.graphics.setColor(color)
    for i = 1, #pts - 1 do
        segment(pts[i], pts[i + 1], 0, 0)
    end
end

return Rope
