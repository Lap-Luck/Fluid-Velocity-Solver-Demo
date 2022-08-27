extends Node

export(NodePath) var grid
onready var n_grid:GridContainer=get_node(grid)

var map=[]
const MAP_DEBUG=false
var near_ceils={}
var global_ceils_id={}
var ceils_cont=0



func parse_map():
	for x in range(5):
		for y in range(5):
			var res=[]
			if x>0:
				if map[y][x-1]:
					res.append([x-1,y])
			if x<5-1:
				if map[y][x+1]:
					res.append([x+1,y])
			if y>0:
				if map[y-1][x]:
					res.append([x,y-1])
			if y<5-1:
				if map[y+1][x]:
					res.append([x,y+1])
			near_ceils[[x,y]]=res
			global_ceils_id[[x,y]]=ceils_cont  # id is equal to nuber of ceil befor given
			if map[y][x]:
				ceils_cont+=1

func show_arrow(x:int,y:int,v:Vector2,s:float):
	var p=n_grid.get_child(y*5+x)
	var new_arrow=$SimpleArrow.duplicate()
	#new_arrow.get_parent().remove_child(new_arrow) not neded
	p.add_child(new_arrow)
	new_arrow.global_position=p.get_global_rect().position+p.get_global_rect().size*0.5
	new_arrow.visible=true
	new_arrow.look_at(1000000.0*Vector2(-v.y,-v.x))
	new_arrow.scale=Vector2(s,s)

func _ready():
	for y in range(5):
		map.append([])
		for x in range(5):
			var g_ceil:Node=n_grid.get_child(y*5+x)
			map[y].append(not Tools.has_child_named(g_ceil,"Obstacle"))
	parse_map()
	
	if MAP_DEBUG:
		var map_t=""
		for y in range(5):
			for x in range(5):
				map_t+="*"if map[y][x] else "#"
				map_t+=" "
			map_t+="\n"
		print(map_t)
	
	if false:
		var m=Tools.Matrix.new(5)
		for i in range(5):
			m.set_value(i,i,10.0)
		m.set_value(0,1,1.0)
		print(m)
		m.inverse()
		print(m)

var solve_res=[]

var flow_x
var flow_y

