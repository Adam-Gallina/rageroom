extends Control

@export var RotateMax = 15
@onready var _ang = deg_to_rad(RotateMax)
@export var RotateSpeed = .5

@onready var _start_rot = rotation
var _t = 0

func _process(delta: float) -> void:
    _t += delta

    rotation = _start_rot + _ang * sin(_t * 2 * PI * RotateSpeed)

