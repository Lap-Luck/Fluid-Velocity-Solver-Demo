extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const GRID_SIZE=32
#GRID_SIZE is power of 2. it shoud allow for easier multigrid method implementation
var grid32=[]

func init_grid():
	for x in range(GRID_SIZE):
		grid32.append([])
		for y in range(GRID_SIZE):
			grid32[-1].append(0)

func register_grid(x:int,y:int):
	self.grid32[x][y]=1

func neibour_size(x:int,y:int):
	return 4-int(x>=32)-int(x<0)-int(y>=32)-int(y<0)
	
func neibour_ids(x:int,y:int,as_vec=false):
	var res=[]
	res.append_array([[x+1,y]] if x+1 in range(32) else [])
	res.append_array([[x-1,y]] if x-1 in range(32) else [])
	res.append_array([[x,y+1]] if y+1 in range(32) else [])
	res.append_array([[x,y-1]] if y-1 in range(32) else [])
	if as_vec:
		var res_v=[]
		for r in res:
			res_v.append(Vector2(r[0],r[1]))
		return res_v
	return res

func query_grid(x:int,y:int,query)->Array:
	match query:
		"FULL":
			#var work=0
			var visted=[]
			var history=[]
			var to_vist=[Vector2(x,y)]
			while not to_vist.empty():
				#history.append(to_vist.duplicate(true))
				var place=to_vist.pop_back()
				#work+=1
				#if work==100:
				#	assert(false)
				visted.append(place)
				var nears=neibour_ids(place[0],place[1],true)
				for n in nears:
					if not visted.find(n)>=0:
						if not to_vist.find(n)>=0:
							if tab[int(n[0])][int(n[1])].fill_value>=1.0:
								to_vist.append(n)
			#if visted.size()>5:
			#	print("DEBUG")
			#	print(history)
			#	assert(false)
			return visted
		_:
			print("Unimplemented")
			assert(false)
	assert(false)
	return []


func add_ceil(x:int,y:int,color=null,size_x:int=1,size_y:int=1,unit_scale=50.0):
	var new_ceil:Node2D=$ceil.duplicate()
	self.add_child(new_ceil)
	new_ceil.set_shape(Rect2(x*unit_scale,y*unit_scale,size_x*unit_scale,size_y*unit_scale))
	new_ceil.visible=true
	#new_ceil.fill()

	if not color==null:
		new_ceil.set_color(color)
	return new_ceil

var tab:={}
func _ready():
	init_grid()
	if true:
		for x in range(1,20+1):
			tab[x]={}
			for y in range(1,20+1):
				tab[x][y]=add_ceil(x,y,Color(256,0,0))
		add_ceil(1,1,Color(0,0,0),20,20)

func is_overflow(x:int,y:int,var t:float=0.0):
	#is this cell contected to cell that has over 1.0 fill value
	var near_cell=query_grid(x,y,"FULL")
	for c in near_cell:
		if tab[int(c.x)][int(c.y)].fill_value>1.0+t:
			return true
	return false

func normalize_fluid(x:int,y:int):
	var near_xy=query_grid(x,y,"FULL")
	var eqautions:Tools.EquationSystem=Tools.EquationSystem.new()
	for n_id in range(near_xy.size()):
		var e:Tools.Equation=Tools.Equation.new()
		var nx=int(near_xy[n_id].x)
		var ny=int(near_xy[n_id].y)
		e.add(n_id,float(neibour_size(nx,ny)))
		for vec in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
			if near_xy[n_id]+vec in near_xy:
				var n2_id=near_xy.find(near_xy[n_id]+vec)
				e.add(n2_id,-1.0)

		e.value=tab[nx][ny].fill_value-1.0
		eqautions.add(e)
	#print("normalize")
	#print(near_xy)
	#print(eqautions)
	var water_spash:PoolRealArray=raf_solve(eqautions,"JACOBI")
	for n_id in range(near_xy.size()):
		var nx=int(near_xy[n_id].x)
		var ny=int(near_xy[n_id].y)
		var spash=water_spash[n_id]
		tab[nx][ny].fill_value-=spash*neibour_size(nx,ny)
		var near=neibour_ids(nx,ny)
		assert(near.size()==neibour_size(nx,ny))
		for n_xy in near:
			tab[n_xy[0]][n_xy[1]].fill_value+=spash
		
		
func raf_solve(eq,way):
	
	var res
	match way:
		"JACOBI":
			var relaxation=0.1
			
			var m:Tools.Matrix=eq.get_matrix()
			var v:PoolRealArray=eq.get_vector()
			var x:PoolRealArray=Tools.zeros(v.size())
			for try in range(30):
				var err=Tools.vector_sub(m.mul(x),v)
				for i in range(err.size()):
					x[i]-=(1.0-relaxation)*err[i]/m.get_value(i,i)
			res=x
		_:
			assert(false)
	return res
		

func _add_fluid(x:int,y:int,v:float):
	tab[x][y].fill_value+=v
	
func update_fluid():
	for x in range(1,20+1):
		for y in range(1,20+1):
			tab[x][y].fill(tab[x][y].fill_value)

func add_fluid(x:int,y:int,v:float):
	_add_fluid(x,y,v)
	if is_overflow(x,y):
		normalize_fluid(x,y)
	if is_overflow(x,y,0.1):
		normalize_fluid(x,y)
	if is_overflow(x,y,0.1):
		normalize_fluid(x,y)
	update_fluid()
	#if tab[x][y].fill_value>1.0:
		#var overflow=tab[x][y].fill_value-1.0
		#print("overflow=",overflow)
		#tab[x][y].fill_value=1.0
		#var near=neibour_ids(x,y)
		
		
		#if overflow>0.01:
		#	for n in near:
		#		add_fluid(n[0],n[1],overflow/near.size())
	

func click(pos:Vector2):
	var x=int(floor(pos.x/50.0))
	var y=int(floor(pos.y/50.0))
	print("click at ",x,",",y)
	if tab.has(x):
		if tab.has(y):
			#tab[x][y].visible=false
			self.add_fluid(x,y,2.1)
			
	
	#for c in get_children():
	
	#	if c is Node2D:
	#		if c.position==Vector2(x*50.0,y*50.0):
	#			c.visible=false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index==BUTTON_LEFT:
			if event.pressed:
				var pos=get_viewport().get_mouse_position()
				click(pos)
