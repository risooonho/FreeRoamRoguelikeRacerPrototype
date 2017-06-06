tool
extends Position3D

# class member variables go here, for example:
#scenes we're using
var road
var road_left
var road_straight


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	var start = OS.get_ticks_msec()
	
	road = preload("res://roads/road_segment.tscn")
	road_left = preload("res://roads/road_segment_left.tscn")
	road_straight = preload("res://roads/road_segment_straight.tscn")
	
	loadData()
	
	var exec_time = OS.get_ticks_msec() - start
	print("Stored road generator execution time: " + String(exec_time))
	
	pass

func loadData():
	var savegame = File.new()
	var filename = get_name()
	var path_to_file = "roadsdata/"+filename+".json"
	#check if a file with our name on it exists
	if not savegame.file_exists(path_to_file):
		#provide a default name
		path_to_file = "roadsdata/"+"Editor panel test"+".json"
	
	if savegame.file_exists(path_to_file):
		print("We have a data file")
		
		# Load the file line by line and process that dictionary to restore the object it represents		
		savegame.open(path_to_file, File.READ)

		var loadeddata = {} # dict.parse_json() requires a declared dict.
		#lines are counted from 1 not 0
		var linenum = 1
		while (!savegame.eof_reached()):
			#print("Parsing the file")
			var line = savegame.get_line()
			#skip empty lines
			if line.empty(): break
			
			loadeddata["game" + str(linenum)] = parseJson(line)
			#print("Line is " + line)
			print("Loaded data is : " + str(loadeddata["game"+str(linenum)]))
			
			#do our stuff
			#indexes start at 0
			var segment = setupRoad(linenum-1, loadeddata["game"+str(linenum)])
			
			#if we're not the first, get previous
			if linenum > 1:
				#print("We should be getting previous segment") #data")
				var prev = get_previous_segment(linenum-1)
				print("Previous segment is " + prev.get_name())
				var prev_loc = prev.get_translation()
				
				#use data to determine whether it's a straight or a curve
				var data = get_previous_data(linenum, loadeddata)
#				print("Previous data is : " + str(data))
				var prev_type = data["type"]
				if prev_type == "straight":
					#straights don't have children nodes because they don't need 'em
					#this is positive!!!
					var end_loc = prev.relative_end 
					var loc = prev_loc + end_loc - Vector3(0,0,1)
					print("Location is " + String(loc))
					
					#are we a curve?
					var curdata = get_current_data(linenum, loadeddata)
					var cur_type = curdata["type"]
					
					if cur_type == "curved":
						segment.set_translation(loc)
					else:
						segment.get_parent().set_translation(loc)
						
					#rotations
					#print("Previous segment's end vector " + String(prev.end_vector))
					var target_loc = prev.relative_end + prev.end_vector
					#print("End vector is " + String(prev.end_vector))
					#print("Target loc is " + String(target_loc))
					var start_vec = get_start_vector(segment, loadeddata["game"+str(linenum)])
					print("Start vec " + String(start_vec))
					var angle = start_vec.angle_to(target_loc)
					print("Angle to target loc is " + String(angle))
					segment.set_rotation(Vector3(0,-angle,0))
					
				#a curve
				else:
					var end_loc = prev.get_child(0).get_child(0).relative_end #+ Vector3(1,0,0)

					print("Previous segment is a curve at " + String(prev_loc) + " ending at " + String(end_loc))
					if prev_loc != Vector3(0,0,0):
						var g_loc = prev.get_global_transform().xform(-end_loc)
						#print("Global location of relative end is" + String(g_loc))
						
						var loc = get_global_transform().xform_inv(g_loc)
						
						print("Location is " + String(loc))
						#are we a curve?
						var curdata = get_current_data(linenum, loadeddata)
						var cur_type = curdata["type"]
						
						if cur_type == "curved":
							#print("Current type is curved")
							segment.set_translation(loc)
						else:
							#print("Current type is straight")
							segment.get_parent().set_translation(loc)
					
						#rotations
						#print("Previous segment's end vector " + String(prev.end_vector))
						var target_loc = end_loc + prev.get_child(0).get_child(0).end_vector
						#negate (a curve's relative end is start-end)
						var g_target_loc = prev.get_global_transform().xform(-target_loc)
						#make the global a local again but in our space
						var check_loc = get_global_transform().xform_inv(g_target_loc)
						
						#print("Check loc is " + String(check_loc))
						#this is local
						var start_vec = get_start_vector(segment, loadeddata["game"+str(linenum)]) 
						var g_start_vec = segment.get_parent().get_global_transform().xform(start_vec)
						var start_g = get_global_transform().xform_inv(g_start_vec)

						#print("Start vec is " + String(start_g))
						
						#check the angles (relative to segment)
						var rel_target = segment.get_parent().get_global_transform().xform_inv(g_target_loc)
						print("Relative location of check vec to segment is " + String(rel_target))
						var angle = atan2(rel_target.x, rel_target.z)

						#if get_tree().is_editor_hint():
						print("Angle to target loc is " + String(rad2deg(angle)) + " degrees")
						#to point straight, we need to rotate by 180-angle degrees
						#180 degrees in radians is a scary number 3.14159265, so just trim
						var rotation = -(3.1415-angle+0.03)
						segment.get_parent().set_rotation(Vector3(0,rotation,0))
						print("Rotation is " + String(segment.get_parent().get_rotation_deg()))

			
			linenum += 1
		
	savegame.close()

func parseJson(line):
	var result = {}
	var error_code = result.parse_json(line)   # (1) What does the error code even mean?
	return result
	
func setupRoad(index, data):
	print("Setting up road for " + str(data))
	
	if data["type"] == "straight":
		print("Setting up a straight road")
		var node = setupStraightRoad(index, data)
		return node
	else:
		print("Setting up a curved road")
		var node = setupCurvedRoad(index, data)
		return node
	
func setupStraightRoad(index, data):
	var road_node = road_straight.instance()
	road_node.set_name("Road_instance" + String(index))
	
	var spatial = Spatial.new()
	spatial.set_name("Spatial")
	add_child(spatial)
	spatial.add_child(road_node)
	return road_node
	
func setupCurvedRoad(index, data):
	if data["left_turn"] == false:
		var road_node_right = road.instance()
		road_node_right.set_name("Road_instance" + String(index))
		#set the angle we wanted
		if data["angle"] > 0:
			road_node_right.get_child(0).get_child(0).angle = data["angle"]
		#set the radius we wanted
		if data["radius"] > 0:
			road_node_right.get_child(0).get_child(0).radius = data["radius"]
		add_child(road_node_right)
		return road_node_right
		
func get_previous_data(index, data):
	return data["game"+str(index-1)]
	
func get_current_data(index, data):
	return data["game"+str(index)]
	
func get_previous_segment(index):
	if has_node("Road_instance"+String(index-1)): #get_node("Road_instance"+String(index-1)):
		return get_node("Road_instance"+String(index-1))
	
	#handle the fact that the straight needs a spatial parent
	if has_node("Spatial/Road_instance"+String(index-1)): #get_node("Spatial/Road_instance"+String(index-1)):
		return get_node("Spatial/Road_instance"+String(index-1))
		
func get_start_vector(segment, data):
	#faster than checking if segment extends a custom script
	if data["type"] == "straight":
		return segment.start_vector
	else:
		return segment.get_child(0).get_child(0).start_vector
	