-- Pure-Lua unit tests for modules that do not need LÖVE.
-- Run from the project root:  luajit tests/unit_tests.lua
package.path = "./?.lua;" .. package.path

local Utf8 = require("src.localization.utf8_util")
local Shaper = require("src.localization.arabic_shaper")
local Bidi = require("src.localization.bidi")

local passed, failed = 0, 0

local function hex(cps)
    local t = {}
    for i, cp in ipairs(cps) do t[i] = string.format("%04X", cp) end
    return table.concat(t, " ")
end

local function check(name, actual, expected)
    if actual == expected then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("FAIL %s\n  expected: %s\n  actual:   %s", name, tostring(expected), tostring(actual)))
    end
end

local function shape(s, opts)
    return hex(Shaper.shape(Utf8.decode(s), opts or { stripMarks = true }))
end

local function visual(s, dir)
    return Utf8.encode((Bidi.toVisual(Utf8.decode(s), dir)))
end

-- UTF-8 ----------------------------------------------------------------------------------
check("utf8 roundtrip arabic", Utf8.encode(Utf8.decode("برمجة")), "برمجة")
check("utf8 roundtrip mixed", Utf8.encode(Utf8.decode("Aé€😀ب")), "Aé€😀ب")
check("utf8 length", Utf8.len("سلام"), 4)
check("utf8 empty", #Utf8.decode(""), 0)
check("utf8 invalid byte", Utf8.decode("a\255b")[2], 0xFFFD)
check("utf8 truncated", Utf8.decode("\216")[1], 0xFFFD)

-- Shaping ----------------------------------------------------------------------------------
-- ب initial, ر final (right-joining), م isolated (base), ج initial, ة final
check("shape برمجة", shape("برمجة"), "FE91 FEAE FEE3 FEA0 FE94")
check("shape lam-alef isolated", shape("لا"), "FEFB")
check("shape lam-alef final", shape("سلا"), "FEB3 FEFC")
check("shape lam-alef hamza", shape("لأن"), "FEF7 0646")
check("shape non-joining hamza", shape("شيء"), "FEB7 FEF2 0621")
check("shape single letter isolated", shape("ب"), "0628")
check("shape strips marks", shape("بَ"), "0628")
check("shape keeps marks when asked", shape("بَب", {}), "FE91 064E FE90")
check("shape marks are transparent", shape("بَب", {}), "FE91 064E FE90")
check("shape latin untouched", shape("abc"), "0061 0062 0063")
check("shape tatweel joins", shape("ـبـ"), "0640 FE92 0640")
check("shape space breaks joining", shape("ب ب"), "0628 0020 0628")

-- Glyph fallback: a font missing a form gets the plain letter instead.
local noMedial = function(cp) return cp ~= 0xFE92 end
check("shape missing glyph fallback", shape("ببب", { hasGlyph = noMedial }), "FE91 0628 FE90")
local noLigature = function(cp) return cp < 0xFEF5 end
check("shape missing ligature fallback", shape("لا", { hasGlyph = noLigature }), "FEDF FE8E")

-- Bidi -----------------------------------------------------------------------------------------
check("detect rtl", Bidi.detectDirection(Utf8.decode("123 مرحبا")), "rtl")
check("detect ltr", Bidi.detectDirection(Utf8.decode("(Hello) مرحبا")), "ltr")
check("detect none", Bidi.detectDirection(Utf8.decode("123 !")), nil)
check("bidi pure arabic reversed", visual("سلام", "rtl"), "مالس")
check("bidi latin in rtl stays ltr", visual("كلمة word", "rtl"), "word ةملك")
check("bidi numbers stay ltr", visual("عدد 123", "rtl"), "123 ددع")
check("bidi arabic-indic digits stay ltr", visual("عدد ١٢٣", "rtl"), "١٢٣ ددع")
check("bidi brackets mirrored", visual("(سلام)", "rtl"), "(مالس)")
check("bidi ltr paragraph untouched", visual("Hello world", "ltr"), "Hello world")
check("bidi arabic inside ltr", visual("Word: سلام!", "ltr"), "Word: مالس!")
check("bidi trailing spaces", visual("سلام  ", "rtl"), "  مالس")
check("bidi empty", visual("", "rtl"), "")
check("bidi decimal number", visual("قيمة 3.14", "rtl"), "3.14 ةميق")

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
