extends Node

func create_num_array(a:int,b:int=-1):
	if b==-1:
		var res=[]
		for i in range(a):
			res.apppend(0.0)
		return res
	else:
		var res=[]
		for i in range(a):
			var sub_res=[]
			for j in range(b):
				sub_res.append(0.0)
			res.append(sub_res)
		return res
	

func has_child_named(n:Node,name:String)->bool:
	for c in n.get_children():
		if c.name==name:
			return true
	return false

func pool_of_zeros(size:int):
	var res=PoolRealArray([])
	res.resize(size)
	for i in range(size):
		res[i]=0.0
	return res

func zeros(count:int)->Array:
	var res=[]
	for i in range(count):
		res.append(0.0)
	return res

func vector_sub(a:Array,b:Array)->Array:
	var res=zeros(a.size())
	for i in range(a.size()):
		res[i]=a[i]-b[i]
	return res


func vector_norm(a,norm):
	if not a is Array:
		assert(false)
	match norm:
		"L1":
			var res=0.0
			for e in a:
				res+=abs(e)
			return res
		"L2":
			var res=0.0
			for e in a:
				res+=abs(e)*abs(e)
			return res
		_:
			assert(false)
	return
#MY_NUM_DEBUG

class My_num:
	
	static func NWD(a:int,b:int):
		var ma:int=int(abs(max(a,b)))
		var mi:int=int(abs(min(a,b)))
		if mi<2:
			return 1
		if ma%mi==0:
			return mi
		return NWD(mi,ma-mi*(ma/mi))
	var a:int
	var b:int
	func _init(v,e=null):
		if Global.data.has("MY_NUM_DEBUG"):
			print("creating from(",v,",",e,")")
		if v is float:
			self.a=int(v*12)
			self.b=12
		else:
			if e == null:
				assert(false)
			var nwd=NWD(v,e)
			self.a=v/nwd
			self.b=e/nwd
			if b>1000000000 or b<-1000000000:
				if a==0:
					b=1
				else:
					print("Big num warning:",self)
					var mi:int=int(abs(min(a,b)))
					self.a=100000000*a/mi
					self.b=100000000*b/mi
					if b>4000000000 or b<-4000000000:
						self.a=0
						self.b=1
						print("WARNING NUM to 0")
					else:
						print("to simplyfiy:",self)
			if b==0:
				assert(false)
	func add(other:My_num):
		return My_num.new(self.a*other.b+self.b*other.a,self.b*other.b)
	func sub(other:My_num):
		return My_num.new(self.a*other.b-self.b*other.a,self.b*other.b)
	func mul(other:My_num):
		return My_num.new(self.a*other.a,self.b*other.b)
	func div(other:My_num):
		return My_num.new(self.a*other.b,self.b*other.a)
	func neg():
		return My_num.new(self.a,self.b)
	func _to_string():
		return "<"+String(self.a)+"/"+String(self.b)+">"
	func _to_float():
		return float(self.a)/float(self.b) if float(self.b!=0.0) else NAN

class My_num2:
	var value:float
	func _init(v:float):
		self.value=v
	func add(other:My_num2):
		return My_num2.new(self.value+other.value)
	func sub(other:My_num2):
		return My_num2.new(self.value-other.value)
	func mul(other:My_num2):
		return My_num2.new(self.value*other.value)
	func div(other:My_num2):
		return My_num2.new(self.value/other.value)
	func neg():
		return My_num2.new(-self.value)
	func _to_string():
		return String(self.value)
	func _to_float():
		return self.value

class Equation:
	var variables=[]
	var weights=[]
	var value=0.0
	func _to_string():
		var res:=""
		for i in range(variables.size()):
			res+=String(weights[i])+"*x_"+String(variables[i])+"+"
		res+="="
		res=res.replace("+=","=")
		res+=String(value)
		return res
	func add(v_id,w):
		if not v_id is int:
			assert(false)
		if not w is float:
			assert(false)
		self.variables.append(v_id)
		self.weights.append(w)
		return self
	
class EquationSystem:
	var data:Array=[]
	func add(e:Equation):
		data.append(e)
	func _to_string():
		var res:=""
		for i in range(data.size()):
			if Global.data.has("PRINT_EQUATION_SYSTEM_IN_ONE_LINE"):
				res+=data[i]._to_string()+";"
			else:
				res+=data[i]._to_string()+"\n"
		return res
	#NEW!!!!!!
	func get_diagonal_cooficients():
		var res=[]
		for e_id in range(data.size()):
			var to_res=0.0
			for id in range(data[e_id].variables.size()):
				to_res+=data[e_id].weights[id] if data[e_id].variables[id]==e_id else 0.0
			res.append(to_res)
		return res
	func get_matrix():
		var dim=data.size()
		var res=Matrix.new(dim)
		var number_of_unknowns:int
		for row_id in dim:
			var e:Equation=data[row_id]
			for i in range(e.variables.size()):
				if e.variables[i]>=dim:
					print("Error equation system illdefined")
					assert(false)
				number_of_unknowns=max(number_of_unknowns,e.variables[i])
				res.inc_value(e.variables[i],row_id,e.weights[i])
		print(number_of_unknowns)
		if not number_of_unknowns+1==dim:
			print("Can not convert Equation System with ",number_of_unknowns+1,
				" to matrix with dim ",dim)
			assert(false)
		return res
	
	func get_vector():
		var dim=data.size()
		var res=PoolRealArray([])
		for row_id in dim:
			res.append(data[row_id].value)
		return res
			
