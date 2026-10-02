-- Pure-Lua tests for UI logic (focus navigation, RTL-aware widgets).
-- Run from the project root:  luajit tests/ui_tests.lua
package.path = "./?.lua;" .. package.path

local Input = require("src.core.input")
local Settings = require("src.core.settings")
local Localization = require("src.managers.localization_manager")
local UIManager = require("src.ui.ui_manager")
local Widget = require("src.ui.widget")
local Selector = require("src.ui.selector")
local Slider = require("src.ui.slider")
local Toggle = require("src.ui.toggle")
local Tabs = require("src.ui.tabs")
local TextInput = require("src.ui.text_input")
local Profile = require("src.managers.profile_manager")

local passed, failed = 0, 0
local function check(name, actual, expected)
    if actual == expected then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("FAIL %s\n  expected: %s\n  actual:   %s", name, tostring(expected), tostring(actual)))
    end
end

local A = Input.Actions
Localization.init()

-- Simple focusable box widget.
local Box = Widget.extend()
function Box.new(id, x, y, enabled)
    local self = setmetatable({}, Box)
    Widget.init(self, { x = x, y = y, w = 20, h = 10, enabled = enabled })
    self.id = id
    return self
end

-- Focus navigation ----------------------------------------------------------------------------------
-- Grid:   a b c
--         d e f      (e disabled)
--         g h i
local ui = UIManager.new()
local ids = { "a", "b", "c", "d", "e", "f", "g", "h", "i" }
local boxes = {}
for i, id in ipairs(ids) do
    local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
    boxes[id] = ui:add(Box.new(id, col * 40, row * 30, id ~= "e"))
end
ui:focusFirst()
check("focus first", ui:getFocused().id, "a")
ui:action(A.RIGHT); check("right a->b", ui:getFocused().id, "b")
ui:action(A.DOWN); check("down b skips disabled e -> h", ui:getFocused().id, "h")
ui:action(A.LEFT); check("left h->g", ui:getFocused().id, "g")
ui:action(A.UP); check("up g->d", ui:getFocused().id, "d")
ui:action(A.UP); ui:action(A.UP); check("up wraps a->g", ui:getFocused().id, "g")
ui:action(A.LEFT); check("left wraps g->i", ui:getFocused().id, "i")
check("disabled widget never focused", boxes.e.focused, false)

-- Selector: LEFT/RIGHT mirrored in RTL -----------------------------------------------------------------
local value = "normal"
local selector = Selector.new({ textKey = "DIFFICULTY",
    options = { { value = "easy" }, { value = "normal" }, { value = "hard" } },
    get = function() return value end, set = function(v) value = v end })

Settings.set("interfaceLanguage", "en")
selector:onAction(A.RIGHT); check("ltr right = next", value, "hard")
selector:onAction(A.RIGHT); check("ltr wraps to first", value, "easy")
selector:onAction(A.LEFT); check("ltr left = previous", value, "hard")

Settings.set("interfaceLanguage", "ar")
check("language switched to rtl", Localization.isRTL(), true)
value = "normal"
selector:onAction(A.LEFT); check("rtl left = next", value, "hard")
selector:onAction(A.RIGHT); check("rtl right = previous", value, "normal")

-- Slider ---------------------------------------------------------------------------------------------------
local volume = 0.5
local slider = Slider.new({ textKey = "MUSIC_VOLUME", get = function() return volume end,
    set = function(v) volume = v end })
slider:onAction(A.LEFT); check("rtl slider left increases", string.format("%.1f", volume), "0.6")
Settings.set("interfaceLanguage", "en")
slider:onAction(A.LEFT); slider:onAction(A.LEFT); check("ltr slider left decreases", string.format("%.1f", volume), "0.4")
for _ = 1, 20 do slider:onAction(A.RIGHT) end
check("slider clamps at 1", volume, 1)

-- Toggle -------------------------------------------------------------------------------------------------
local on = false
local toggle = Toggle.new({ textKey = "MUTE", get = function() return on end, set = function(v) on = v end })
toggle:onAction(A.CONFIRM); check("toggle confirm", on, true)
toggle:onAction(A.LEFT); check("toggle left", on, false)
toggle:setEnabled(false); toggle:toggle(); check("disabled toggle ignores", on, false)

-- Tabs ----------------------------------------------------------------------------------------------------
local changed
local tabs = Tabs.new({ x = 0, y = 0, w = 300, h = 20, tabs = { "GAMEPLAY", "AUDIO", "GRAPHICS" },
    onChange = function(i) changed = i end })
tabs:onAction(A.RIGHT); check("tabs ltr right", changed, 2)
Settings.set("interfaceLanguage", "ar")
tabs:onAction(A.RIGHT); check("tabs rtl right goes back", changed, 1)
local x1 = tabs:tabRect(1)
check("rtl first tab is on the right", x1, 200)

-- Text input ------------------------------------------------------------------------------------------
local typed = ""
local submitted = false
local field = TextInput.new({ x = 0, y = 0, w = 200, h = 24, maxLength = 5,
    get = function() return typed end, set = function(v) typed = v end,
    filter = Profile.filterTyping, onSubmit = function() submitted = true end })
field:onTextInput("ab"); field:onTextInput("c")
check("text typed", typed, "abc")
field:onTextInput("defgh")
check("text limited to max length", typed, "abcde")
field:onTextInput("z")
check("text full ignores more", typed, "abcde")
field:onKey("backspace")
check("backspace removes one", typed, "abcd")
typed = "عمر"
field:onKey("backspace")
check("backspace removes a whole arabic letter", typed, "عم")
field:onKey("backspace"); field:onKey("backspace"); field:onKey("backspace")
check("backspace on empty text", typed, "")
field:onTextInput(" ")
check("leading space filtered", typed, "")
field:onTextInput("a"); field:onTextInput(" ")
check("a space can be typed after a word", typed, "a ")
field:onTextInput(" "); field:onTextInput("b")
check("repeated spaces collapse", typed, "a b")
check("keys other than backspace not used", field:onKey("a"), false)
field:onAction(A.CONFIRM)
check("confirm submits", submitted, true)
field:setEnabled(false)
check("disabled field ignores text", field:onTextInput("x"), false)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
