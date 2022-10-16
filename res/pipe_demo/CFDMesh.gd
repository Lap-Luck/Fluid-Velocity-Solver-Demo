extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var mesh=[]
# Called when the node enters the scene tree for the first time.
class Cell:
	var up:Cell=null
	var down:Cell=null
	var right:Cell=null
	var left:Cell=null
	var x:int=0
	var y:int=0
	var data={}
	var b_up:Dictionary={}
	var b_down:Dictionary={}
	var b_right:Dictionary={}
	var b_left:Dictionary={}
	
class VKT_File:
	var quads=[]
	func draw_quad(a:Vector2,b:Vector2,c:Vector2,d:Vector2,v:Dictionary):
		quads.append([a,b,c,d,v])
	func save(name:String):
		
		var fdata="""# vtk DataFile Version 1.0
2D Unstructured Grid of Linear Triangles
ASCII
DATASET UNSTRUCTURED_GRID\n"""
		
		#save mesh
		fdata+="POINTS "+String(4*quads.size())+" float"+"\n"
		for q in quads:
			for axis in range(4):
				fdata+=String(q[axis].x)+" "+String(q[axis].y)+" "+"0"+"\n"
		fdata+="CELLS "+String(quads.size())+" "+String(5*quads.size())+"\n"
		for id in range(quads.size()):
			fdata+="4 "+String(4*id)+" "+String(4*id+1)+" "+String(4*id+2)+" "+String(4*id+3)+"\n"
		fdata+="CELL_TYPES "+String(quads.size())+"\n"
		for id in range(quads.size()):
			fdata+="9\n"
		fdata+="CELL_DATA "+String(quads.size())+"\n"
		
		#save data
		for key in quads[0][4].keys():
			fdata+="SCALARS "+key+" float\n"
			fdata+="LOOKUP_TABLE default\n"
			for q in quads:
				var value:float=q[4][key]
				fdata+=String(value)+" "
		
		#commit file to OS
		var f=File.new()
		f.open("res://"+name,File.WRITE)
		f.store_string(fdata)
		f.close()

func _ready():
	mesh=$CFD_GRID.tab.duplicate(true)
	#for l in mesh:
	#	print(l)
	
	for x in range(mesh.size()):
		for y in range(mesh[0].size()):
			if mesh[x][y]==-1:
				var c = Cell.new()
				mesh[x][y]=c
	for x in range(mesh.size()):
		for y in range(mesh[0].size()):
			if mesh[x][y] is Cell:
				var c:Cell=mesh[x][y]
				c.up=mesh[x][y+1] if mesh[x][y+1] is Cell else null
				c.down=mesh[x][y-1] if mesh[x][y-1] is Cell else null
				c.right=mesh[x+1][y] if mesh[x+1][y] is Cell else null
				c.left=mesh[x-1][y] if mesh[x-1][y] is Cell else null
				c.x=x
				c.y=y
	for x in range(mesh.size()):
		for y in range(mesh[0].size()):
			if mesh[x][y] is Cell:
				if mesh[x][y].up==null:
					mesh[x][y].b_up=$CFD_GRID.get_b_data(x,y+1)
				if mesh[x][y].down==null:
					mesh[x][y].b_down=$CFD_GRID.get_b_data(x,y-1)
				if  mesh[x][y].right==null:
					mesh[x][y].b_right=$CFD_GRID.get_b_data(x+1,y)
				if  mesh[x][y].left==null:
					mesh[x][y].b_left=$CFD_GRID.get_b_data(x-1,y)
	save()
	print("START")
	simulate()
	print("DONE")
	
onready var RES_X = $CFD_GRID.RES_X
onready var RES_Y = $CFD_GRID.RES_Y
onready var DX = $CFD_GRID.DX
onready var  DY = $CFD_GRID.DY

func _draw():
	for x in range(mesh.size()):
		for y in range(mesh[0].size()):
			if mesh[x][y] is Cell:
				var me=mesh[x][y]
				if me.data.has("p"):
						draw_rect(Rect2(Vector2(x*DX,y*DY),Vector2(DX,DY)),
						Color(me.data["p"]/10.0,0.0,0.0))


