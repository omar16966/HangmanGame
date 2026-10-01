-- 9-slice drawing: draws a frame image at any size by keeping the corners
-- unscaled and stretching only the edges and the middle, so pixel-art
-- borders stay crisp.
--
--   local slice = NineSlice.new(image, 16, 16, 4)   -- frames of 16x16, 4px corners
--   slice:draw(frameIndex, x, y, w, h)
--
-- Frames are laid out left to right in the image.

local NineSlice = {}
NineSlice.__index = NineSlice

function NineSlice.new(image, frameW, frameH, corner)
    local self = setmetatable({}, NineSlice)
    self.image = image
    self.frameW, self.frameH = frameW, frameH
    self.corner = corner
    self.frameCount = math.max(1, math.floor(image:getWidth() / frameW))
    self.frames = {}
    local iw, ih = image:getDimensions()
    local c = corner
    local mw, mh = frameW - 2 * c, frameH - 2 * c
    for f = 1, self.frameCount do
        local ox = (f - 1) * frameW
        local q = function(x, y, w, h)
            return love.graphics.newQuad(ox + x, y, w, h, iw, ih)
        end
        self.frames[f] = {
            q(0, 0, c, c), q(c, 0, mw, c), q(c + mw, 0, c, c),
            q(0, c, c, mh), q(c, c, mw, mh), q(c + mw, c, c, mh),
            q(0, c + mh, c, c), q(c, c + mh, mw, c), q(c + mw, c + mh, c, c),
        }
    end
    return self
end

function NineSlice:draw(frameIndex, x, y, w, h)
    local quads = self.frames[math.min(frameIndex, self.frameCount)]
    local c = self.corner
    local mw, mh = self.frameW - 2 * c, self.frameH - 2 * c
    local innerW, innerH = math.max(0, w - 2 * c), math.max(0, h - 2 * c)
    local sx, sy = innerW / mw, innerH / mh
    local img = self.image
    x, y = math.floor(x), math.floor(y)

    love.graphics.draw(img, quads[1], x, y)
    love.graphics.draw(img, quads[2], x + c, y, 0, sx, 1)
    love.graphics.draw(img, quads[3], x + c + innerW, y)
    love.graphics.draw(img, quads[4], x, y + c, 0, 1, sy)
    love.graphics.draw(img, quads[5], x + c, y + c, 0, sx, sy)
    love.graphics.draw(img, quads[6], x + c + innerW, y + c, 0, 1, sy)
    love.graphics.draw(img, quads[7], x, y + c + innerH)
    love.graphics.draw(img, quads[8], x + c, y + c + innerH, 0, sx, 1)
    love.graphics.draw(img, quads[9], x + c + innerW, y + c + innerH)
end

return NineSlice
