extends Debris
class_name Screw

@export var UnscrewDuration = 1.
@export var UnscrewOffset = .25

var _screwed = false

func smack():
    pass

func screw():
    if _screwed: return

    _screwed = true
    _unscrew()


func _unscrew():
    var start_pos = global_position
    var dir = global_basis.z
    var duration = UnscrewDuration
    while duration > 0:
        duration -= get_process_delta_time()
        var t = 1 - duration / UnscrewDuration

        global_position = start_pos + dir * UnscrewOffset * t

        await get_tree().process_frame

    drop()
