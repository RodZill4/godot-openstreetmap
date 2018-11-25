extends HTTPRequest

var queue = []
var downloading = false

func _ready():
	connect("request_completed", self, "_on_HTTPRequest_completed")

func process_queue():
	if !downloading:
		while !queue.empty():
			var request = queue.front()
			set_download_file("user://http_download")
			if request(request.url) == RESULT_SUCCESS:
				downloading = true
				print("Downloading "+request.file+" from "+request.url)
				break
			else:
				print("Cannot download "+request.url)
				queue.pop_front()

func download(url, file, object, method, args):
	var found = false
	for e in queue:
		if e.url == url && e.file == file:
			e.actions.append( { object=object, method = method, args = args } )
			found = true
	if !found:
		queue.append({url=url, file=file, object=object, actions = [ { object=object, method = method, args = args } ] })
	process_queue()

func cancel():
	queue.clear()
	if downloading:
		downloading = false
		cancel_request()

func _on_HTTPRequest_completed(result, response_code, headers, body):
	downloading = false
	var request = queue.front()
	if result == RESULT_SUCCESS:
		var dir = Directory.new()
		dir.rename("user://http_download", request.file)
		print("Downloaded "+request.url)
		for a in request.actions:
			a.object.callv(a.method, a.args)
	else:
		print("HTTP request for "+request.url+" failed")
	queue.pop_front()
	process_queue()