func number_of_cells_in_mesh():
	var res=0
	for x in range(mesh.size()):
		for y in range(mesh[0].size()):
			res+=int(mesh[x][y] is Cell)
	return res

func save():
	var f=VKT_File.new()
	for l in mesh:
		for c in l:
			if c is Cell:
				f.draw_quad(Vector2(c.x,c.y),
							Vector2(c.x,c.y+1),
							Vector2(c.x+1,c.y+1),
							Vector2(c.x+1,c.y),
							{"parity":0.0 if (c.x+c.y)%2==0 else 1.0})
	f.save("test.vtk")
	
	

func my_avg(a,b,c,d):
	var sum=0.0
	var count=0.0
	for e in [a,b,c,d]:
		if not e == null:
			sum+=e
			count+=1.0
	return sum/count

func simulate():
	for x in range(mesh.size()):
		for y in range(mesh[0].size()):
			if mesh[x][y] is Cell:
				mesh[x][y].data["p"]=0.0
				mesh[x][y].data["v"]=Vector2.ZERO
	for t in range(100):
		print("Iteration=",t)
		for x in range(mesh.size()):
			for y in range(mesh[0].size()):
				if mesh[x][y] is Cell:
					var me=mesh[x][y]
					#p_xx=avg((p_right-p),(p_left-p))
					#p_yy=avg((p_up-p),(p_down-p))
					#p_xx+p_yy==0
					
					#p=avg(p_right,p_left,p_up,p_down
					#print(me.b_down)
					var p_up=me.up.data["p"] if not me.up==null else (me.b_up["p"] if me.b_up["pb"] else null)
					var p_down=me.down.data["p"] if not me.down==null else (me.b_down["p"] if me.b_down["pb"] else null)
					var p_right=me.right.data["p"] if not me.right==null else (me.b_right["p"] if me.b_right["pb"] else null)
					var p_left=me.left.data["p"] if not me.left==null else (me.b_left["p"] if me.b_left["pb"] else null)
					
					me.data["p"]=me.data["p"]+0.9*(my_avg(p_up,p_down,p_right,p_left)-me.data["p"])
					
					
		print("check:")
		var error=0.0
		for x in range(mesh.size()):
			for y in range(mesh[0].size()):
				if mesh[x][y] is Cell:
					var me=mesh[x][y]
					var p_up=me.up.data["p"] if not me.up==null else (me.b_up["p"] if me.b_up["pb"] else null)
					var p_down=me.down.data["p"] if not me.down==null else (me.b_down["p"] if me.b_down["pb"] else null)
					var p_right=me.right.data["p"] if not me.right==null else (me.b_right["p"] if me.b_right["pb"] else null)
					var p_left=me.left.data["p"] if not me.left==null else (me.b_left["p"] if me.b_left["pb"] else null)
					error+=my_avg(p_up,p_down,p_right,p_left)-me.data["p"]
		print("computation error=",error)
		
	#####################
	for x in range(mesh.size()):
		for y in range(mesh[0].size()):
			if mesh[x][y] is Cell:
				var me=mesh[x][y]
				var v=me.data["v"]
				var p=me.data["p"]
				var grad_p=Vector2.ZERO
				if me.up!=null and me.down!=null:
					 grad_p.y=me.up.data["p"]-me.down.data["p"]
				elif me.up!=null and me.down==null:
					 grad_p.y=me.up.data["p"]-me.data["p"]
				elif me.up!=null and me.down==null:
					 grad_p.y=me.up.data["p"]-me.data["p"]
	##########################
	var f=VKT_File.new()
	for l in mesh:
		for c in l:
			if c is Cell:
				f.draw_quad(Vector2(c.x,c.y),
							Vector2(c.x,c.y+1),
							Vector2(c.x+1,c.y+1),
							Vector2(c.x+1,c.y),
							{"pressure":c.data["p"]})
	f.save("save3.vtk")
	
