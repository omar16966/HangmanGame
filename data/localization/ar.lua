-- نصوص الواجهة العربية. المفاتيح مطابقة لملف en.lua.
-- Arabic interface strings. Placeholders use {name}.
-- Diacritics are optional: the PixelAE font has no harakat, so they are
-- removed automatically before drawing.

return {
    -- General
    GAME_TITLE = "الرجل المشنوق",
    LOADING = "جاري التحميل",
    YES = "نعم",
    NO = "لا",
    OK = "موافق",
    CANCEL = "إلغاء",
    BACK = "رجوع",
    NEXT = "التالي",
    CONFIRM = "تأكيد",
    ON = "تشغيل",
    OFF = "إيقاف",

    -- Main menu
    PLAY = "ابدأ اللعب",
    CONTINUE = "متابعة",
    SCORES = "النتائج",
    STATISTICS = "الإحصائيات",
    SETTINGS = "الإعدادات",
    HOW_TO_PLAY = "طريقة اللعب",
    CREDITS = "فريق العمل",
    EXIT = "خروج",
    ADD_WORD = "أضف كلمة",
    MY_WORDS = "كلماتي",

    -- Languages
    CHOOSE_INTERFACE_LANGUAGE = "اختر لغة الواجهة",
    CHOOSE_PUZZLE_LANGUAGE = "اختر لغة الألغاز",
    INTERFACE_LANGUAGE = "لغة الواجهة",
    PUZZLE_LANGUAGE = "لغة الألغاز",
    LANGUAGE = "اللغة",
    LANGUAGE_ARABIC = "العربية",
    LANGUAGE_ENGLISH = "الإنجليزية",

    -- Difficulty
    DIFFICULTY = "الصعوبة",
    DIFFICULTY_EASY = "سهل",
    DIFFICULTY_NORMAL = "متوسط",
    DIFFICULTY_HARD = "صعب",

    -- Pause
    PAUSED = "إيقاف مؤقت",
    RESUME = "متابعة",
    RESTART_ROUND = "إعادة الجولة",
    MAIN_MENU = "القائمة الرئيسية",
    CONFIRM_ABANDON = "هل تريد مغادرة الجولة الحالية؟ سيضيع تقدمك فيها.",

    -- Gameplay
    SCORE = "النقاط",
    CATEGORY = "الفئة",
    ATTEMPTS_LEFT = "المحاولات المتبقية: {count}",
    HINT = "تلميح",
    HINT_TEXT = "عرض التلميح",
    HINT_REVEAL = "كشف حرف",
    HINT_COST = "-{points} نقطة",
    NO_HINT = "لا يوجد تلميح لهذا اللغز.",
    SCORE_VALUE = "النقاط: {value}",
    ALREADY_GUESSED = "جربت هذا الحرف من قبل.",
    TYPE_ARABIC = "استخدم الحروف العربية لهذا اللغز.",
    TYPE_ENGLISH = "استخدم الحروف الإنجليزية لهذا اللغز.",
    NOTHING_TO_REVEAL = "لا يمكن كشف حرف الآن.",
    NO_PUZZLES = "لا توجد ألغاز متاحة لهذا الاختيار.",
    NEXT_ROUND_PROMPT = "اضغط Enter أو انقر للغز التالي",
    ROUND_POINTS = "+{points}",

    -- Results
    RESULT_WIN = "أحسنت!",
    RESULT_LOSS = "حظا أوفر في المرة القادمة",
    ANSWER = "الإجابة",
    ACCURACY = "الدقة",
    WRONG_GUESSES = "التخمينات الخاطئة",
    TIME = "الوقت",
    BONUS = "المكافأة",
    XP = "الخبرة",
    STREAK = "سلسلة الفوز",
    TOTAL = "المجموع",
    NEXT_PUZZLE = "اللغز التالي",
    REPLAY = "إعادة اللعب",

    -- Settings
    GRAPHICS = "الرسوميات",
    AUDIO = "الصوت",
    GAMEPLAY = "اللعب",
    MASTER_VOLUME = "الصوت العام",
    MUSIC_VOLUME = "الموسيقى",
    SFX_VOLUME = "المؤثرات الصوتية",
    MUTE = "كتم الصوت",
    FULLSCREEN = "ملء الشاشة",
    WINDOW_SIZE = "حجم النافذة",
    SHADERS = "المؤثرات البصرية",
    CRT_EFFECT = "تأثير الشاشة القديمة",
    SCANLINES = "خطوط المسح",
    SCREEN_SHAKE = "اهتزاز الشاشة",
    PARTICLES = "الجزيئات",

    -- Statistics
    GAMES_PLAYED = "عدد الألعاب",
    ROUNDS_PLAYED = "الجولات",
    ROUNDS_WON = "جولات الفوز",
    ROUNDS_LOST = "جولات الخسارة",
    WIN_RATE = "نسبة الفوز",
    CORRECT_GUESSES = "التخمينات الصحيحة",
    ARABIC_GAMES = "الألغاز العربية",
    ENGLISH_GAMES = "الألغاز الإنجليزية",
    BEST_SCORE = "أفضل نتيجة",
    TOTAL_SCORE = "مجموع النقاط",
    BEST_STREAK = "أطول سلسلة فوز",
    CURRENT_STREAK = "السلسلة الحالية",
    HINTS_USED = "التلميحات المستخدمة",
    PLAY_TIME = "وقت اللعب",
    LEVEL = "المستوى {level}",

    -- Formats
    POINTS = "{value} نقطة",
    PERCENT = "{value}٪",
}
