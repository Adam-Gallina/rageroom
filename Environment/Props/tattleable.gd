extends Smackable
class_name Tattleable

func smack():
    smacked.emit()
    RoomManager.HitObject(self)