noble = require 'noble'
async = require 'async'
Q = require 'q'
_ = require('underscore')._

utils = require '../../lib/utils'
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
			utils.doWithTimeout Q.nfcall(task.fn), task.timeout, (err, data) ->
				logger.info("Stop connection to device with id: '#{task.device.uuid}'")
				task.device.disconnect()
				logger.info("Finished processing queryTask with name: '#{task.name}' - err: #{err}, data: '#{data}'")
				callback(err, data)

queueForDeviceQuery = (deviceUuid) ->
	if (!deviceQueryQueues[deviceUuid])
		deviceQueryQueues[deviceUuid] = async.queue deviceQueryTaskProcessor, 1
	deviceQueryQueues[deviceUuid]

executeQuery = (device, fn, timeout, callback) ->
	logger.info("Executing query for device with UUID: '#{device.uuid}' ...")

	queryTask =
		name: "Querying device with uuid: '#{device.uuid}'"
		fn: fn
		device: device
		timeout: timeout

	deviceQueue = queueForDeviceQuery(device.uuid)
	deviceQueue.push(queryTask, callback)

module.exports =
	executeQuery: executeQuery