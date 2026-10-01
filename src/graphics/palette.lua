-- Central color palette. Every color used by the game comes from here, so
-- the whole visual style can be changed by editing this one file.
-- Theme: a warm wooden puzzle room at night.

local Utils = require("src.core.utils")

local hex = Utils.hexColor

local Palette = {
    -- Base
    black = hex("#0b0810"),
    white = hex("#fff8ec"),
    background = hex("#1a1423"),
    backgroundDeep = hex("#120d19"),

    -- Panels / UI
    panel = hex("#2b2238"),
    panelLight = hex("#3d3150"),
    panelBorder = hex("#0f0b14"),
    panelHighlight = hex("#57476e"),
    shadow = hex("#0b0810"),

    -- Accents
    primary = hex("#f2a65a"),     -- warm amber
    primaryDark = hex("#b9703a"),
    secondary = hex("#5ec4b6"),   -- teal
    secondaryDark = hex("#3a8a80"),
    highlight = hex("#ffd86b"),

    -- Text
    text = hex("#f4e9d8"),
    textDim = hex("#a89cb0"),
    textDark = hex("#2b2238"),

    -- Feedback (never used alone: always paired with an icon/shape/animation)
    correct = hex("#7bd66f"),
    correctDark = hex("#3f8f45"),
    incorrect = hex("#e8615a"),
    incorrectDark = hex("#9c3540"),

    -- Scene
    wood = hex("#8a5a3b"),
    woodDark = hex("#5c3a26"),
    woodLight = hex("#b07a4f"),
    rope = hex("#c9a66b"),
    candle = hex("#ffcf70"),

    -- Placeholder art for missing image assets
    placeholder = hex("#ff00ff"),
    placeholderDark = hex("#7a007a"),
}

-- Returns a copy of a palette color with a different alpha.
function Palette.withAlpha(color, alpha)
    return { color[1], color[2], color[3], alpha }
end

return Palette
