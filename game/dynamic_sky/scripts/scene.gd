extends Spatial

var iTime=0.0
var iFrame=0
var env = null

# the part here originally based on a script by Khairul Hidayat, https://www.youtube.com/watch?v=iTkLEP3Kwko

#export var SPEED = 20.0;
var DAY_SPEED = 10; # in real-time minutes

var trigger_count = 0
#const UPDATE_TIME = 1/30.0;

export var start_time = 8.0

var prev_time = 0.0
var time = 0.0;
var delay = 0.0;

var hour = 0
var minute = 0

var light

export var day_night = true

var sun = null
var sunmoon_angle
var sunmoon_lat
var sky = null
var clouds = null

# colors
var light_color
var ambient_color
var sky_color
var horizon_color
var gr_horizon_color
var cloud_tint
var cloud_tint_dist

var night_fired = false

# weather

export(int) var weather = 0
# we can't init it on ready because it relies on our own setup
var state = null #WeatherSunny.new(self)
var prev_state

const WEATHER_SUNNY = 0
const WEATHER_OVERCAST = 1
const WEATHER_RAIN = 2

signal state_changed

var player


func _ready():
	
	time = start_time;
	prev_time = start_time;
	delay = 0.0;
	
	#target 60 fps
	Engine.set_target_fps(60)
	
	sun = get_parent().get_node("DirectionalLight")
	env = get_parent().get_node("WorldEnvironment").get_environment()
	#sky = env.get_sky()
	sky = get_node("Sky/Node2D/sky_rect")
	clouds = get_node("Sky/Node2D/Sprite2")
	
	#print("Real-life minutes/day is: " + str(DAY_SPEED) + ", 1 h is: " + str((DAY_SPEED/24.0)*60.0) + " s")
	
	player = get_tree().get_nodes_in_group("player")[0]
	
	trigger_count = 2
	
	sunset_color()
	
	# set weather
	call_deferred("set_state", weather)

func sunset_color():
	# random sunset color
	# seed the rng
	randomize()
	var ran = randf()

	if ran < 0.2:
		# red
		sky.set_sun_color(Color(1.0, 0.05, 0.0, 0.75))
		print("Selected red sunset")
	else:
		# yellow
		sky.set_sun_color(Color(1.0, 0.75, 0.0, 0.75))
		print("Selected yellow sunset")

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	iTime+=delta
	iFrame+=1

	# real-time
	#real_s_per_hour = (DAY_SPEED/24.0)*60.0
	#real_s_per_min = (DAY_SPEED/24.0) # because real_s_per_hour/60.0

	# set previous time
	prev_time = time
	
	# passage of time
	# delta = amount of seconds
	
	#time += delta/real_s_per_hour
	time += delta/((DAY_SPEED/24.0)*60.0)

	#time += 1/60.0*SPEED*delta;
	# time is measured in in-game hours
	if time >= 24.0:
		time -= 24.0;
	
	#update
#	delay -= delta;
#	if delay > 0.0:
#		return;
#	delay = UPDATE_TIME
	
	# set hours and minutes
	hour = floor(time)
	minute = (time - floor(time))*60
	
	if day_night:
		# throttle the updates
		if trigger_count > 0:
			trigger_count -= 1
			if trigger_count == 0:
				day_night_cycle(time)
				trigger_count = 15
		
	# TODO: weather should be a fsm and effects should be applied only on weather change
	# weather
#	if weather == WEATHER_SUNNY:
#		player.get_node("BODY/skysphere/Skysphere").get_material_override().set_shader_param("cloud_cover", 25)
#	elif weather == WEATHER_OVERCAST or weather == WEATHER_RAIN:
#		player.get_node("BODY/skysphere/Skysphere").get_material_override().set_shader_param("cloud_cover", 85)
	
#	if weather == WEATHER_RAIN:
#		rain()
#	else:
#		no_rain()

