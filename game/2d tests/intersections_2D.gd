tool
extends Node2D

# class member variables go here, for example:
	
	
# need to be class-level because draw()
var loc_src_exit = Vector2(0,0)
var loc_dest_exit = Vector2(0,0)

var loc_src_extended = Vector2(0,0)
var loc_dest_extended = Vector2(0,0)

var helper_line

func _ready():
	helper_line = load("res://2d tests/Line2D.tscn")

	connect_intersections(1,0)
	connect_intersections(0,2)
	connect_intersections(1,2)
	

func connect_intersections(one, two):
	var src_exit = get_src_exit(get_child(one), get_child(two))
	loc_src_exit = to_local(get_child(one).to_global(src_exit))
	
	var dest_exit = get_dest_exit(get_child(one), get_child(two))
	loc_dest_exit = to_local(get_child(two).to_global(dest_exit))
	
	extend_lines(one,two)
	
	setup_line_2d()
	

func extend_lines(one,two):
	#B-A: A->B
	var src_line = loc_src_exit-get_child(one).get_position()
	var extend = 2
	loc_src_extended = src_line*extend + get_child(one).get_position()
	
	var dest_line = loc_dest_exit-get_child(two).get_position()
	
	loc_dest_extended = dest_line*extend + get_child(two).get_position()

func setup_line_2d():
	var help = helper_line.instance()
	
	help.points = [loc_src_exit, loc_src_extended, loc_dest_extended, loc_dest_exit]
	# looks
	help.width = 5
	help.set_default_color(Color(0.4, 0.5, 1, 0.2))
	
	add_child(help)



func _draw():
	draw_line(loc_src_exit, loc_dest_exit, Color(0,1,0, 0.5))

	# test
	#draw_line(get_child(0).get_position(), loc_src_exit, Color(0,0,1))

	draw_circle(loc_src_extended, 1.0, Color(0,0,1))
	draw_circle(loc_dest_extended, 1.0, Color(0,1,0))
	
	draw_line(loc_src_exit, loc_src_extended, Color(0,0,1))
	draw_line(loc_src_extended, loc_dest_extended, Color(0,0,1))
	draw_line(loc_dest_extended, loc_dest_exit, Color(0,0,1))
	
	#var arr = [loc_src_exit, loc_src_extended, loc_dest_extended, loc_dest_exit]
	#draw_polyline(arr, Color(0,0,1))

# assume standard rotation for now
func get_src_exit(src, dest):
	var src_exits = src.open_exits
	
	if src_exits.size() < 0:
		print("Error, no exits left")
		return
	
	if abs(dest.get_position().x - src.get_position().x) > abs(dest.get_position().y - src.get_position().y):
		if src_exits.has(src.point_two):
		#if dest.get_position().x < src.get_position().x and src_exits.has("two"):
			print("[src] " + str(src.get_name()) + " " + str(dest.get_name()) + " X rule" )
			
			src_exits.remove(src_exits.find(src.point_two))
			#src_exits.remove(src_exits.find("two"))
			
			return src.point_two
			
		else:
			print("[src] " + str(src.get_name()) + " " + str(dest.get_name()) + " X rule alt")
			src_exits.remove(src_exits.find(src.point_one))
			
			return src.point_one
		
	elif dest.get_position().y > src.get_position().y and src_exits.has(src.point_one):
		print("[src] " + str(src.get_name()) + " " + str(dest.get_name()) + " Y rule")
		
		src_exits.remove(src_exits.find(src.point_one))
		#src_exits.remove(src_exits.find("one"))
		
		return src.point_one
		
	elif src_exits.has(src.point_three):
	#src_exits.has("three"):
	# else
		print("[src] " + str(src.get_name()) + " " + str(dest.get_name()) + " Y rule 2")
		
		src_exits.remove(src_exits.find(src.point_three))
		#src_exits.remove(src_exits.find("three"))
		return src.point_three	

# assume standard rotation for now
func get_dest_exit(src, dest): #, dest_exits):
	var dest_exits = dest.open_exits
	
	print("X abs: " + str(abs(dest.get_position().x - src.get_position().x)))
	print("Y abs: " + str(abs(dest.get_position().y - src.get_position().y)))
	
	
	if dest_exits.size() < 0:
		print("Error, no exits left")
		return
	
	if abs(dest.get_position().x - src.get_position().x) > abs(dest.get_position().y - src.get_position().y):
		if dest_exits.has(dest.point_three):
		#if dest.get_position().x < src.get_position().x and dest_exits.has("one"):
			print("[dest] " + str(src.get_name()) + " " + str(dest.get_name()) + " X rule")
			
			dest_exits.remove(dest_exits.find(dest.point_three))
			#dest_exits.remove(dest_exits.find("three"))
			
			return dest.point_three
		
		else:
			print("[dest] " + src.get_name() + " " + dest.get_name() + " replacement for X rule")
			
			dest_exits.remove(dest_exits.find(dest.point_one))
			#dest_exits.remove(dest_exits.find("one"))
			
			return dest.point_one
			
		#dest_exits.remove(dest_exits.find("one"))
		
		#return dest.point_one
	
	elif dest.get_position().y > src.get_position().y:
		if dest_exits.has(dest.point_three):
		#if dest_exits.has("three"):
			print("[dest] " + str(src.get_name()) + " " + str(dest.get_name()) + " Y rule")
			
			dest_exits.remove(dest_exits.find(dest.point_three))
			#dest_exits.remove(dest_exits.find("three"))
			
			return dest.point_three
		
		else:
			print("[dest] " + src.get_name() + " " + dest.get_name() + " replacement for Y rule")
			
			dest_exits.remove(dest_exits.find(dest.point_two))
			#dest_exits.remove(dest_exits.find("two"))
			
			return dest.point_two
		
	elif dest_exits.has(dest.point_one):	
	#elif dest_exits.has("one"):
	#else:
		print("[dest] " + str(src.get_name()) + " " + str(dest.get_name()) + " Y rule 2")
		
		dest_exits.remove(dest_exits.find(dest.point_one))
		#dest_exits.remove(dest_exits.find("one"))
		
		return dest.point_one
