extends CollisionObject3D
class_name Smackable
signal smacked()

@export var ID = ''

func smack():
    print(name, ': Yeowch!')
    smacked.emit()

func screw():
    pass