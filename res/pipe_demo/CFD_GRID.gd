tool
extends Node2D

class Boundary:
	var name:String
	var points:PoolVector2Array
	var color:Color
	var boundary:Dictionary


func _ready():
	_tab_update()

var tab = [] #Use to store ids of thing thath ocupies this cell
export(bool) var refresh=false
export var RES_X = 50
export var RES_Y = 50
export var DX = 20.0
export var  DY = 20.0
var boundaries = []


func vec2grid(v:Vector2):
	return [int(v.x/DX),int(v.y/DY)]

func _tab_update():
	if true:
		#creating empty grid
		var id=-1 #not valid id so not bounbary
		for i_x in range(RES_X):
			tab.append([])
			for i_y in range(RES_Y):
				tab[-1].append(id)
	if true:
		#creating bounbary grid
		for l_id in range($CFD_BOUNDARY.get_child_count()):
			var line2d:Line2D=$CFD_BOUNDARY.get_child(l_id)
			
			var b=Boundary.new()
			b.color=line2d.default_color
			b.boundary={"vb":line2d.vb,"v":line2d.v,"pb":line2d.pb,"p":line2d.p}
			b.name=line2d.name
			boundaries.append(b)
			
			for id in range(line2d.points.size()-1):
				var line=[line2d.points[id],line2d.points[id+1]]
				var steps_count=2+int((line[0]-line[1]).length())
				for step in range(steps_count):
					var pos=line[0]+(line[1]-line[0])*(float(step)/float(steps_count-1))
					var ipos=vec2grid(pos)
					tab[ipos[0]][ipos[1]]=l_id
	if true:
		assert(tab[0][0]==-1)
		var outside=_select(0,0)
		for coord in outside:
			tab[coord[0]][coord[1]]=-2

func _select(x,y):
	var m_tab = tab.duplicate(true)
	var to_vist = [[x,y]]
	var thing = m_tab[x][y]
	var res = []
	
	while not to_vist.empty():
		var place = to_vist.pop_back()
		if not place[0] in range(RES_X):continue
		if not place[1] in range(RES_Y):continue
		
		if m_tab[place[0]][place[1]]==thing:
			res.append(place)
			m_tab[place[0]][place[1]]=thing+1
			for move in [[1,0],[-1,0],[0,1],[0,-1]]:
				to_vist.append([place[0]+move[0],place[1]+move[1]])

	return res


func _draw():
	for i_x in range(RES_X):
		for i_y in range(RES_X):
			if tab[i_x][i_y]==-1:
				draw_rect(Rect2(Vector2(i_x*DX,i_y*DY),Vector2(DX,DY)),
					Color.yellow if ((i_x+i_y)%2==0) else Color.green)
			if tab[i_x][i_y]>=0:
				var b=boundaries[tab[i_x][i_y]]
				var color=b.color
				draw_rect(Rect2(Vector2(i_x*DX,i_y*DY),Vector2(DX,DY)),
					color.darkened(0.1) if ((i_x+i_y)%2==0) else color.darkened(0.2))

func get_b_data(x,y):
	return boundaries[tab[x][y]].boundary

func _process(delta):
	if refresh:
		refresh=false
		tab = []
		boundaries = []
		_tab_update()
		update()
