-- Puzzle normalization: decides which characters are guessable letters and
-- how a guess is compared with the answer.
--
--   English: case-insensitive (a == A), only A-Z are guessable.
--   Arabic:  diacritics and tatweel are ignored; letter variants are merged
--            according to Config.normalization.arabic (e.g. أ إ آ -> ا).
--
-- Everything else in an answer (spaces, digits, punctuation, hyphens) is
-- revealed automatically. The original answer is always used for display.
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Normalizer = {}

local TATWEEL = 0x0640

local rules = {
    alefVariants = true,
    alefMaqsura = false,
    taMarbuta = false,
    hamzaCarriers = false,
}

function Normalizer.configure(arabicRules)
    for key, value in pairs(arabicRules or {}) do
        rules[key] = value
    end
end

function Normalizer.getRules()
    return rules
end

function Normalizer.isArabicMark(cp)
    return (cp >= 0x064B and cp <= 0x065F) or cp == 0x0670
        or (cp >= 0x0610 and cp <= 0x061A)
        or (cp >= 0x06D6 and cp <= 0x06ED)
end

-- Characters dropped completely (not even displayed as a cell).
function Normalizer.isIgnored(cp, language)
    if language == "ar" then
        return cp == TATWEEL or Normalizer.isArabicMark(cp)
    end
    return false
end

local function isArabicLetter(cp)
    return (cp >= 0x0621 and cp <= 0x063A) or (cp >= 0x0641 and cp <= 0x064A) or cp == 0x0671
end

-- Returns the comparison key (a codepoint) for a guessable letter, or nil
-- when the character is not a guessable letter in this language.
function Normalizer.key(cp, language)
    if language == "en" then
        if cp >= 0x61 and cp <= 0x7A then
            return cp - 32
        end
        if cp >= 0x41 and cp <= 0x5A then
            return cp
        end
        return nil
    end

    if language == "ar" then
        if not isArabicLetter(cp) then
            return nil
        end
        if rules.alefVariants and (cp == 0x0623 or cp == 0x0625 or cp == 0x0622 or cp == 0x0671) then
            return 0x0627
        end
        if rules.alefMaqsura and cp == 0x0649 then
            return 0x064A
        end
        if rules.taMarbuta and cp == 0x0629 then
            return 0x0647
        end
        if rules.hamzaCarriers then
            if cp == 0x0624 then return 0x0648 end
            if cp == 0x0626 then return 0x064A end
        end
        return cp
    end

    return nil
end

function Normalizer.isGuessable(cp, language)
    return Normalizer.key(cp, language) ~= nil
end

-- True when the letter is its own key, i.e. it needs its own keyboard key
-- (letters merged into another one by the rules are hidden).
function Normalizer.isCanonical(cp, language)
    return Normalizer.key(cp, language) == cp
end

return Normalizer
