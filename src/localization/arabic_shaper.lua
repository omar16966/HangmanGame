-- Arabic shaper: chooses the contextual form (isolated / final / initial /
-- medial) of every Arabic letter, using the Unicode "Arabic Presentation
-- Forms" codepoints, and builds the mandatory lam-alef ligatures.
--
-- LÖVE draws each codepoint as-is (it does not apply the font's OpenType
-- shaping tables), so without this step Arabic would appear as disconnected
-- letters. This works on *logical* order; direction is handled by bidi.lua.
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Shaper = {}

-- base = { isolated, final, initial, medial } presentation forms.
-- Letters with only two forms are right-joining (they never connect to the
-- following letter). The isolated form is always output as the base letter:
-- every Arabic font draws the base codepoint in its isolated shape, while
-- many fonts (including PixelAE) omit the separate isolated presentation forms.
local FORMS = {
    [0x0621] = { 0xFE80 },                         -- ء  (non-joining)
    [0x0622] = { 0xFE81, 0xFE82 },                 -- آ
    [0x0623] = { 0xFE83, 0xFE84 },                 -- أ
    [0x0624] = { 0xFE85, 0xFE86 },                 -- ؤ
    [0x0625] = { 0xFE87, 0xFE88 },                 -- إ
    [0x0626] = { 0xFE89, 0xFE8A, 0xFE8B, 0xFE8C }, -- ئ
    [0x0627] = { 0xFE8D, 0xFE8E },                 -- ا
    [0x0628] = { 0xFE8F, 0xFE90, 0xFE91, 0xFE92 }, -- ب
    [0x0629] = { 0xFE93, 0xFE94 },                 -- ة
    [0x062A] = { 0xFE95, 0xFE96, 0xFE97, 0xFE98 }, -- ت
    [0x062B] = { 0xFE99, 0xFE9A, 0xFE9B, 0xFE9C }, -- ث
    [0x062C] = { 0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0 }, -- ج
    [0x062D] = { 0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4 }, -- ح
    [0x062E] = { 0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8 }, -- خ
    [0x062F] = { 0xFEA9, 0xFEAA },                 -- د
    [0x0630] = { 0xFEAB, 0xFEAC },                 -- ذ
    [0x0631] = { 0xFEAD, 0xFEAE },                 -- ر
    [0x0632] = { 0xFEAF, 0xFEB0 },                 -- ز
    [0x0633] = { 0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4 }, -- س
    [0x0634] = { 0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8 }, -- ش
    [0x0635] = { 0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC }, -- ص
    [0x0636] = { 0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0 }, -- ض
    [0x0637] = { 0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4 }, -- ط
    [0x0638] = { 0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8 }, -- ظ
    [0x0639] = { 0xFEC9, 0xFECA, 0xFECB, 0xFECC }, -- ع
    [0x063A] = { 0xFECD, 0xFECE, 0xFECF, 0xFED0 }, -- غ
    [0x0641] = { 0xFED1, 0xFED2, 0xFED3, 0xFED4 }, -- ف
    [0x0642] = { 0xFED5, 0xFED6, 0xFED7, 0xFED8 }, -- ق
    [0x0643] = { 0xFED9, 0xFEDA, 0xFEDB, 0xFEDC }, -- ك
    [0x0644] = { 0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0 }, -- ل
    [0x0645] = { 0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4 }, -- م
    [0x0646] = { 0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8 }, -- ن
    [0x0647] = { 0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC }, -- ه
    [0x0648] = { 0xFEED, 0xFEEE },                 -- و
    [0x0649] = { 0xFEEF, 0xFEF0 },                 -- ى
    [0x064A] = { 0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4 }, -- ي
    -- Extended letters (Persian / loan words)
    [0x067E] = { 0xFB56, 0xFB57, 0xFB58, 0xFB59 }, -- پ
    [0x0686] = { 0xFB7A, 0xFB7B, 0xFB7C, 0xFB7D }, -- چ
    [0x0698] = { 0xFB8A, 0xFB8B },                 -- ژ
    [0x06A4] = { 0xFB6A, 0xFB6B, 0xFB6C, 0xFB6D }, -- ڤ
    [0x06A9] = { 0xFB8E, 0xFB8F, 0xFB90, 0xFB91 }, -- ک
    [0x06AF] = { 0xFB92, 0xFB93, 0xFB94, 0xFB95 }, -- گ
    [0x06BA] = { 0xFB9E, 0xFB9F },                 -- ں
    [0x06CC] = { 0xFBFC, 0xFBFD, 0xFBFE, 0xFBFF }, -- ی
}

