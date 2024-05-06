extends Control
class_name GemCell
# VARS
@onready var sprite:Sprite2D = $Sprite2D
@onready var anim_player:AnimationPlayer = $AnimationPlayer
@onready var animated_busy:AnimatedSprite2D = $DebugAnimatedBusy
@onready var debug_label_sel_num:Label = $DebugLabelSelNum
# PROPS
const SPRITE_SCALE:float = 0.25
var gem_color:Enums.GemColor

func initialize(colorIn: Enums.GemColor):
	# A:
	gem_color = colorIn
	load_texture()
	# B:
	#card_control.connect("card_drag_start", self._on_card_drag_start)
	#card_control.connect("card_drag_ended", self._on_card_drag_ended)
	# C:
	#panel_hover.visible = false

func load_texture():
	# Construct texture path based on suit and rank
	var texture_path = "res://assets/gems/"
	if gem_color == Enums.GemColor.WHITE:
		texture_path += "characters_0001" + ".png"
	elif gem_color == Enums.GemColor.RED:
		texture_path += "characters_0002" + ".png"
	elif gem_color == Enums.GemColor.YELLOW:
		texture_path += "characters_0003" + ".png"
	elif gem_color == Enums.GemColor.GREEN:
		texture_path += "characters_0005" + ".png"
	elif gem_color == Enums.GemColor.PURPLE:
		texture_path += "characters_0007" + ".png"
	
	# Load and assign texture
	sprite.texture = ResourceLoader.load(texture_path)
	#print("[gem_cell] loaded sprite.texture: ", texture_path)

func play_selected_anim(selected:bool):
	if selected:
		anim_player.play("selected")
	else:
		anim_player.stop(false)
		sprite.scale.x = SPRITE_SCALE
		sprite.scale.y = SPRITE_SCALE

func play_anim_explode():
	#anim_player.play("explode")
	sprite.visible = false
	animated_busy.visible = true
	animated_busy.play()
	debug_label_sel_num.visible = true

func debug_show_selnum(num:int):
	if not num or num == 0:
		debug_label_sel_num.visible = false
		debug_label_sel_num.text = "-"
	else:
		debug_label_sel_num.visible = true
		debug_label_sel_num.text = str(num)
