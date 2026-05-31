extends Debris

@export var ConnectedScrews : Array[Debris]

@export var Offset : Vector3
@export var DropForce = 10.

func _ready():
	for s in ConnectedScrews:
		s.dropped.connect(_on_screw_removed)

func _on_screw_removed():
	for s in ConnectedScrews:
		if not s.get_dropped(): return

	var p = drop()

	var dir = p.global_position.direction_to(global_position + Offset)
	rb.apply_impulse(dir * DropForce, global_position)
	
