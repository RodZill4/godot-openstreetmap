extends Node

var pool = {}

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func new(object):
	if pool.has(object):
		var p = pool[object]
		if !p.empty():
			var x = p.back()
			p.pop_back()
			return x
	return object.instance()

func newnew(object, count = 0):
	if count == 0:
		if pool.has(object):
			var p = pool[object]
			if !p.empty():
				var x = p.back()
				p.pop_back()
				return x
		return object.instance()
	else:
		var a = []
		if pool.has(object):
			var p = pool[object]
			if p.size() > 0:
				if p.size() <= count:
					a = p
					pool[object] = []
					count -= p.size()
				else:
					for i in range(count):
						a.append(p.back())
						p.pop_back()
					return
		for i in range(count):
			a.append(object.instance())
		return a

func keep(x, c):
	if !pool.has(c):
		pool[c] = [x]
	else:
		pool[c].append(x)