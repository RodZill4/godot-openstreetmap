extends Node

var classes = {}
var pool = {}

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func new(n):
	var x
	if pool.has(n) && !pool[n].empty():
		x = pool[n].back()
		pool[n].pop_back()
	else:
		var c
		if classes.has(n):
			c = classes[n]
		else:
			c = load(n)
			classes[n] = c
		x = c.instance()
	return x

func keep(x, n):
	if !pool.has(n):
		pool[n] = []
	pool[n].append(x)