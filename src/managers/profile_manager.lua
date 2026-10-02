-- Player profile: a simple local profile (no account). The name is shown on
-- the statistics screen and stored with every high score.
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Config = require("src.core.config")
local Utf8 = require("src.localization.utf8_util")

local Profile = {}

local data = { name = "", createdAt = 0 }

-- Characters that never belong in a name: controls, zero-width and bidi
-- override characters (which could scramble neighbouring text on screen).
local function isAllowed(cp)
    if cp < 0x20 or (cp >= 0x7F and cp <= 0x9F) then return false end
    if cp >= 0x200B and cp <= 0x200F then return false end
    if cp >= 0x2028 and cp <= 0x202E then return false end
    if cp >= 0x2060 and cp <= 0x206F then return false end
    if cp == 0xFEFF or cp == 0xFFFD then return false end
    if cp >= 0xE000 and cp <= 0xF8FF then return false end
    return true
end

-- Removes unwanted characters, drops leading spaces and collapses repeated
-- ones, limits the length. A single trailing space is kept: this is what
-- the text field uses while the player is still typing.
function Profile.filterTyping(text)
    local out = {}
    local lastWasSpace = true -- also drops leading spaces
    for _, cp in ipairs(Utf8.decode(tostring(text or ""))) do
        if isAllowed(cp) then
            if cp == 0x20 then
                if not lastWasSpace then out[#out + 1] = cp end
                lastWasSpace = true
            else
                out[#out + 1] = cp
                lastWasSpace = false
            end
        end
    end
    local limit = Config.save.nameMaxLength
    while #out > limit do
        out[#out] = nil
    end
    return Utf8.encode(out)
end

-- The final, stored form of a name: like filterTyping, and also trimmed.
-- Returns "" when nothing usable is left.
function Profile.sanitizeName(text)
    local cleaned = Profile.filterTyping(text)
    local cps = Utf8.decode(cleaned)
    while #cps > 0 and cps[#cps] == 0x20 do
        cps[#cps] = nil
    end
    return Utf8.encode(cps)
end

function Profile.nameLength(text)
    return #Utf8.decode(text or "")
end

-- The name as typed, or "" if the player never set one.
function Profile.getName()
    return data.name
end

function Profile.setName(name)
    data.name = Profile.sanitizeName(name)
end

-- The name to show: the player's name or a localized default.
function Profile.getDisplayName()
    if data.name ~= "" then
        return data.name
    end
    local ok, text = pcall(function()
        return require("src.managers.localization_manager").get("DEFAULT_PLAYER_NAME")
    end)
    return ok and text or "Player"
end

function Profile.getCreatedAt()
    return data.createdAt
end

-- Save sections ---------------------------------------------------------------------------------

function Profile.reset()
    data = { name = "", createdAt = os.time() }
end

function Profile.load(saved)
    Profile.reset()
    if type(saved) ~= "table" then
        return
    end
    if type(saved.name) == "string" then
        data.name = Profile.sanitizeName(saved.name)
    end
    if type(saved.createdAt) == "number" and saved.createdAt > 0 and saved.createdAt == saved.createdAt then
        data.createdAt = saved.createdAt
    end
end

function Profile.export()
    return { name = data.name, createdAt = data.createdAt }
end

return Profile
