-- Virtual keyboard layouts per puzzle language.
-- Keys whose letter is merged into another one by the normalization rules
-- (e.g. أ when "alefVariants" is on) are hidden automatically, so optional
-- variant keys can be listed in `extra`.

return {
    en = {
        rows = {
            { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" },
            { "A", "S", "D", "F", "G", "H", "J", "K", "L" },
            { "Z", "X", "C", "V", "B", "N", "M" },
        },
    },

    ar = {
        -- Same positions as a standard Arabic PC keyboard.
        rows = {
            { "ض", "ص", "ث", "ق", "ف", "غ", "ع", "ه", "خ", "ح", "ج", "د" },
            { "ش", "س", "ي", "ب", "ل", "ا", "ت", "ن", "م", "ك", "ط" },
            { "ذ", "ئ", "ء", "ؤ", "ر", "ى", "ة", "و", "ز", "ظ" },
        },
        -- Shown in an extra row only when the rules keep them separate.
        extra = { "أ", "إ", "آ" },

        -- Physical keyboard fallback: when the player types Latin keys during
        -- an Arabic puzzle (OS keyboard still in English), each key is mapped
        -- to the Arabic letter at the same position on an Arabic keyboard.
        latinToArabic = {
            q = "ض", w = "ص", e = "ث", r = "ق", t = "ف", y = "غ", u = "ع", i = "ه",
            o = "خ", p = "ح", ["["] = "ج", ["]"] = "د",
            a = "ش", s = "س", d = "ي", f = "ب", g = "ل", h = "ا", j = "ت", k = "ن",
            l = "م", [";"] = "ك", ["'"] = "ط",
            z = "ئ", x = "ء", c = "ؤ", v = "ر", n = "ى", m = "ة", [","] = "و",
            ["."] = "ز", ["/"] = "ظ", ["`"] = "ذ",
        },
    },
}
