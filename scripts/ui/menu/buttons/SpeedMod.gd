extends ReferenceRect

@onready var mmm:Button = $C/MMM
@onready var mm:Button = $C/MM
@onready var m:Button = $C/M
@onready var normal:Button = $C/Normal
@onready var p:Button = $C/P
@onready var pp:Button = $C/PP
@onready var ppp:Button = $C/PPP
@onready var pppp:Button = $C/PPPP
@onready var custom:Button = $C/Custom

func on_button_changed(state:bool,selectedSpeed:int):
	if state: Rhythia.mod_speed_level = selectedSpeed

func _ready():
	mmm.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_MMM
	mm.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_MM
	m.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_M
	normal.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_NORMAL
	p.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_P
	pp.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_PP
	ppp.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_PPP
	pppp.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_PPPP
	custom.button_pressed = Rhythia.mod_speed_level == Globals.SPEED_CUSTOM
	
	mmm.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_MMM))
	mm.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_MM))
	m.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_M))
	normal.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_NORMAL))
	p.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_P))
	pp.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_PP))
	ppp.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_PPP))
	pppp.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_PPPP))
	custom.connect("toggled", Callable(self, "on_button_changed").bind(Globals.SPEED_CUSTOM))
