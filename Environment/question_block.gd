extends Tattleable

func smack():
	super()

	$AnimationPlayer.play('bonk')

func enable():
	$CollisionShape3D.disabled = false
