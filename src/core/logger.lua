-- Simple leveled logger.
--   Logger.info("Loaded 240 Arabic puzzles")
--   Logger.warning("Missing sound: ui_hover")
--   Logger.warningOnce("sfx:ui_hover", "Missing sound: ui_hover")   -- printed only once

local Logger = {}

local LEVELS = { DEBUG = 1, INFO = 2, WARNING = 3, ERROR = 4 }

local minLevel = LEVELS.DEBUG
local historySize = 200
local history = {}
local onceKeys = {}
local counts = { DEBUG = 0, INFO = 0, WARNING = 0, ERROR = 0 }

function Logger.configure(options)
    options = options or {}
    if options.level and LEVELS[options.level] then
        minLevel = LEVELS[options.level]
    end
    historySize = options.historySize or historySize
end

local function clock()
    if love and love.timer then
        return love.timer.getTime()
    end
    return os.clock()
end

local function write(level, message, ...)
    if select("#", ...) > 0 then
        message = string.format(message, ...)
    end
    message = tostring(message)
    counts[level] = counts[level] + 1

    local line = string.format("[%8.3f] %-7s %s", clock(), level, message)
    history[#history + 1] = { level = level, text = line }
    if #history > historySize then
        table.remove(history, 1)
    end

    if LEVELS[level] >= minLevel then
        print(line)
    end
end

function Logger.debug(message, ...) write("DEBUG", message, ...) end
function Logger.info(message, ...) write("INFO", message, ...) end
function Logger.warning(message, ...) write("WARNING", message, ...) end
function Logger.error(message, ...) write("ERROR", message, ...) end

-- Logs a warning only the first time `key` is seen. Use for anything that
-- could otherwise repeat every frame (missing asset, unknown key, ...).
function Logger.warningOnce(key, message, ...)
    if onceKeys[key] then
        return
    end
    onceKeys[key] = true
    write("WARNING", message, ...)
end

function Logger.getHistory()
    return history
end

function Logger.getCounts()
    return counts
end

return Logger
