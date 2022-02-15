extends Node2D

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const MIN_BLINK_TIME : float = 0.1
const MAX_BLINK_TIME : float = 0.5

const MIN_SPAN_TIME : float = 1.2
const MAX_SPAN_TIME : float = 6.6

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var color_eyes : Color = Color(0,0,0)		setget set_color_eyes
export var color_skin : Color = Color(1,1,1)		setget set_color_skin
export var color_body_base : Color = Color(1,1,1)		setget set_color_body_base
export var color_body_dark : Color = Color(1,1,1)		setget set_color_body_dark
export var color_body_light : Color = Color(1,1,1)		setget set_color_body_light

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var blink_delay : float = 0

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var eyes_node : Node2D = get_node("Body/Head/Eyes")
onready var leye_node : Sprite = get_node("Body/Head/Eyes/LEye")
onready var reye_node : Sprite = get_node("Body/Head/Eyes/REye")
onready var head_node : Sprite = get_node("Body/Head")
onready var body_node : Sprite = get_node("Body")

# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func set_color_eyes(c : Color) -> void:
	color_eyes = c
	if leye_node and reye_node:
		leye_node.self_modulate = color_eyes
		reye_node.self_modulate = color_eyes


func set_color_skin(c : Color) -> void:
	color_skin = c
	if head_node:
		head_node.material.set_shader_param("to_color_1", color_skin)

func set_color_body_base(c : Color) -> void:
	color_body_base = c
	if body_node:
		body_node.material.set_shader_param("to_color_1", color_body_base)

func set_color_body_dark(c : Color) -> void:
	color_body_dark = c
	if body_node:
		body_node.material.set_shader_param("to_color_2", color_body_dark)

func set_color_body_light(c : Color) -> void:
	color_body_light = c
	if body_node:
		body_node.material.set_shader_param("to_color_3", color_body_light)


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	set_color_eyes(color_eyes)
	set_color_skin(color_skin)
	set_color_body_base(color_body_base)
	set_color_body_dark(color_body_dark)
	set_color_body_light(color_body_light)

func _process(delta : float) -> void:
	if blink_delay <= 0.0:
		_toggleBlink()
	else:
		blink_delay -= delta

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _toggleBlink() -> void:
	if eyes_node.visible:
		blink_delay = rand_range(MIN_BLINK_TIME, MAX_BLINK_TIME)
	else:
		blink_delay = rand_range(MIN_SPAN_TIME, MAX_SPAN_TIME)
	eyes_node.visible = !eyes_node.visible

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------


