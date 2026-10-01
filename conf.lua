-- LÖVE configuration (runs before main.lua).

local Config = require("src.core.config")

function love.conf(t)
    t.identity = Config.app.identity
    t.version = "11.5"
    t.console = false

    t.window.title = Config.app.name
    t.window.width = Config.window.width
    t.window.height = Config.window.height
    t.window.minwidth = Config.window.minWidth
    t.window.minheight = Config.window.minHeight
    t.window.resizable = Config.window.resizable
    t.window.fullscreen = false -- applied after the save is loaded
    t.window.fullscreentype = Config.window.fullscreenType
    t.window.vsync = Config.window.vsync
    t.window.highdpi = false

    -- Modules this game does not use.
    t.modules.joystick = true -- kept for future gamepad support
    t.modules.physics = false
    t.modules.video = false
    t.modules.touch = false
end
