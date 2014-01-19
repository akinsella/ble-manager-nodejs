_ = require('underscore')._
logger = require 'winston'
ApnAgent = require 'apnagent'

config = require '../conf/config'
Device = require '../model/device'
Notification = require '../model/notification'

logger.info "Dirname: #{__dirname}"

if config.apns.enabled
	agent = new ApnAgent.Agent()
	agent
		.set('cert file', "#{__dirname}/../certs/helyx-apns-cert.pem")
		.set('key file', "#{__dirname}/../certs/helyx-apns-key.pem")
		.set('expires', '1d')
		.set('reconnect delay', '1s')
		.set('cache ttl', '30m')

	if config.apns.devMode
		logger.info("Apns sandbox mode")
		agent.enable('sandbox')
	else
		logger.info("Apns production mode !")

	# see error mitigation section
	agent.on 'message:error', (err, msg) ->
		logger.info("Got some error: #{err.message} - Message: #{msg}")

	# connect needed to start message processing
	agent.connect (err) ->
		if err
			throw err
		else
			logger.info("Apn agent running ")
else
	agent = {}

pushToAll = (message, cb) ->

	Device.find {}, (err, devices) ->
		if err
			cb(err)
		else
			_(devices).each (device) ->
				pushNotification(device.token, message)

			cb()


pushNotificationToAll = (notificationId, cb) ->
	# set default to one day - Global ??
	# agent.set('expires', '1d');

	Notification.findOne { id: notificationId }, (err, notification) ->
		if err
			cb(err)
		else
			Device.find {}, (err, devices) ->
				if err
					cb(err)
				else
					devices.forEach (device) ->
						pushNotification(device.token, notification.message)

					cb()


pushNotification = (token, message) ->
	if config.apns.enabled
		logger.info("Try to log Message: '#{message}' to device with token: '#{token}'");
		agent
			.createMessage()
			.device(token)
			.alert(message)
			.send((err) ->
				if err
					logger.info("Count not send message: '#{message}' for device with token: #{token}")
				else
					logger.info("Message sent")
			)
	else
		logger.info("[APNS][DISABLED] Message: '#{message}' to device with token: '#{token}'")

module.exports =
	pushToAll: pushToAll
	pushNotificationToAll: pushNotificationToAll
