extends Node2D

# class member variables go here, for example:

func _ready():
	#set_process_input(true)
	set_fixed_process(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _fixed_process(delta):
	var player_rot = get_parent().get_parent().get_parent().get_rotation()
	var map_rot = -player_rot.y
	
	#this resolves the gimbal lock issues
	if (player_rot.x < -deg2rad(150) or player_rot.x > deg2rad(150)) and (player_rot.z < - deg2rad(150) or player_rot.z > deg2rad(150)):
		map_rot = deg2rad(180)+player_rot.y #1.02
	
	set_rot(map_rot)
	
	#print("Player rotation is " + String(player_rot))