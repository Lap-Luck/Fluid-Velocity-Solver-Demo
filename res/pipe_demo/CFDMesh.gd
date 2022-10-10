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

func number_of_cells_in_mesh():
	var res=0
	for x in range(mesh.size()):
		for y in range(mesh[0].size()):
			res+=int(mesh[x][y] is Cell)
	return res

func save():
	var fdata="""# vtk DataFile Version 1.0
2D Unstructured Grid of Linear Triangles
ASCII
DATASET UNSTRUCTURED_GRID\n"""
	fdata+="POINTS "+String(4*number_of_cells_in_mesh())+" float"+"\n"
	for l in mesh:
		for c in l:
			if c is Cell:
				for m in [[0,0],[0,1],[1,1],[1,0]]:
					fdata+=String(c.x+m[0])+" "+String(c.y+m[1])+" "+"0"+"\n"
	fdata+="CELLS "+String(number_of_cells_in_mesh())+" "+String(5*number_of_cells_in_mesh())+"\n"
	var id=0
	for l in mesh:
		for c in l:
			if c is Cell:
				fdata+="4 "+String(4*id)+" "+String(4*id+1)+" "+String(4*id+2)+" "+String(4*id+3)+"\n"
				id+=1
	fdata+="CELL_TYPES "+String(number_of_cells_in_mesh())+"\n"
	for l in mesh:
		for c in l:
			if c is Cell:
				fdata+="9\n"
	fdata+="CELL_DATA "+String(number_of_cells_in_mesh())+"\n"
	fdata+="""SCALARS pressure float
LOOKUP_TABLE default\n"""
	for l in mesh:
		for c in l:
			if c is Cell:
				var value=0.0
				if (c.x+c.y)%2==0:
					value=1.0
				fdata+=String(value)+" "
	#print(fdata)
	var f=File.new()
	f.open("res://save2.vtk",File.WRITE)
	f.store_string(fdata)
	f.close()

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
	for t in range(1000):
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
	
	var fdata="""# vtk DataFile Version 1.0
2D Unstructured Grid of Linear Triangles
ASCII
DATASET UNSTRUCTURED_GRID\n"""
	fdata+="POINTS "+String(4*number_of_cells_in_mesh())+" float"+"\n"
	for l in mesh:
		for c in l:
			if c is Cell:
				for m in [[0,0],[0,1],[1,1],[1,0]]:
					fdata+=String(c.x+m[0])+" "+String(c.y+m[1])+" "+"0"+"\n"
	fdata+="CELLS "+String(number_of_cells_in_mesh())+" "+String(5*number_of_cells_in_mesh())+"\n"
	var id=0
	for l in mesh:
		for c in l:
			if c is Cell:
				fdata+="4 "+String(4*id)+" "+String(4*id+1)+" "+String(4*id+2)+" "+String(4*id+3)+"\n"
				id+=1
	fdata+="CELL_TYPES "+String(number_of_cells_in_mesh())+"\n"
	for l in mesh:
		for c in l:
			if c is Cell:
				fdata+="9\n"
	fdata+="CELL_DATA "+String(number_of_cells_in_mesh())+"\n"
	fdata+="""SCALARS pressure float
LOOKUP_TABLE default\n"""
	for l in mesh:
		for c in l:
			if c is Cell:
				fdata+=String(c.data["p"])+" "
	#print(fdata)
	var f=File.new()
	f.open("res://save3.vtk",File.WRITE)
	f.store_string(fdata)
	f.close()
