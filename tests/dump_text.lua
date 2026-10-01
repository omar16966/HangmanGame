-- Helper for tests/compare_reference.py: reads lines "MODE<TAB>DIR<TAB>text"
-- from stdin and prints the resulting codepoints (hex, space separated).
--   MODE shape -> Arabic shaping only (logical order)
--   MODE bidi  -> bidi reordering only (no shaping)
package.path = "./?.lua;" .. package.path
local Utf8 = require("src.localization.utf8_util")
local Shaper = require("src.localization.arabic_shaper")
local Bidi = require("src.localization.bidi")

for line in io.lines() do
    local mode, dir, text = line:match("^(%w+)\t(%w+)\t(.*)$")
    local cps = Utf8.decode(text)
    local out
    if mode == "shape" then
        out = Shaper.shape(cps, { stripMarks = true })
    else
        out = Bidi.toVisual(cps, dir)
    end
    local hex = {}
    for i, cp in ipairs(out) do hex[i] = string.format("%04X", cp) end
    print(table.concat(hex, " "))
end
