async = require 'async'
noble = require 'noble'
Q = require 'q'
logger = require 'winston'
_ = require('underscore')._

utils = require '../lib/utils'
Device = require '../model/device'
DeviceDiscoverySynchronizer = require '../task/device/DeviceDiscoverySynchronizer'

noble.on 'stateChange', (state) ->
	logger.info("BLE state: #{state}")

list = (req, res) ->
	Device.find {}, (err, devices) ->
		if err
			res.send 500, "Could not get device list"
		else
			res.send 200, devices.map (device) ->
				device.toObject()

findById = (req, res) ->
	Device.findOne { id: req.params.id }, (err, device) ->
		if err
			res.send 500, "Could not get device"
		else if !device
			res.send 404, "Not Found"
		else
			res.send 200, device.toObject()

removeById = (req, res) ->
	Device.findOneAndRemove { id: req.params.id }, (err, device) ->
		if err
			res.send 500, "Server error: #{err.message}"
		if !device
			res.send 404, "Not Found"
		else
			res.send 200, device.toObject()

discover = (req, res) ->
	console.log("Discovering devices ...")
	synchronizer = new DeviceDiscoverySynchronizer(2 * 1000)
	synchronizer.synchronize (err, devices) ->
		if err
			res.send 500, "Server error: #{err.message}"
		else
			res.send 200, devices.map (device) ->
				device.toObject()

readDeviceServiceCharacteristic = (req, res) ->
	console.log("Reading device characteristic ...")
	deviceUuid = req.params.deviceUuid
	serviceUuid = req.params.serviceUuid
	characteristicUuid = req.params.characteristicUuid
	peripheralHolder = {};

	noble.startScanning([], false)

	deviceCallback = (err, peripheral) ->
		console.log("Stopping scanning with Noble")
		if peripheralHolder.peripheral
			peripheralHolder.peripheral.disconnect()

		noble.stopScanning()

		if err
			res.send 500, "Server error: #{err.message}"
		else
			res.send 200, JSON.stringify(peripheral)

	peripheralProcessingPromise = undefined
	noble.on 'discover', (peripheral) ->
		logger.info("Discovered peripheral with uuid: '#{peripheral.uuid}'")
		if peripheral.uuid != deviceUuid
			logger.info("Not expected device !")
		else
			peripheralProcessingPromise = Q.nfcall(readDeviceServiceCharacteristicInternal, peripheral, serviceUuid, characteristicUuid, peripheralHolder)

	setTimeout () ->
		if peripheralProcessingPromise
			peripheralProcessingPromise
				.then (peripherals) ->
						deviceCallback(undefined, peripherals)
				.fail (err) ->
						deviceCallback(err)
				.done()
		else
			deviceCallback(new Error("No device found"))

	, 2000

readDeviceServiceCharacteristicInternal = (peripheral, serviceUuid, characteristicUuid, dataHolder, peripheralCallback) ->

	peripheral.connect (err) ->
		logger.info("Connected to peripheral with uuid: '#{peripheral.uuid}'")
		if err
			peripheralCallback(err)
		else
			dataHolder.peripheral = peripheral
			peripheral.discoverServices [serviceUuid], (err, services) ->
				service = _(services).find (service) -> service.uuid == serviceUuid
				logger.info("Discovered service with uuid '#{service.uuid}' to peripheral with uuid: '#{peripheral.uuid}'")
				if err || !service
					peripheralCallback(err)
				else
					service.discoverCharacteristics [characteristicUuid], (err, characteristics) ->
						characteristic = _(characteristics).find (characteristic) -> characteristic.uuid == characteristicUuid
						logger.info("Discovered characteristic with uuid '#{characteristic.uuid}' service with uuid '#{service.uuid}' to peripheral with uuid: '#{peripheral.uuid}'")
						if err || !characteristic
							peripheralCallback(err)
						else
							characteristic.read (err, data) ->
								if err || !data
									peripheralCallback(err)
								else
									logger.info("Read data: '#{data}' for characteristic with uuid '#{characteristic.uuid}' service with uuid '#{service.uuid}' to peripheral with uuid: '#{peripheral.uuid}'")
									peripheralCallback(undefined, data)



module.exports =
	list : list
	findById : findById
	removeById : removeById
	discover: discover
	readDeviceServiceCharacteristic: readDeviceServiceCharacteristic