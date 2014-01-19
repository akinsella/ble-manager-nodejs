logger = require 'winston'

utils = require '../lib/utils'
apns = require "../lib/apns"

Device = require "../model/device"
Notification = require "../model/notification"

#feedback.on "feedback", (devices) ->
#	_(devices).each (device) ->
#		logger.info "Received feedback for deletion on timestamp: #{device.time} for device with token #{device.token}"
#
#		Device.findOneAndRemove { token: device.token }, (err) ->
#			if (err)
#				logger.info "Could not remove device with token: #{device.token}."
#			else
#				logger.info "Removed device with token: #{device.token}"

list = (req, res) ->
	Notification.find {}, (err, notifications) ->
		if err
			utils.responseData(500, "Could not find notification - Error: #{err.message}", undefined, { req:req, res:res })
		else
			utils.responseData(200, undefined, notifications, { req:req, res:res })

findById = (req, res) ->
	Notification.findOne { id: req.params.id }, (err, notification) ->
		if err
			utils.responseData(500, "Could not find notification - Error: #{err.message}", undefined, { req:req, res:res })
		else if !notification
			utils.responseData(404, "Not Found", undefined, { req:req, res:res })
		else
			utils.responseData(200, undefined, notification, { req:req, res:res })

removeById = (req, res) ->
	Notification.findOneAndRemove { id: req.params.id }, (err, notification) ->
		if err
			utils.responseData(500, "Could not remove notification - Error: #{err.message}", undefined, { req:req, res:res })
		else if !notification
			utils.responseData(404, "Not Found", undefined, { req:req, res:res })
		else
			utils.responseData(204, undefined, notification, { req:req, res:res })

create = (req, res) ->
	notification = new Notification(req.body)
	notification.save (err) ->
		if err
			utils.responseData(500, "Could not save notification", req.body, { req:req, res:res })
		else
			utils.responseData(201, "Created", notification, { req:req, res:res })

mapNotification = (notification) ->
	id: notification.id
	message: notification.message


push = (req, res) ->

	notificationId = req.params.id
	apns.pushNotificationToAll notificationId, (err) ->
		if err
			utils.responseData(500, "Error: #{err}", "{}", { req:req, res:res })
		else
			utils.responseData(200, "Ok", "{}", { req:req, res:res })


module.exports =
	push : push
	list : list
	findById : findById
	create : create
	removeById : removeById