# day/night cycle
func calculate_lightning(hour, minute):
	var lightningMin = 0.1
	var lightningMax = 1.0
	var time = (hour + (minute / 60.0)) / 24.0
	var light = lightningMax * sin(PI*time)
	return clamp(light, lightningMin, lightningMax)

func calculate_rotation(time):
	# fraction of 24h
	var fraction = time/24.0
	# inverted fraction
	var inv_fraction = 1.0-fraction
	var angle_midnight = 200 # this * 0.5 = ~90, fudged it for the shadows to be more noticeable in the morning/afternoon
	# set the angle in radians
	var angle = deg2rad(-(angle_midnight*inv_fraction))
	return angle
	
func calculate_sun_latitude(time):
	var lat_sunset = 180
	var lat_night = -40
	var latitude
	
	# fraction of daytime (from 6 to 18)
	var time_since_day = time-6
	if time_since_day > 0 and time < 20:
		var fraction_daytime = time_since_day/12.0
		latitude = (lat_sunset*fraction_daytime)
	elif time_since_day < 0 or time >= 20:
		latitude = lat_night
	
	
	return latitude

func calculate_sun_height(time):
	# so that the lowest points are at 6h and 18h
	var sun_height = clamp(1-sin((time-6.0)/4.0), 0.0, 1.0)
	
	if time> 18.5:
		sun_height = 1.4 # below the horizon
	
	var sun_lat = 0.85 # west
	if time > 12:
		sun_lat = 0.15 # east
	
	return Vector2(sun_lat, sun_height)
	
func get_light_color(time):
	if time >= 18.4 && time < 18.5:
		# sunset
		light_color = Color(1,0.75,0)
	elif time >= 18.5 && time < 18.7:
		var d = (time-18.5)/0.5;
		# 0.303474,0.375416,0.627212
		light_color = Color(1-((1-42/255.0)*d), 1-((1-64/255.0)*d), 1-((1-141/255.0)*d));
		
		#print(str(light_color))
	elif time >= 6.0 && time < 6.5:
		var d = (time-5.5)/0.5;
		light_color = Color((42/255.0)+((1-42/255.0)*d), (64/255.0)+((1-64/255.0)*d), (141/255.0)+((1-141/255.0)*d));
	elif time >= 18.7 or time < 5.5:
		light_color = Color(42/255.0, 64/255.0, 141/255.0);
	else:
		light_color = Color(1,1,1)
	
	#print("Time: " + str(time) + " " + str(light_color))
	
	return light_color

func get_light_energy(time):
	var lit = light
	if time >= 6.0 && time < 6.5:
		lit = lit * 0.5
	
	elif time >= 18.5 && time < 19.5:
		lit = lit * 0.5
	else:
		lit = lit
		
	return lit
	
func set_colors(time):
	light_color = get_light_color(time)	
		
	sun.set_color(light_color)
	
	ambient_color = Color(169/255.0*light, 189/255.0*light, 242/255.0*light);
	
	# set ambient light colors
	env.set_ambient_light_color(ambient_color)
	env.set_ambient_light_energy(0.2+(0.2*get_light_energy(time)))
	
	# set sky colors
	# default sky color used to be 12, 116, 249
	# 165, 214, 240
	#sky_color = Color(165/255.0*light, 214/255.0*light, 240/255.0*light)
	# default horizon color is 142, 210, 232
	horizon_color = Color(142/255.0*light, 210/255.0*light, 232/255.0*light)
	# detault ground horizon color is 123, 201, 243
	# 107, 100, 94
	#gr_horizon_color = Color(107/255.0*light, 100/255.0*light, 94/255.0*light)
	
	
	#sky.set_sky_top_color(sky_color)
	#sky.set_sky_horizon_color(horizon_color)
	#sky.set_ground_horizon_color(gr_horizon_color)	
	env.set_fog_color(horizon_color)

func set_clouds(time):
	if time >= 18.1 && time < 18.5:
		# sunset
		cloud_tint = Color(0.8,0.2,0.1, 0.35)
		cloud_tint_dist = 6.4
	else:
		cloud_tint = Color(1.0, 1.0, 1.0, 0.0)
		cloud_tint_dist = 6.4
	
	return [cloud_tint, cloud_tint_dist];

