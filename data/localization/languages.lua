-- Interface languages. To add a language: create data/localization/<code>.lua
-- with the same keys as en.lua and add an entry here (see LOCALIZATION.md).
-- These files are trusted game content bundled with the game.

return {
    order = { "ar", "en" },

    ar = {
        code = "ar",
        nativeName = "العربية",
        direction = "rtl",
        dictionary = "data.localization.ar",
        -- "arabic": ٠١٢٣٤٥٦٧٨٩   "western": 0123456789
        digits = "arabic",
        -- The Arabic decimal separator (U+066B) is missing from PixelAE,
        -- so a dot is used: ١.٥
        decimalSeparator = ".",
    },

    en = {
        code = "en",
        nativeName = "English",
        direction = "ltr",
        dictionary = "data.localization.en",
        digits = "western",
        decimalSeparator = ".",
    },

    -- Used when a key is missing from the current language.
    fallback = "en",
}
