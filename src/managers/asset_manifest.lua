-- Every external asset the game knows about, in one place.
-- Code refers to assets by key (Assets.fonts.regular, Assets.images.backgroundMenu),
-- never by file path. See ASSETS.md for sizes and details of each file.
--
-- required = true  -> a warning is logged as an ERROR when missing (the game still runs).
-- Missing images fall back to placeholder art drawn in code.

return {
    fonts = {
        -- PixelAE is drawn on a 10px grid: size 10 = 1 font pixel per screen pixel,
        -- size 20 = 2x (titles). Other sizes would blur the pixels.
        regular = { path = "assets/PixelAE/PixelAE-Regular.ttf", size = 10, required = true },
        bold = { path = "assets/PixelAE/PixelAE-Bold.ttf", size = 10, required = true },
        title = { path = "assets/PixelAE/PixelAE-Bold.ttf", size = 20, required = true },
    },

    images = {
        backgroundMenu = { path = "assets/backgrounds/menu.png" },
        backgroundGameplay = { path = "assets/backgrounds/gameplay.png" },
        backgroundResults = { path = "assets/backgrounds/results.png" },
        backgroundGameplayFar = { path = "assets/backgrounds/gameplay_far.png" },
        backgroundGameplayNear = { path = "assets/backgrounds/gameplay_near.png" },

        hangmanStages = { path = "assets/sprites/hangman_stages.png" },
        character = { path = "assets/sprites/character.png" },

        panel = { path = "assets/ui/panel.png" },
        button = { path = "assets/ui/button.png" },
        key = { path = "assets/ui/key.png" },
        cursor = { path = "assets/ui/cursor.png" },
        logoArabic = { path = "assets/ui/logo_ar.png" },
        logoEnglish = { path = "assets/ui/logo_en.png" },

        icons = { path = "assets/icons/icons.png" },
    },
}
