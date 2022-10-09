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

func _ready():
	mesh=$CFD_GRID.tab.duplicate(true)
	for l in mesh:
		print(l)
	
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
	save()

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
	print(fdata)
	var f=File.new()
	f.open("res://save2.vtk",File.WRITE)
	f.store_string(fdata)
	f.close()



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
