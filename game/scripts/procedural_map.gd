tool
extends "connect_intersections.gd"

# class member variables go here, for example:
var intersects
var mult

var edges = []
var samples = []
var as

var nav
#var tris = []

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here

	mult = get_node("triangulate/poisson").mult

	intersects = preload("res://roads/intersection.tscn")

	samples = get_node("triangulate/poisson").samples

	for i in range(0, get_node("triangulate/poisson").samples.size()-1):
		var p = get_node("triangulate/poisson").samples[i]
		var intersection = intersects.instance()
		intersection.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))
		intersection.set_name("intersection" + str(i))
		add_child(intersection)

	# get the triangulation
	var tris = get_node("triangulate").tris

	for t in tris:
		#var poly = []
		#print("Edges: " + str(t.get_edges()))
		for e in t.get_edges():
			edges.append(e)

	# create the map
	for i in range(0, edges.size()):
		var ed = edges[i]
		#print("Connecting intersections for edge: " + str(i) + " 0: " + str(ed[0]) + " 1: " + str(ed[1]))
		var p1 = samples[ed[0]]
		var p2 = samples[ed[1]]
		# +1 because of the poisson node that comes first
		connect_intersections(ed[0]+2, ed[1]+2)


	setup_neighbors()

	var marker_data = spawn_markers()

	# test
	var roads_start_id = 2+5 # 2 helper nodes + 5 intersections

	nav = AStar.new()
	var pts = []
	var begin_id = 0
	#var path_data = []
	var path_look = {}
	for i in range(roads_start_id, roads_start_id+4):
		var data = setup_nav_astar(pts, i, begin_id)
		#print('Begin: ' + str(begin_id) + " end: " + str(data[0]) + " inters: " + str(data[1]))
		#path_data.append([data[1], [begin_id, data[0]]])
		path_look[data[1]] = [begin_id, data[0]]
		# just in case, map inverse too
		path_look[[data[1][1], data[1][0]]] = [data[0], begin_id]

		# increment begin_id
		begin_id = data[0]

	print(path_look)
	
	#print(path_data)
	# test
	#for i in range(path_data.size()):
	#	print(str(i) + ", " + str(path_data[i]))
	

	# test the nav
	# marker is the last child
	var marker = get_child(get_child_count()-1)
	#print(marker.get_translation())
	var tg = marker.target
	#print("tg : " + str(tg))

#	print("Marker intersection id" + str(marker_data[0]) + " tg id" + str(marker_data[1]))
	var int_path = as.get_id_path(marker_data[0], marker_data[1])
	print("Intersections path" + str(int_path))
	
	#print("First pair: " + str(int_path[0]) + "," + str(int_path[1]))
	var lookup_path = path_look[[int_path[0], int_path[1]]]
	#print("Lookup path pt1: " + str(lookup_path))
	var nav_path = nav.get_point_path(lookup_path[0], lookup_path[1])
	print("Nav path: " + str(nav_path))
	# so that the player can see
	marker.raceline = nav_path
	
	#print("Second pair: " + str(int_path[1]) + "," + str(int_path[2]))
	lookup_path = path_look[[int_path[1], int_path[2]]]
	#print("Lookup path pt2: " + str(lookup_path))
	var nav_path2 = nav.get_point_path(lookup_path[0], lookup_path[1])
	#print("Nav path pt2 : " + str(nav_path2))
	
	var nav_path3
	if int_path.size() > 3:
		#print("Third pair: " + str(int_path[2]) + "," + str(int_path[3]))
		lookup_path = path_look[[int_path[2], int_path[3]]]
		#print("Lookup path pt3: " + str(lookup_path))
		nav_path3 = nav.get_point_path(lookup_path[0], lookup_path[1])
		#print("Nav path pt3: " + str(nav_path3))

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func setup_nav_astar(pts, i, begin_id):
	print(get_child(i).get_name())
	
	# extract intersection id's
	var sub = get_child(i).get_name().substr(5, 3)
	var nrs = sub.split("-")
	#print(nrs)
	
	var ret = []
	for i in nrs:
		ret.append(int(i)-2)
		
	#print(ret)
	
	#print(get_child(i).get_translation())
	
	var turn1 = get_child(i).get_node("Road_instance0").get_child(0).get_child(0)
	var turn2 = get_child(i).get_node("Road_instance1").get_child(0).get_child(0)

	#print("Straight positions: " + str(get_child(i).get_node("Spatial0").get_child(0).positions))
	#print("Turn 1 positions: " + str(turn1.positions))
	#print("Turn 2 positions: " + str(turn2.positions))

	#print("Turn 1 global pos: " + str(turn1.get_global_transform().origin))
	#print("Turn 2 global pos: " + str(turn2.get_global_transform().origin))

	# from local to global
	for p in turn1.positions:
		#pts.append(turn1.get_global_transform().xform(p))
		pts.append(turn1.to_global(p))
	for p in turn2.positions:
		#pts.append(turn2.get_global_transform().xform(p))
		pts.append(turn2.to_global(p))

	# add pts to nav (road-level AStar)
	for i in range(pts.size()):
		nav.add_point(i, pts[i])

	# connect the points
	# because of i+1
	for i in range(begin_id, begin_id + turn1.positions.size()-1):
		nav.connect_points(i, i+1)

	for i in range(begin_id + turn1.positions.size(), begin_id + turn1.positions.size()+turn2.positions.size()-1):
		nav.connect_points(i, i+1)

	# connect the endpoints
	nav.connect_points(begin_id + turn1.positions.size()-1, begin_id + turn1.positions.size())

	# test
	var endpoint_id = begin_id + turn1.positions.size()+turn2.positions.size()-3
	#print("Endpoint id " + str(endpoint_id))
	#print("Test: " + str(nav.get_point_path(begin_id, endpoint_id)))
	return [endpoint_id, ret]




