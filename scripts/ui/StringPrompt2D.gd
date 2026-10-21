extends ColorRect
class_name StringPrompt2D

signal option_selected
signal done_opening
signal done_closing

@onready var s_alert = $Alert
@onready var s_next = $Next
@onready var s_back = $Back

@onready var title_label = $C/Main/V/Title/L
@onready var body_label = $C/Main/V/Body/L
@onready var input = $"C/Main/V/Buttons/H/LineEdit"
@onready var buttons = [
	$"C/Main/V/Buttons/H/0",
	$"C/Main/V/Buttons/H/1",
	$"C/Main/V/Buttons/H/2",
	$"C/Main/V/Buttons/H/3",
]

var is_open:bool = false
var current_options:Array = []
var twn:Tween
var transition_time:float = 0.4

func open(body:String, title:String="Confirm", input:String="Profile Name",
	options:Array=[
	{ text="Cancel" },
	{ text="OK", wait=3 }
	
]):
	title_label.text = title
	body_label.text = body
	self.input.text = input

	for i in range(buttons.size()):
		var button:Button = buttons[i]
		if i < options.size():
			var option:Dictionary = options[i]
			button.visible = true
			button.disabled = true
			if option.has("wait"):
				button.text = "%s (%s)" % [option.text, ceil(option.wait)]
			else:
				button.text = option.text
		else:
			button.visible = false
	if twn:
		twn.kill()
	$C.position = Vector2(-300,0)
	modulate = Color(1,1,1,0)
	visible = true
	move_to_front()
	twn = create_tween().set_parallel()
	twn.tween_property($C,"position",Vector2(0,0),transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	twn.tween_property(self,"modulate",Color(1,1,1,1),transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await twn.finished
	for i in range(buttons.size()):
		var button:Button = buttons[i]
		if i < options.size():
			button.disabled = options[i].has("wait")
	buttons[0].grab_focus()
	is_open = true
	current_options = options
	emit_signal("done_opening")

func close():
	if twn:
		twn.kill()
	twn = create_tween().set_parallel()
	twn.tween_property($C,"position",Vector2(300,0),transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	twn.tween_property(self,"modulate",Color(1,1,1,0),transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	is_open = false
	current_options = []
	for button in buttons: button.disabled = true
	await twn.finished
	visible = false
	emit_signal("done_closing")

func _process(delta):
	if is_open:
		for i in range(current_options.size()):
			var option:Dictionary = current_options[i]
			var button:Button = buttons[i]
			if option.has("wait"):
				option.wait = max(option.wait - delta, 0)
				if option.wait == 0:
					button.disabled = false
					button.text = option.text
					option.erase("wait")
				else:
					button.text = "%s (%s)" % [option.text, ceil(option.wait)]

func _ready():
	visible = false
	for i in range(buttons.size()):
		buttons[i].connect("pressed", Callable(self, "emit_signal").bind("option_selected",i))
