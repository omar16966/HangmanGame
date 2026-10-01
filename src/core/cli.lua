-- Command-line options for development and automated testing.
-- Ignored unless Config.debug is true.
--
--   love . --size 1920x1080            start with this window size
--   love . --fullscreen                start in fullscreen
--   love . --state diagnostics         first state after boot
--   love . --screenshot shot.png       save a screenshot (into the save folder)
--          --screenshot-after 1.5      ...after this many seconds (default 1)
--   love . --quit-after 2              quit automatically
--   love . --overlay                   show the debug overlay
--   love . --fresh                     ignore the existing save (testing)

local Cli = {}

function Cli.parse(args)
    local options = {}
    local i = 1
    while args and i <= #args do
        local a = args[i]
        if a == "--size" and args[i + 1] then
            local w, h = args[i + 1]:match("^(%d+)x(%d+)$")
            if w then
                options.width, options.height = tonumber(w), tonumber(h)
            end
            i = i + 1
        elseif a == "--fullscreen" then
            options.fullscreen = true
        elseif a == "--state" and args[i + 1] then
            options.state = args[i + 1]
            i = i + 1
        elseif a == "--screenshot" and args[i + 1] then
            options.screenshot = args[i + 1]
            i = i + 1
        elseif a == "--screenshot-after" and args[i + 1] then
            options.screenshotAfter = tonumber(args[i + 1])
            i = i + 1
        elseif a == "--quit-after" and args[i + 1] then
            options.quitAfter = tonumber(args[i + 1])
            i = i + 1
        elseif a == "--overlay" then
            options.overlay = true
        elseif a == "--fresh" then
            options.fresh = true
        end
        i = i + 1
    end
    return options
end

return Cli