local LAM = 0x0644
-- alef variant -> { isolated ligature, final ligature }
local LAM_ALEF = {
    [0x0622] = { 0xFEF5, 0xFEF6 }, -- لآ
    [0x0623] = { 0xFEF7, 0xFEF8 }, -- لأ
    [0x0625] = { 0xFEF9, 0xFEFA }, -- لإ
    [0x0627] = { 0xFEFB, 0xFEFC }, -- لا
}

local TATWEEL = 0x0640
local ZWJ = 0x200D

-- Joining types: "D" dual, "R" right, "C" join-causing, "T" transparent, "U" none.
local function isMark(cp)
    return (cp >= 0x064B and cp <= 0x065F) or cp == 0x0670
        or (cp >= 0x0610 and cp <= 0x061A)
        or (cp >= 0x06D6 and cp <= 0x06DC) or (cp >= 0x06DF and cp <= 0x06E4)
        or cp == 0x06E7 or cp == 0x06E8 or (cp >= 0x06EA and cp <= 0x06ED)
end
Shaper.isMark = isMark

local function joiningType(cp)
    local forms = FORMS[cp]
    if forms then
        if #forms == 4 then return "D" end
        if #forms == 2 then return "R" end
        return "U"
    end
    if cp == TATWEEL or cp == ZWJ then return "C" end
    if isMark(cp) then return "T" end
    return "U"
end
Shaper.joiningType = joiningType

local function canJoinNext(t) return t == "D" or t == "C" end
local function canJoinPrev(t) return t == "D" or t == "R" or t == "C" end

-- Returns true if the codepoint is a letter this shaper knows.
function Shaper.isArabicLetter(cp)
    return FORMS[cp] ~= nil
end

-- Shapes an array of codepoints (logical order) and returns a new array.
-- options.stripMarks  remove harakat/diacritics (for fonts without them)
-- options.hasGlyph    function(cp) -> bool; forms missing from the font
--                     fall back to the plain letter instead of an empty box
function Shaper.shape(cps, options)
    options = options or {}
    local hasGlyph = options.hasGlyph

    local input = cps
    if options.stripMarks then
        input = {}
        for i = 1, #cps do
            if not isMark(cps[i]) then
                input[#input + 1] = cps[i]
            end
        end
    end

    local n = #input
    local types = {}
    for i = 1, n do
        types[i] = joiningType(input[i])
    end

    -- Nearest non-transparent neighbours.
    local prevIndex, nextIndex = {}, {}
    local last = nil
    for i = 1, n do
        prevIndex[i] = last
        if types[i] ~= "T" then last = i end
    end
    last = nil
    for i = n, 1, -1 do
        nextIndex[i] = last
        if types[i] ~= "T" then last = i end
    end

    local function pick(form, fallback)
        if form and (not hasGlyph or hasGlyph(form)) then
            return form
        end
        return fallback
    end

    local out = {}
    local skip = {}
    for i = 1, n do
        if not skip[i] then
            local cp = input[i]
            local t = types[i]
            local forms = FORMS[cp]
            if not forms then
                out[#out + 1] = cp
            else
                local p, q = prevIndex[i], nextIndex[i]
                local joinsPrev = canJoinPrev(t) and p ~= nil and canJoinNext(types[p])
                local ligature = cp == LAM and q ~= nil and LAM_ALEF[input[q]]

                if ligature then
                    local form = joinsPrev and ligature[2] or ligature[1]
                    if hasGlyph and not hasGlyph(form) then
                        -- No ligature glyph: draw lam + alef as normal letters.
                        out[#out + 1] = pick(joinsPrev and forms[4] or forms[3], cp)
                        out[#out + 1] = pick(FORMS[input[q]][2], input[q])
                    else
                        out[#out + 1] = form
                    end
                    -- Keep marks that sat between lam and alef, drop the alef.
                    for k = i + 1, q - 1 do
                        out[#out + 1] = input[k]
                        skip[k] = true
                    end
                    skip[q] = true
                else
                    local joinsNext = canJoinNext(t) and q ~= nil and canJoinPrev(types[q])
                    local form
                    if joinsPrev and joinsNext then
                        form = forms[4]
                    elseif joinsPrev then
                        form = forms[2]
                    elseif joinsNext then
                        form = forms[3]
                    end
                    out[#out + 1] = pick(form, cp)
                end
            end
        end
    end
    return out
end

return Shaper
