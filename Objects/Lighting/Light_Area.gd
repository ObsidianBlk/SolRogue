extends Light2D

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var flicker : bool = false
export (float, 0.0, 4.0, 0.01) var energy_variance = 0.5
export (float, 0.0, 1.0, 0.01) var duration = 0.1
export (float, 0.0, 1.0, 0.01) var duration_variance = 0.0

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _energy_base : float = 0.0

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var tween_node : Tween = get_node("Tween")

# -------------------------------------------------------------------------
# Setters
# -------------------------------------------------------------------------
func set_flicker(f : bool) -> void:
	flicker = f
	if not flicker:
		if tween_node:
			tween_node.stop_all()
		self.energy = _energy_base

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	_energy_base = self.energy

func _process(delta : float) -> void:
	if flicker and not tween_node.is_active():
		_FlickerLight()

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _FlickerLight() -> void:
	var target_energy : float = _energy_base + (_energy_base * rand_range(0, energy_variance))
	var target_dur : float = duration + (duration * rand_range(-duration_variance, duration_variance))
	
	tween_node.interpolate_property(
		self, "energy",
		self.energy, target_energy,
		target_dur,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween_node.start()


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