func day_night_cycle(time):
	#print(str(time))
	sunmoon_angle = calculate_rotation(time)
	sun.set_rotation(Vector3(sunmoon_angle, 0, 0))
	sunmoon_lat = calculate_sun_height(time)
	#sunmoon_lat = calculate_sun_latitude(time)
	
	light = calculate_lightning(hour, minute);
	sun.set_param(Light.PARAM_ENERGY, light);
	
	set_colors(time)
	
	if time >= 5.5 and time <= 19.0:
		# set sun latitude
		sky.set_sun(sunmoon_lat)
		var cloud_data = set_clouds(time)
		clouds.set_cloud_tint(cloud_data[0])
		#sky.set_sun_latitude(sunmoon_lat)		
	
	if time >= 5.5 && time < 6.0:
		night_fired = false
		# stuff done slightly before sunrise
		get_tree().get_nodes_in_group("roads")[0].reset_lite()
		#get_tree().call_group("roads", "reset_lite")
		#re-enable shadows
		#sun.set_shadow(true)
		
		env.background_energy = 1
	if time >= 18.4 && time < 18.5:
		get_node("Sky")._trigger_update_sky()
		
	elif time >= 18.5 && not night_fired:

		
		#disable shadows
		#sun.set_shadow(false)
		get_tree().get_nodes_in_group("roads")[0].lite_up()
		# so that emissives light effect is better visible
		env.background_energy = 0.1
		print("[DAYNIGHT] switch to night settings")
		night_fired = true
		

	

	
	#env.set_background_param(Environment.BG_PARAM_COLOR, col);

# weather
func rain():
	player.get_node("BODY/RainParticles").set_emitting(true)
	player.get_node("BODY/RainParticles2").set_emitting(true)
	
	# enable SSR
	env.set_ssr_enabled(true) 
	
	if get_tree().get_nodes_in_group("roads").size() > 0:
		get_tree().get_nodes_in_group("roads")[0].rain_shine()
		
	player.get_node("BODY/proc_mesh").rain_glass()

func no_rain():
	env.set_ssr_enabled(false)
		
	player.get_node("BODY/RainParticles").set_emitting(false)
	player.get_node("BODY/RainParticles2").set_emitting(false)
	if get_tree().get_nodes_in_group("roads").size() > 0:
		get_tree().get_nodes_in_group("roads")[0].no_rain()

	# car glass
	player.get_node("BODY/proc_mesh").rain_clear()

func overcast():
	# in percent
	clouds.set_coverage(70)
	
func normal_sky():
	clouds.set_coverage(50)
	
# fsm
func set_state(new_state):
	# if we need to clean up
	#state.exit()
	if state != null:
		prev_state = get_state()
	
	if new_state == WEATHER_SUNNY:
		state = WeatherSunny.new(self)
	elif new_state == WEATHER_OVERCAST:
		state = WeatherOvercast.new(self)
	elif new_state == WEATHER_RAIN:
		state = WeatherRain.new(self)
	
	emit_signal("state_changed", self)

func get_state():
	if state is WeatherSunny:
		return WEATHER_SUNNY
	elif state is WeatherOvercast:
		return WEATHER_OVERCAST
	elif state is WeatherRain:
		return WEATHER_RAIN
		
# states ----------------------------------------------------

class WeatherSunny:
	var world
	
	func _init(wd):
		world = wd
		# weather init
		world.no_rain()
		world.normal_sky()

class WeatherOvercast:
	var world
	
	func _init(wd):
		world = wd
		# weather init
		world.no_rain()
		world.overcast()
		
class WeatherRain:
	var world
	
	func _init(wd):
		world = wd
		# weather init
		world.rain()
		world.overcast()


# from danilw
func steep_scb(value):
	pass # Replace with function body.

func _on_Sky_sky_updated():
	$Sky.copy_to_environment(env)
