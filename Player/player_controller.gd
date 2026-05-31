extends CharacterBody3D
class_name PlayerController
signal anim_complete(anim_name:StringName)

const IdleAnim = 'idle'
const MoveAnim = 'move'
const SwingAnim = 'swing'
const BackSwingAnim = 'backswing'
const FaintAnim = 'faint'

@export_category('Movement')
@export var MoveSpeed = 10
var _disable_movement = false

@export_category('Camera')
@export var CamSpeed = .125
@export var MinPitch = -90.
@export var MaxPitch = 90.
var pitch:
	set(val): $CamParent.rotation.x = val
	get: return $CamParent.rotation.x
var yaw:
	set(val): rotation.y = val
	get: return rotation.y
var _disable_cam = false
@export var CamMod = 1.

@export_category('Items')
@onready var _bat = $CamParent/BatPivot/Bat
@onready var _screwdriver = $CamParent/BatPivot/Screwdriver
var _equipped = 0
@export var UnlockedScrewdriver = false
func set_screwdriver(unlocked:bool = true, show_tutorial:bool = false): 
	UnlockedScrewdriver = unlocked
	$CanvasLayer/Inventory.show()
	$CanvasLayer/Inventory/AnimationPlayer.play('slide_in')
	if show_tutorial:
		$CanvasLayer/Tutorial/EquipScrewdriver.show()
		while _equipped == 0:
			await get_tree().process_frame
		$CanvasLayer/Tutorial/EquipScrewdriver.hide()
		$CanvasLayer/Tutorial/SwangThatThang.show()
		while not Input.is_action_just_pressed('Select'):
			await get_tree().process_frame
		$CanvasLayer/Tutorial/SwangThatThang.hide()

@export_category('Effects')
@export var HitParticles : Array[PackedScene]
@onready var _stars = $Stars

var _attacking = false
var _fainted = false

@onready var cam: Camera3D = $CamParent/Camera3D
#@onready var _hit_ray: RayCast3D = $CamParent/HitRayCast3D
@onready var _screw_ray: RayCast3D = $CamParent/ScrewRayCast3D
@onready var _bat_shapecast: ShapeCast3D = $CamParent/BatPivot/ShapeCast3D

func set_input(enable_movement=true, enable_cam=true):
	_disable_movement = not enable_movement
	_disable_cam = not enable_cam

@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var anim_tree : AnimationTree = $AnimationTree

func _ready() -> void:

	$CanvasLayer/Inventory.hide()
	anim.play(IdleAnim)
	RoomManager.RegisterPlayer(self)
	_stars.hide()

func _process(delta):
	_handle_input(delta)

	if not _disable_movement:
		velocity = _handle_movement(delta)
		move_and_slide()
		apply_floor_snap()


func _handle_movement(_delta):
	var x = Input.get_axis('Left', 'Right')
	var z = Input.get_axis('Forward', 'Back')

	var b : Basis = transform.basis
	var dir = (b.z * z + b.x * x).normalized() * MoveSpeed

	return dir

func _handle_input(_delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		if Input.is_key_pressed(KEY_SHIFT):
			get_tree().quit()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if _disable_cam: return

	if _attacking:
		if _equipped == 0:
			_bat_shapecast.force_shapecast_update()
			if _bat_shapecast.is_colliding() and _bat_shapecast.get_collision_count() > 0:
				_on_hit(_bat_shapecast.get_collider(0), _bat_shapecast.get_collision_point(0))
				_attacking = false
	else:
		if UnlockedScrewdriver:
			var next_equipped = _equipped
			if Input.is_action_just_pressed('Inventory_1'):
				next_equipped = 0
			elif Input.is_action_just_pressed('Inventory_2'):
				next_equipped = 1
			elif Input.is_action_just_pressed('Inventory_Down'):
				next_equipped += 1
				if next_equipped > 1: next_equipped = 0
			elif Input.is_action_just_pressed('Inventory_Up'):
				next_equipped -= 1
				if next_equipped < 0: next_equipped = 1

			if next_equipped != _equipped:
				_equipped = next_equipped
				if _equipped == 0:
					$CanvasLayer/Inventory/AnimationPlayer.play('bat')
				elif _equipped == 1:
					$CanvasLayer/Inventory/AnimationPlayer.play('screwdriver')
				_bat.visible = _equipped == 0
				_screwdriver.visible = _equipped == 1

		if Input.is_action_just_pressed('Select'):
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				swing()
					

func swing():
	if not _attacking:
		_attacking = true

func _do_hit():
	if _equipped == 1:
		if _screw_ray.is_colliding():
			var hit = _screw_ray.get_collider()
			if hit != null:
				_on_screw(hit)


func _on_hit(hit:Object, point:Vector3):
	if hit.get_collision_layer_value(2):
		if hit is Smackable:
			hit.smack()
			do_hit_particles(point)
		else:
			printerr('Tried to hit non-smackable: ', hit)
			do_hit_particles(point)
	elif hit is RigidBody3D:
		var look_dir = cam.global_position.direction_to(point).normalized()
		var dir = global_position.direction_to(point)
		var hit_dir = -$CamParent/BatPivot.basis.x
		dir.y = 0
		dir = dir.normalized()
		hit.linear_velocity = dir + Vector3.UP * 5 + look_dir * 2 + hit_dir * 3
		hit.angular_velocity = look_dir * 4
		do_hit_particles(point)
	else:
		do_hit_particles(point)

func _on_screw(hit:Object):
	if hit.get_collision_layer_value(2):
		if hit is Smackable:
			hit.screw()
		else:
			printerr('Tried to screw non-smackable: ', hit)


func do_hit_particles(pos:Vector3):
	for particle in HitParticles:
		var p : CPUParticles3D = particle.instantiate()
		get_parent().add_child(p)
		p.global_position = pos
		p.finished.connect(p.queue_free)
		p.emitting = true

func do_star_particles():
	_stars.show()


func set_fainted(faint:bool = true):
	_fainted = faint

func _on_animation_finished(anim_name:StringName) -> void:
	anim_complete.emit(anim_name)

	if anim_name == 'swing':
		_attacking = false
	elif anim_name == 'backswing':
		_attacking = false


func set_camera(p: float, y: float):
	yaw = y
	if p < MinPitch: p = MinPitch
	elif p > MaxPitch: p = MaxPitch
	pitch = p

func _rotate_camera(dp: float, dy: float):
	yaw -= dy * CamSpeed * CamMod * PI / 180
	var p = pitch * 180 / PI - dp * CamSpeed * CamMod
	if p < MinPitch: p = MinPitch
	elif p > MaxPitch: p = MaxPitch
	pitch = p * PI / 180

func _input(event):
	if event is InputEventMouseMotion and not _disable_cam:
		_rotate_camera(event.relative.y, event.relative.x)

func _reset_cam(duration:float=.5):
	var start_p = pitch
	var start_y = yaw
	var end_y = yaw + PI
	var remaining = duration
	while remaining > 0:
		remaining -= get_process_delta_time()

		var t = 1 - remaining / duration
		pitch = start_p - start_p * t
		yaw = start_y + (end_y - start_y) * t

		await get_tree().process_frame
	
	pitch = 0
	yaw = 0
