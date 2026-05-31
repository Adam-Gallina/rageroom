extends Node
signal spawn_room(room:Room)

class LoadedRoom:
	var ID : String = ''
	var Scene : PackedScene

	func _init(id, scene):
		ID = id
		Scene = scene

## Rooms
@onready var _start_room = LoadedRoom.new('Start', load('Environment/base_room.tscn'))
@onready var _smash_monitor = LoadedRoom.new('SmashMonitor', load('Environment/Rooms/smash_monitor.tscn'))
@onready var _smash_desk = LoadedRoom.new('SmashDesk', load('Environment/Rooms/smash_desk.tscn'))
@onready var _unlock_screwdriver = LoadedRoom.new('Screwdriver', load('Environment/Rooms/screwdriver.tscn'))
@onready var _tray_parry = LoadedRoom.new('Parry', load('Environment/Rooms/parried.tscn'))
@onready var _kaizo = LoadedRoom.new('Kaizo', load('Environment/Rooms/kaizo.tscn'))

@onready var _curr_room = _start_room


## Room State
var _smashed_monitor = false
var _smashed_desk = false
var _has_screwdriver = false
var _parried = false
var _kaizoed = false

var _curr_player : PlayerController

func RegisterPlayer(player:PlayerController):
	_curr_player = player
	_curr_player.set_screwdriver()


func HitObject(object:Smackable):
	print('Yeah you just hit ', object, ' ', object.ID)

	if object.ID == 'Monitor':
		_smashed_monitor = true
		if _has_screwdriver:
			return await ChangeToRoom(_smash_monitor)
	elif object.ID == 'Desk':
		_smashed_desk = true
		if _has_screwdriver:
			return await ChangeToRoom(_smash_desk)
	elif object.ID == 'Screwdriver':
		_has_screwdriver = true
		_curr_player.set_screwdriver(true, true)
		object.queue_free()
		return null
	elif object.ID == 'DiskTray':
		_parried = true
	elif object.ID == 'QuestionBlock':
		_kaizoed = true

	if _kaizoed:
		return await ChangeToRoom(_kaizo)
	elif _parried:
		return await ChangeToRoom(_tray_parry)
	elif _smashed_desk:
		return await ChangeToRoom(_unlock_screwdriver)
	elif _smashed_monitor:
		return await ChangeToRoom(_smash_monitor)

	printerr('What happens now')


func ChangeToRoom(room:LoadedRoom, faint_anim=true) -> Room:
	var next_room : Room = LoadRoom(room.Scene)

	if faint_anim and _curr_player != null and not _curr_player.is_queued_for_deletion():
		_curr_player.set_input(false, false)
		_curr_player.set_fainted()

		var n = await _curr_player.anim_complete
		if n == PlayerController.SwingAnim:
			print('waiting for player anim')
			await _curr_player.anim_complete
			print('done')

	_curr_room = room
	spawn_room.emit(next_room)
	return next_room


func LoadRoom(room_scene:PackedScene) -> Room:
	var r : Room = room_scene.instantiate()
	return r
