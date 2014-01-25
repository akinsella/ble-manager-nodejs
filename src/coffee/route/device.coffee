async = require 'async'

utils = require '../lib/utils'
Device = require '../model/device'
DeviceDiscoverySynchronizer = require '../task/device/DeviceDiscoverySynchronizer'

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

module.exports =
	list : list
	findById : findById
	removeById : removeById
	discover: discover
