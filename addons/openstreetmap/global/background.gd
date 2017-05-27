extends Node

var thread = Thread.new()
var mutex = Mutex.new()
var finished

var queue = []

func _ready():
	pass

func run(object, method, data):
	mutex.lock()
	if finished:
		thread.wait_to_finish()
	queue.append({ object = object, method = method, data = data})
	if !thread.is_active():
		finished = false
		thread.start(self, "execute")
	mutex.unlock()

func execute(data):
	while true:
		mutex.lock()
		if queue.empty():
			finished = true
			mutex.unlock()
			return
		var action = queue.front()
		queue.pop_front()
		mutex.unlock()
		#print("Running "+action.method+" on "+str(action.object))
		action.object.call(action.method, action.data)
	