func solve():
	assert(ceils_cont==24)
	assert(map[0][0]==true)
	var m=Tools.Matrix.new(24)
	
	#Very ceil has spash(preshure) it is amount of staf sent to its nerboiurs
	#We solve equation system besed on SPASH_FROM_OTHERS-OWN_SPASH=EXTERNAL_INGOING_MATTER
	#at begging EXTERNAL_INGOING_MATTER is positive in (3,2)
	#and EXTERNAL_INGOING_MATTER is negative in (4,2)
	
	#first equation 
	#in order for this equation to be solvabe(as matrix inverse),
	#
	var equations_value=Tools.pool_of_zeros(24)
	
	var equation_id=0
	m.set_value(global_ceils_id[[0,0]],equation_id,1.0)
	equations_value[equation_id]=0.0
	for x in range(5):
		for y in range(5):
			if x==0 and y==0: continue
			if not map[y][x]: continue
			equation_id+=1
			m.set_value(global_ceils_id[[x,y]],equation_id,-1.0)
			for near in near_ceils[[x,y]]:
				var near_near_count=near_ceils[near].size()
				if near_near_count==0:
					print("Error no conncted to:",near)
					assert(false)
				m.set_value(global_ceils_id[near],equation_id,1.0/float(near_near_count))
			equations_value[equation_id]=0.0
			if [x,y]==[1,2]:
				equations_value[equation_id]=10.0
			if [x,y]==[1,3]:
				equations_value[equation_id]=-10.0
			if [x,y]==[0,2]:
				equations_value[equation_id]=10.0
			if [x,y]==[0,3]:
				equations_value[equation_id]=-10.0
	print("Created equation")
	print(m)
	print("*UNKOWN=",equations_value)
	print("trying to solve....")
	var back_d=m.data
	m.inverse()

	#print(m)
	var solution=m.mul(equations_value)
	print(solution)
	m.data=back_d
	print("equation check")
	print(m.mul(solution))
	print("????????")
	
	flow_y=Tools.create_num_array(6,5)
	flow_x=Tools.create_num_array(5,6)
	
	#flow_y=[
	#[<from 0,0 up>,<from 0,1 up>,<from 0,2 up>,...]
	#[<from 1,0 up>,<from 1,1 up>,<from 1,2 up>,...]
	#...
	#[<from 4,0 up>,<from 4,1 up>,<from 4,2 up>,...]
	#[<from 5,0 up>,<from 5,1 up>,<from 5,2 up>,...]
	
	#given begining flow
	var flow_from_3_1_down=-10.0
	flow_y[3][1]=flow_from_3_1_down
	var flow_from_3_0_down=-10.0
	flow_y[3][0]=flow_from_3_0_down
	
	#up flow from splash
	for y in range(6):
		for x in range(5):
			if y==0:
				flow_y[y][x]+=0.0
				continue
			if y==5:
				flow_y[y][x]+=0.0
				continue
			var splash_up=solution[global_ceils_id[[x,y-1]]]/float(near_ceils[[x,y-1]].size())
			var splash_down=solution[global_ceils_id[[x,y]]]/float(near_ceils[[x,y]].size())
			flow_y[y][x]+=splash_down-splash_up if map[y][x] and map[y-1][x] else 0.0# this is transfer of water upwards
	
	#right flow from splash
	for x in range(6):
		for y in range(5):
			if x==0:
				flow_x[y][x]+=0.0
				continue
			if x==5:
				flow_x[y][x]+=0.0
				continue
			var splash_left=solution[global_ceils_id[[x-1,y]]]/float(near_ceils[[x-1,y]].size())
			var splash_right=solution[global_ceils_id[[x,y]]]/float(near_ceils[[x,y]].size()) 
			flow_x[y][x]+=splash_left-splash_right if map[y][x] and map[y][x-1] else 0.0# this is transfer of water upwards

	var res_vel=Tools.create_num_array(5,5)
	for x in range(5):
		for y in range(5):
			var res:Vector2=Vector2.ZERO
			if true:#map[y][x]:
				res.x=(flow_x[y][x]+flow_x[y][x+1])*0.5
				res.y=(flow_y[y][x]+flow_y[y+1][x])*0.5
			res_vel[x][y]=res
	
	#print("###############")
	#print(res_vel)
	#print(flow_x)
	#print(flow_y)
	solve_res=res_vel
	#assert(false)

func _on_PlayButton_pressed():
	solve()
	$SimpleArrow.visible=false
	$SimpleArrow2.visible=false
	#print("map")
	#print(map)
	for x in range(5):
		for y in range(5):
			if map[y][x]:
				var v:Vector2=solve_res[x][y]
				if v.length()>0.0001:
					if false:
						if v.length()>1.0:
							show_arrow(x,y,v.normalized(),1.2)
						elif v.length()>0.1:
							show_arrow(x,y,v.normalized(),v.length()*0.5+0.5)
						elif v.length()>0.01:
							show_arrow(x,y,v.normalized(),v.length()*4.0+0.1)
						else:
							show_arrow(x,y,v.normalized(),0.1)
					else:
						show_arrow(x,y,v.normalized(),v.length()/4.0)
			else:
				var v:Vector2=solve_res[x][y]
				if v.length()>0.1:
					assert(false)
				#show_arrow(x,y,Vector2(1.0,-1.0),0.5)
	moves=true
	
func get_flow(x:float,y:float):
	if x<0.0 or x>5.0:
		return Vector2.ZERO
	if y<0.0 or y>5.0:
		return Vector2.ZERO
	var x_id=int(floor(x))
	var y_id=int(floor(y))
	print("@",x_id,",",y_id)
	n_grid.get_child(y_id*5+x_id).rect_rotation=10.0
	var f_x_1=flow_x[y][x]
	var f_x_2=flow_x[y][x+1]
	var f_y_1=flow_y[y][x]
	var f_y_2=flow_y[y+1][x]
	return Vector2( -1.0*f_y_1-f_y_2,-1.0*f_x_1-f_x_2)
	
var moves=false
func _process(delta):
	if moves:
		if false:
			for i in range(10):
				$Icon.global_position+=delta*get_flow(($Icon.global_position.x-75.0)*0.01,($Icon.global_position.y-75.0)*0.01)*2.0

	
	#show_arrow(1,1,Vector2(1.0,0.0),0.2)
	#show_arrow(0,0,Vector2(0.0,1.0),0.4)

