noble = require 'noble'
async = require 'async'
Q = require 'q'

logger = require '../../log/logger'

noble.on 'stateChange', (state) ->
	logger.info("BLE state: #{state}")

scanningTaskProcessor = (task, callback) ->
	console.log("Executing scanning task: '#{task.name}'")

	devices = []
	console.log("Starting scanning with Noble")
	noble.startScanning(task.devices, false)

	listener = (device) ->
		console.log("Discovered device with UUID: '#{device.uuid}'")
		devices.push(device)

	noble.on 'discover', listener

	setTimeout () ->
		console.log("Stopping scanning with Noble")
		noble.stopScanning()
		noble.removeListener 'discover', listener
		console.log("Stopping scanning with Noble")
		callback(undefined, devices)
	, task.timeout

scanningQueue = async.queue scanningTaskProcessor, 1

executeDiscoveryTask = (task, callback) ->
	scanningQueue.push(task, callback)

discoverDevice = (deviceUuid, timeout, callback) ->
	discoverDeviceTask =
		name: "Discover device with uuid: '#{deviceUuid}'"
		devices: [deviceUuid]
		timeout: timeout

	taskCallback = (err, data) ->
		console.log("Finished processing discovery task with name: '#{discoverDeviceTask.name}' - err: #{err}, data: #{data}")
		callback(err, data)

	executeDiscoveryTask(discoverDeviceTask, taskCallback)

discoverDevices = (timeout, callback) ->
	discoverDeviceTask =
		name: "Discover devices"
		devices: []
		timeout: timeout

	executeDiscoveryTask(discoverDeviceTask, callback)

module.export =
	discoverDevice: discoverDevice
	discoverDevices: discoverDevices
