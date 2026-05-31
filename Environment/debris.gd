extends Smackable
class_name Debris
signal dropped()

var _dropped = false
func get_dropped(): return _dropped

@export var rb : RigidBody3D

@export var TattleWhileFrozen = false

func smack():
    if TattleWhileFrozen and not _dropped:
        smacked.emit()
        RoomManager.HitObject(self)
    else:
        super()

func drop():
    if _dropped: return
    _dropped = true

    var pos = global_position
    var rot = global_rotation

    var p = get_parent().get_parent()
    get_parent().remove_child(self)
    p.add_child(self)

    global_position = pos
    global_rotation = rot

    dropped.emit()
    collision_layer = 1<<2

    rb.freeze = false

    return p
