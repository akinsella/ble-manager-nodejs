async = require 'async'
Q = require 'q'
_ = require('underscore')._

logger = require '../log/logger'
utils = require '../lib/utils'
Device = require '../model/device'
DeviceDescriptor = require '../model/deviceDescriptor'
DeviceDiscoverySynchronizer = require '../task/device/DeviceDiscoverySynchronizer'
BleServive = require '../service/bluetooth/ReadCharacteristicService'

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

	deviceUuid = req.params.deviceUuid
	serviceUuid = req.params.serviceUuid
	characteristicUuid = req.params.characteristicUuid

	logger.info("Reading data for characteristic with uuid '#{characteristicUuid}' service with uuid '#{serviceUuid}' to peripheral with uuid: '#{deviceUuid}'")

	BleServive.readDeviceServiceCharacteristic deviceUuid, serviceUuid, characteristicUuid, (err, data) ->
		if err
			res.send 500, "Server error: #{err.message}"
		else
			res.json 200, {
				deviceUuid: deviceUuid
				serviceUuid: serviceUuid
				characteristicUuid: characteristicUuid
				data:
					string: data.toString()
					hexa: data.toString('hex')
					array: JSON.stringify(data)
			}

deviceDescriptorByDeviceUuid = (req, res) ->
	DeviceDescriptor.findOne { uuid: req.params.deviceUuid }, (err, deviceDescriptor) ->
		if err
			res.send 500, "Could not get device descriptors for uuid: #{req.params.deviceUuid}"
		else if !deviceDescriptor
			res.send 404, "Not Found"
		else
			res.send 200, deviceDescriptor.toObject()

module.exports =
	list : list
	findById : findById
	removeById : removeById
	discover: discover
	readDeviceServiceCharacteristic: readDeviceServiceCharacteristic
	deviceDescriptorByDeviceUuid: deviceDescriptorByDeviceUuid