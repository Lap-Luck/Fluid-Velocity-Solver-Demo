extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const GRID_SIZE=32
#GRID_SIZE is power of 2. it shoud allow for easier multigrid method implementation
var grid32=[]

func init_grid():
	for x in range(GRID_SIZE):
		grid32.apped([])
		for y in range(GRID_SIZE):
			grid32[-1].apped(0)

func register_grid(x:int,y:int):
	self.grid32[x][y]=1

func neibour_ids(x:int,y:int):
	var res=[]
	res.append_array([[x+1,y]] if x+1 in range(32) else [])
	res.append_array([[x-1,y]] if x-1 in range(32) else [])
	res.append_array([[x,y+1]] if y+1 in range(32) else [])
	res.append_array([[x,y-1]] if y-1 in range(32) else [])
	return res

func query_grid(x:int,y:int):
	neibour_ids(x,y)

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
	
	if true:
		for x in range(1,20+1):
			tab[x]={}
			for y in range(1,20+1):
				tab[x][y]=add_ceil(x,y,Color(256,0,0))
		add_ceil(1,1,Color(0,0,0),20,20)

func add_fluid(x:int,y:int,v:float):
	tab[x][y].fill_value+=v
	if tab[x][y].fill_value>1.0:
		var overflow=tab[x][y].fill_value-1.0
		print("overflow=",overflow)
		tab[x][y].fill_value=1.0
		var near=neibour_ids(x,y)
		if overflow>0.01:
			for n in near:
				add_fluid(n[0],n[1],overflow/near.size())
	tab[x][y].fill(tab[x][y].fill_value)

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
