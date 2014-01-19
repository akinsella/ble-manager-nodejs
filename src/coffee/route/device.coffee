utils = require '../lib/utils'
Device = require "../model/device"

# To be refactored
create = (req, res) ->
	device = new Device(
		udid: req.body.udid
		token: req.body.token
		deviceModel: req.body.deviceModel
		systemVersion: req.body.systemVersion
	)

	device.save (err, device) ->
		if (err)
			utils.responseData(500, "Could not save device", req.body, { req:req, res:res })
		else
			utils.responseData(201, "Created", mapDevice(device), { req:req, res:res })

register = (req, res) ->
	query =  { udid: req.body.udid, token: req.body.token }
	Device.findOne query, (err, device) ->
		if err
			utils.responseData(500, "Could not check device is already registered", undefined, { req:req, res:res })
		else if device
			device.deviceModel = req.body.deviceModel
			device.systemVersion = req.body.systemVersion
#			device.save (err, device) ->
			Device.update query, { deviceModel: req.body.deviceModel, systemVersion: req.body.systemVersion }, { upsert: true }, (err, numberAffected, raw) ->
				if (err)
					utils.responseData(500, "Could not check device is already registered", undefined, { req:req, res:res })
				else
					utils.responseData(200, "Device already registered was updated", mapDevice(device), { req:req, res:res })
		else
			device = new Device(
				udid: req.body.udid
				token: req.body.token
				deviceModel: req.body.deviceModel
				systemVersion: req.body.systemVersion
			)

			device.save (err, device) ->
				if err
					utils.responseData(500, "Could not save device", req.body, { req:req, res:res })
				else
					utils.responseData(201, "Created", mapDevice(device), { req:req, res:res })

list = (req, res) ->
	Device.find {}, (err, devices) ->
		if err
			utils.responseData(500, "Could not get device list", undefined, { req:req, res:res })
		else
			utils.responseData(200, undefined, devices.map(mapDevice), { req:req, res:res })

findById = (req, res) ->
	Device.findOne { id: req.params.id }, (err, device) ->
		if err
			utils.responseData(500, "Could not get device", undefined, { req:req, res:res })
		else if (!device)
			utils.responseData(404, "Not Found", undefined, { req:req, res:res })
		else
			utils.responseData(200, undefined, mapDevice(device), { req:req, res:res })

removeById = (req, res) ->
	Device.findOneAndRemove { id: req.params.id }, (err, device) ->
		if (device)
			utils.responseData(204, undefined, mapDevice(device), { req:req, res:res })
		else
			utils.responseData(404, "Not Found", undefined, { req:req, res:res })

mapDevice = (device) ->
	device.toObject()

module.exports =
	register : register
	list : list
	findById : findById
	create : create
	removeById : removeById
