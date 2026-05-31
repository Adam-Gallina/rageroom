extends Node3D

@export var SpinSpeed = 1.
@onready var _pivot : Node3D = $Pivot

func _ready() -> void:
    for s in _pivot.get_children():
        s.rotation.y = randf() * 2 * PI

func _process(delta: float) -> void:
    _pivot.rotation.y += 2 * PI * SpinSpeed * delta

    for s in _pivot.get_children():
        s.rotation.y += 2 * PI * SpinSpeed * delta