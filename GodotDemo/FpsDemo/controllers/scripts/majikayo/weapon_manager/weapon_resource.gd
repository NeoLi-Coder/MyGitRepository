class_name WeaponResource
extends Resource

# 用于第一人称视角，持枪的时候。将包含手部模型
@export var view_model: PackedScene
# 用于武器在玩家手上或地面上
@export var world_model: PackedScene

@export var view_model_pos: Vector3
@export var view_model_rot: Vector3
@export var view_model_scale := Vector3.ONE
@export var world_model_pos: Vector3
@export var world_model_rot: Vector3
@export var world_model_scale := Vector3.ONE

@export var view_idle_anim: String
@export var view_equip_anim: String
@export var view_shoot_anim: String
@export var view_reload_anim: String

# 声音
@export var shoot_sound: AudioStream
@export var reload_sound: AudioStream
@export var unholster_sound: AudioStream

# 武器逻辑
@export var damage = 10

@export var current_ammo := INF
@export var magazine_capacity := INF
@export var reserve_ammo := INF
@export var max_reserve_ammo := INF

@export var auto_fire: bool = true
@export var max_fire_rate_ms = 50

const RAYCAST_DIST: float = 9999 # 似乎太远会破坏它

var weapon_manager: WeaponManager

var trigger_down := false:
	set(v):
		if trigger_down != v:
			trigger_down = v
			if trigger_down:
				on_trigger_down()
			else:
				on_trigger_up()

var is_equipped := false:
	set(v):
		if is_equipped != v:
			is_equipped = v
			if is_equipped:
				on_equip()
			else:
				on_unequip()

var last_fire_time = -999999

func on_process(delta):
	if trigger_down and auto_fire \
			and Time.get_ticks_msec() - last_fire_time > max_fire_rate_ms:
		if current_ammo > 0:
			fire_shot()
		else:
			reload_pressed()


func on_trigger_down():
	if Time.get_ticks_msec() - last_fire_time >= max_fire_rate_ms and current_ammo > 0:
		fire_shot()
	elif current_ammo == 0:
		reload_pressed()


func on_trigger_up():
	pass


func on_equip():
	weapon_manager.play_anim(view_equip_anim)
	weapon_manager.queue_anim(view_idle_anim)


func on_unequip():
	pass


func get_amount_can_reload() -> int:
	var wish_reload = magazine_capacity - current_ammo
	var can_reload = min(wish_reload, reserve_ammo)
	return can_reload


func reload_pressed():
	if view_reload_anim and weapon_manager.get_anim() == view_reload_anim:
		return
	if get_amount_can_reload() <= 0:
		return
	var cancel_cb = func(): weapon_manager.stop_sounds()
	weapon_manager.play_anim(view_reload_anim, reload, cancel_cb)
	weapon_manager.queue_anim(view_idle_anim)
	weapon_manager.play_sound(reload_sound)


func reload():
	var reload_amount = get_amount_can_reload()
	if reload_amount < 0:
		return
	if magazine_capacity == INF or current_ammo == INF:
		current_ammo = magazine_capacity
	else:
		current_ammo += reload_amount
		reserve_ammo -= reload_amount


func fire_shot():
	weapon_manager.play_anim(view_shoot_anim)
	weapon_manager.play_sound(shoot_sound)
	weapon_manager.queue_anim(view_idle_anim)
	
	var raycast = weapon_manager.bullet_raycast
	raycast.target_position = Vector3(0, 0, -abs(RAYCAST_DIST))
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var obj = raycast.get_collider()
		var nrml = raycast.get_collision_normal()
		var pt = raycast.get_collision_point()
		if obj is RigidBody3D:
			obj.apply_impulse(-nrml * 5.0 / obj.mass, pt - obj.global_position)
		if obj.has_method("take_damage"):
			obj.take_damage(self.damage)
	
	last_fire_time = Time.get_ticks_msec()
	current_ammo -= 1
