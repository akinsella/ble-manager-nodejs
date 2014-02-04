noble = require 'noble'
async = require 'async'
Q = require 'q'
_ = require('underscore')._

logger = require '../../log/logger'
DiscoveryService = require './DiscoveryService'

deviceQueryQueues = {}

deviceQueryTaskProcessor = (task, callback) ->
	console.log("Executing task: '#{task.name}'")

	task.device.connect (err) ->
		logger.info("Connected to device with uuid: '#{task.device.uuid}'")
		if err
			callback(err)
		else
			doWithTimeout task.promise, 2000, (err, data) ->
				logger.info("Stop connection to device with id: '#{task.device.uuid}'")
				task.device.disconnect()
				callback(err, data)

queueForDeviceQuery = (deviceUuid) ->
	if (!deviceQueryQueues[deviceUuid])
		deviceQueryQueues[deviceUuid] = async.queue deviceQueryTaskProcessor, 1
	deviceQueryQueues[deviceUuid]

executeQuery = (device, promise, timeout, callback) ->
	logger.info("Reading device characteristic ...")

	queryTask =
		name: "Querying device with uuid: '#{device.uuid}'"
		promise: promise
		timeout: timeout

	taskCallback = (err, data) ->
		console.log("Finished processing queryTask with name: '#{queryTask.name}' - err: #{err}, data: #{data}")
		callback(err, data)

	queueForDeviceQuery(device.uuid).push(queryTask, taskCallback)

module.exports =
	executeQuery: executeQuery