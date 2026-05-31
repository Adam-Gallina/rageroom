extends Node3D

@export var _curr_room : Room

@onready var screen_fade : ScreenFade = $ScreenTransitions

func _ready() -> void:
	RoomManager.spawn_room.connect(_spawn_room)


func _spawn_room(room:Room):
	await screen_fade.fade_out(1)
	
	_curr_room.queue_free()
	add_child(room)
	_curr_room = room

	await screen_fade.fade_in(.5)

	_curr_room.start()
