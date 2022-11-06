extends Node

var mutex = Mutex.new()
var semaphore = Semaphore.new()
var threads = []

func add_new_thread():
	threads.append({
		thread = Thread.new(),
		queue = [],
		stopped = false
	})

	threads[threads.size() - 1].thread.start(self, 'thread_function', threads.size() - 1)

func thread_function(id):
	while true:
		mutex.lock()
		var stopped = threads[id].stopped
		var queue_size = threads[id].queue.size()
		mutex.unlock()
		if stopped:
			break

		if queue_size > 0:
			threads[id].queue[0].functionref.call_func(threads[id].queue[0].params)
			mutex.lock()
			threads[id].queue.remove(0)
			mutex.unlock()

func add_to_queue(id, functionref, params):
	mutex.lock()
	var function_call = {
		functionref = functionref,
		params = params
	}
	threads[id].queue.append(function_call)
	mutex.unlock()

func stop_all_threads():
	mutex.lock()
	for thread in threads:
		thread.stopped = true
	mutex.unlock()

func wait_to_finish():
	for thread in threads:
		thread.thread.wait_to_finish()