#-------------------------
# Distance map

func setup_neighbors():
	# we'll use AStar to have an easy map of neighbors
	as = AStar.new()
	for i in range(0,samples.size()-1):
		as.add_point(i, Vector3(samples[i][0]*mult, 0, samples[i][1]*mult))

	for i in range(0, edges.size()):
		var ed = edges[i]
		as.connect_points(ed[0], ed[1])

# yes it could be more efficient I guess
func bfs_distances(start):
	# keep track of all visited nodes
	#var explored = []
	var distance = {}
	distance[start] = 0

	# keep track of nodes to be checked
	var queue = [start]

	# keep looping until there are nodes still to be checked
	while queue:
		# pop shallowest node (first node) from queue
		var node = queue.pop_front()
		print("Visiting... " + str(node))

		var neighbours = as.get_point_connections(node)
		# add neighbours of node to queue
		for neighbour in neighbours:
			# if not visited
			#if not explored.has(neighbour):
			if not distance.has(neighbour):
				queue.append(neighbour)
				distance[neighbour] = 1 + distance[node]


	return distance


#-------------------------

func spawn_markers():
	var spots = []

	var mark = preload("res://objects/marker.tscn")
	var sp_mark = preload("res://objects/speed_marker.tscn")

	# random choice of an intersection to spawn at
	# trick to copy the array
	spots = [] + samples
	spots.pop_back() # we don't want the last entry
	var num_inters = spots.size()
	var id = randi() % num_inters
	var p = spots[id]

	var sp_marker = sp_mark.instance()
	sp_marker.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))
	add_child(sp_marker)

	# remove from list of possible spots
	spots.remove(id)

	# random choice of an intersection to spawn at
	id = randi() % spots.size()
	p = spots[id]
	var marker = mark.instance()
	marker.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))

	# create a distance map from our intersection
	# because the spots map can have different id from the samples
	var m_id = samples.find(p)
	var distance_map = bfs_distances(m_id)
	print(str(distance_map))
	#print("Keys: " + str(distance_map.keys()))
	#print("Values: " + str(distance_map.values()))

	# pick a target
	var possible_targets = []
	for n in distance_map.keys():
		var v = distance_map[n]
		if v > 1:
			print("Possible target id: " + str(n))
			possible_targets.append(n)

	var t_id = null
	if possible_targets.size() > 1:
		# pick randomly
		t_id = possible_targets[randi() % possible_targets.size()]
	else:
		t_id = possible_targets[0]

	print("Target id: " + str(t_id))

	marker.target = Vector3(samples[t_id][0]*mult, 0, samples[t_id][1]*mult)
	print("Marker target is " + str(marker.target))

	add_child(marker)
	return [m_id, t_id]