class Matrix:# to represnt squere matrix 
	var NUM_LIB=My_num2
	var data:Array=[]
	var dim:int
	func _init(dim=0):
		self.dim=dim
		for y in range(dim):
			for x in range(dim):
				self.data.append(NUM_LIB.new(0.0))
	func inverse()->void:
		if not "MI_log" in Global.data.keys():
			Global.data["MI_log"]=[]
		Global.data["MI_log"].append(0)
		var res=Matrix.new(dim)
		for i in range(dim):
			res.data[i*dim+i]=NUM_LIB.new(1.0)
		if Global.data.has("MATRIX_DEBUG"):
			print("re",res)
			print("se",self)
		for self_x in range(dim):
			var diagonal_value=self.data[self_x*dim+self_x]
			for self_y in range(dim):
				if self_x==self_y: continue
				var weight=self.data[self_y*dim+self_x].div(diagonal_value).neg()
				#print("W:",weight)
				for res_x in range(dim):
					var value_change=weight.mul(res.data[self_x*dim+res_x])
					res.data[self_y*dim+res_x]=res.data[self_y*dim+res_x].add(value_change)
					Global.data["MI_log"][-1]+=1
				for id_x in range(dim):
					var value_change=weight.mul(self.data[self_x*dim+id_x])
					self.data[self_y*dim+id_x]=self.data[self_y*dim+id_x].add(value_change)
					Global.data["MI_log"][-1]+=1
			if Global.data.has("MATRIX_DEBUG"):
				print("re",res)
				print("se",self)
					
		for self_y in range(dim):
			var diagonal_value=self.data[self_y*dim+self_y]
			for res_x in range(dim):
				if diagonal_value._to_float()!=0.0:
					res.data[self_y*dim+res_x]=res.data[self_y*dim+res_x].div(diagonal_value)
				else:
					#res.data[self_y*dim+res_x]=NUM_LIB.new(-1.0)
					assert(false)
					print("ERROR!!!!!!!!!!!!!!")
		#returning value
		self.data=res.data
			
	func _to_string():
		var res:="Matrix(\n"
		for y in range(dim):
			for x in range(dim):
				res+=self.data[y*dim+x]._to_string()
				res+=" "
			res+="\n"
		res+=")"
		return res
	
	func set_value(x:int,y:int,value):
		if value is float:
			self.data[y*dim+x]=NUM_LIB.new(value)
			
	func get_value(x:int,y:int):
		return self.data[y*dim+x]._to_float()
		
	func inc_value(x:int,y:int,value):
		if value is float:
			self.data[y*dim+x]=self.data[y*dim+x].add(NUM_LIB.new(value))
	
	func mul(vec:PoolRealArray):
		if vec.size()!=self.dim:
			assert(false)
		var res_vec=PoolRealArray([])
		for y in range(dim):
			var res:float=0.0
			for x in range(dim):
				res+=self.data[y*dim+x]._to_float()*vec[x]
			res_vec.append(res)
		return res_vec

func _ready():
	if true:
		#Global.data["MY_NUM_DEBUG"]=true
		var a=My_num.new(1.0/2.0)
		var b=My_num.new(1.0/3.0)
		var c=My_num.new(1.0/6.0)
		assert(a._to_float()==1.0/2.0 and b._to_float()==1.0/3.0 and c._to_float()==1.0/6.0  )
		assert(a.add(b)._to_float()==5.0/6.0)
		assert(a.add(b).add(c)._to_float()==1.0)
	
	#print("test")
	#Global.data["MATRIX_DEBUG"]=true
	var m=Matrix.new(2)
	m.set_value(0,0,1.0)
	m.set_value(1,1,1.0)
	m.set_value(1,0,-1.0)
	m.set_value(0,1,1.0)
	#print(m)
	m.inverse()
	#print(m)
	if m.mul(PoolRealArray([1,0]))[1]!=-0.5:
		print("err",m.mul(PoolRealArray([1,0])))
		assert(false)

#example in_what_set([[1,2,3][10,20,30]],20)==1 (set id)
func in_what_set(sets,element):
	for i in range(sets.size()):
		if element in sets[i]:
			return i
	print("Count not find ",element," in ",sets)
	return -1

#[10,3]
#[1,10]

#->


#[10,3]
#[0,9,7]

#[1      0   ]
#[-0.1   1 ]

