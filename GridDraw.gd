extends Control

var vertices=[]
var elements=[]

enum ELEMENT_TYPE {Line=3,
	Triangle=5,
	Quadrilateral=9,
	Tetrahedral=10
	Hexahedral=12
	Prism=13
	Pyramid=14
}

func pack(x,y,size):
	return x*size+y

func _ready():
	gen_mesh(4)
	
func gen_mesh(size,simple=false):
	if simple:
		gen_mesh_simple_grid(size)
	else:
		gen_mesh_grid(size)

class space_databse:
	var area:Rect2
	var resolutin:Vector2 # shuld be of int
	var array=[]
	
	func _init(scale:float,res:int):
		area = Rect2( Vector2(-scale,-scale),Vector2(scale,scale) )
		resolutin = Vector2(res,res)
		#print("RES=",res)
		for backet in range(floor(resolutin.y)*floor(resolutin.x)):
			array.append([])
		
	func _pos2id(p:Vector2):
		#print("pos2id(",p,",",area,",",resolutin,")")
		
		var inverse_scale = Transform2D( Vector2(1.0/area.size.x,0),Vector2(1.0/area.size.y,0),Vector2.ZERO)
		var local = inverse_scale*(p-area.position)
		return floor(local.x*resolutin.x)+floor(local.y*resolutin.y)*floor(resolutin.x)
		
	func add(element,pos):
		array[_pos2id(pos)].append([pos,element])
	
	func get_bucket(pos):
		return array[_pos2id(pos)] 
	
	func query(pos):
		#print("Quring pos=",pos)
		#print(array)
		for entry in get_bucket(pos):
			if entry[0]==pos:
				return entry[1]
		return null

func on_null(maby_null,on_null):
	if maby_null==null:
		return on_null
	else:
		return maby_null



func gen_mesh_grid(size):
	vertices = []
	elements = []
	var data=space_databse.new(size*100.0+200.0,2+floor(sqrt(size)))
	for i_x in range(size-1):
		for i_y in range(size-1):
			if (i_x-size)*(i_x-size)+(i_y-size)*(i_y-size)<size*size:
				var shape = []
				for extra_xy in [[0,0],[1,0],[1,1],[0,1]]:
					shape.append(
						Vector2(
							(i_x+extra_xy[0])*50.0,
							(i_y+extra_xy[1])*50.0
							)+Vector2(100.0,100.0))
					
				var element=[ELEMENT_TYPE.Quadrilateral]
				for point in shape:
					var id=data.query(point)
					if id==null:
						data.add(vertices.size(),point)
						id=vertices.size()
						vertices.append(point)
						
					element.append(id)
				elements.append(element)
	print(data.array)
			
func gen_mesh_simple_grid(size):
	vertices = []
	elements = []
	for i_x in range(size):
		for i_y in range(size):
			var pos = Vector2(i_x*50.0,i_y*50.0)+Vector2(100.0,100.0)
			assert( pack(i_x,i_y,size)==vertices.size() ) #test if element is going to be appended with predictable id
			vertices.append(pos)
	for i_x in range(size-1):
		for i_y in range(size-1):
			var element = [ELEMENT_TYPE.Quadrilateral,pack(i_x,i_y,size),pack(i_x+1,i_y,size),
													pack(i_x+1,i_y+1,size),pack(i_x,i_y+1,size)]
			elements.append(element)

func _draw_example():
	draw_polygon(PoolVector2Array([Vector2(100.0,100.0),
									Vector2(200.0,100.0),
									Vector2(150.0,200.0),
								]),PoolColorArray([
									Color.red,
									Color.red,
									Color.black,
								]))

#we use cached random color for drawing
func cached(cache:Dictionary,id,value):
	if id in cache.keys():
		return cache[id]
	else:
		cache[id]=value
		return value

var id_2color={}
func _draw():
	for e_id in range(elements.size()):
		var e=elements[e_id]
		if e[0]==ELEMENT_TYPE.Quadrilateral:
			var color=cached(id_2color,e_id,Color(randf(),randf(),randf()))
			draw_polygon(PoolVector2Array([vertices[e[1]],
					vertices[e[2]],
					vertices[e[3]],
					vertices[e[4]],
						]),
						PoolColorArray([
							color,
							color,
							color,
							color,
						])
			)
			



func _on_Button_pressed():
	gen_mesh($"../setings/SpinBox".value)
	update()
