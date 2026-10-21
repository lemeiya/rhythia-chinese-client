extends ColorRect

@onready var languageselect = $ChangeLanguage/SelectLanguageWindow/languageselector

# locale table for Globals.locale
# en = 0
# jp = 1
# fr = 2
# es = 3
# it = 4
# pl = 5
# zh_CN = 6

# # Called when the node enters the scene tree for	 the first time.
func _ready():
	Rhythia.apply_render_scale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_items()
	languageselect.selected = Rhythia.language

func add_items():
	languageselect.add_item("ENGLISH")
	languageselect.add_item("JAPANESE")
	languageselect.add_item("FRENCH")
	languageselect.add_item("SPANISH")
	languageselect.add_item("ITALIAN")
	languageselect.add_item("POLISH")
	languageselect.add_item("简体中文")

func _on_languageselector_item_selected(index):
	Rhythia.language = index
	TranslationServer.set_locale(Globals.locale[Rhythia.language])
