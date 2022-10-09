tool
extends Node2D

class Boundary:
	var name:String
	var start:Vector2
	var end:Vector2
	var points:PoolVector2Array

var boundaries=[]
func _ready2():
	var d=get_orber_boundary()
	print(d)
	

var tab=[]
func _ready():
	for i_x in range(20):
		tab.append([])
		for i_y in range(20):
			tab[-1].append(0)
	tab[5][5]=1

func _draw():
	for i_x in range(20):
		for i_y in range(20):
			if tab[i_x][i_y]==0:
				draw_rect(Rect2(Vector2(i_x*50.0,i_y*50.0),Vector2(50.0,50.0)),
					Color.yellow if ((i_x+i_y)%2==0) else Color.green)
	
func get_orber_boundary():
	for l in $CFD_BOUNDARY.get_children():
		var line2d:Line2D=l
		var dat=Boundary.new()
		dat.points=line2d.points
		dat.name=line2d.name
		dat.start=dat.points[0]
		dat.end=dat.points[-1]
		boundaries.append(dat)
	
	var ending2boundary={}
	for b_id in range(boundaries.size()):
		var b:Boundary=boundaries[b_id]
		var tmp
		tmp=ending2boundary.get(b.start,[])
		tmp.append(b_id)
		ending2boundary[b.start]=tmp
		tmp=ending2boundary.get(b.end,[])
		tmp.append(b_id)
		ending2boundary[b.end]=tmp
		
	print("***",ending2boundary)
	
	var current_id=0
	var current_b:Boundary=boundaries[current_id]
	var current_pos:Vector2=current_b.start
	
	var res=[]
	for _a in boundaries:
		current_pos=current_b.end if current_pos==current_b.start else current_b.start
		var b_ids=ending2boundary[current_pos]
		current_id=b_ids[0] if b_ids[1]==current_id else b_ids[1]
		if true:
			#print(current_pos,">>",current_b.points)
			if current_pos!=current_b.end:
				var c=current_b.points
				var t=PoolVector2Array([])
				#print("CCCC",c)
				for cp in c:
					#print("#",cp)
					t.insert(0,cp)
				#print("$")
				current_b.points=t
			res.append(current_b.points)
				
		current_b=boundaries[current_id]
	return res
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
