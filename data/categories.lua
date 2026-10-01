-- Puzzle categories. To add one, add an entry here and use its id in
-- puzzle files (see PUZZLES.md).
--   id          used by puzzle records
--   name        display name per interface language
--   unlockLevel player level needed to play it (Phase 6; 1 = always open)

return {
    { id = "general",    name = { ar = "عام",        en = "General" },    unlockLevel = 1 },
    { id = "technology", name = { ar = "التقنية",    en = "Technology" }, unlockLevel = 1 },
    { id = "science",    name = { ar = "العلوم",     en = "Science" },    unlockLevel = 1 },
    { id = "animals",    name = { ar = "الحيوانات",  en = "Animals" },    unlockLevel = 1 },
    { id = "countries",  name = { ar = "الدول",      en = "Countries" },  unlockLevel = 1 },
    { id = "cities",     name = { ar = "المدن",      en = "Cities" },     unlockLevel = 1 },
    { id = "history",    name = { ar = "التاريخ",    en = "History" },    unlockLevel = 1 },
    { id = "games",      name = { ar = "الألعاب",    en = "Games" },      unlockLevel = 1 },
    { id = "sports",     name = { ar = "الرياضة",    en = "Sports" },     unlockLevel = 1 },
    { id = "movies",     name = { ar = "الأفلام",    en = "Movies" },     unlockLevel = 1 },
    { id = "food",       name = { ar = "الطعام",     en = "Food" },       unlockLevel = 1 },
    { id = "nature",     name = { ar = "الطبيعة",    en = "Nature" },     unlockLevel = 1 },
}
