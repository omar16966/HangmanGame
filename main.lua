-- Entry point. Kept minimal: every callback is delegated to the Game module.

local Game = require("src.core.game")

function love.load(args)
    Game.load(args)
end

function love.update(dt)
    Game.update(dt)
end

function love.draw()
    Game.draw()
end

function love.keypressed(key, scancode, isRepeat)
    Game.keypressed(key, scancode, isRepeat)
end

function love.keyreleased(key, scancode)
    Game.keyreleased(key, scancode)
end

function love.textinput(text)
    Game.textinput(text)
end

function love.mousepressed(x, y, button)
    Game.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    Game.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    Game.mousemoved(x, y, dx, dy)
end

function love.wheelmoved(dx, dy)
    Game.wheelmoved(dx, dy)
end

function love.resize(w, h)
    Game.resize(w, h)
end

function love.quit()
    return Game.quit()
end
