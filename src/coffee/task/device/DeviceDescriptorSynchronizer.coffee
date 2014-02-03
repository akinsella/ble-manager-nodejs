_ = require('underscore')._
util = require 'util'
fs = require 'fs'
noble = require 'noble'
Q = require 'q'
async = require 'async'

logger = require '../../log/logger'
utils = require '../../lib/utils'
DeviceDescriptor = require "../../model/deviceDescriptor"
DeviceDescriptorSynchronizer = require './DeviceDescriptorSynchronizer'
DeviceSynchronizer = require './DeviceSynchronizer'

scanning = false

class DeviceDescriptorSynchronizer extends DeviceSynchronizer

	constructor: (@timeout) ->
		logger.info("Instanciating DeviceDescriptor Synchronizer with a timeout of #{timeout}ms")
		super("DeviceDescriptor")

	itemTransformer: (deviceDescriptors) =>
		deviceDescriptors = _(deviceDescriptors).sortBy (deviceDescriptor) =>
			"#{deviceDescriptor.uuid} - #{deviceDescriptor.uuid}".toUpperCase()
		deviceDescriptors = deviceDescriptors.map (deviceDescriptor) =>
			logger.info("deviceDescriptor[#{deviceDescriptor.uuid}]: #{util.inspect(deviceDescriptor)}")
			deviceDescriptor = new DeviceDescriptor(deviceDescriptor)

		deviceDescriptors

	compareFields: () ->
		["uuid"]

	query: (deviceDescriptor) ->
		id: deviceDescriptor.id
		uuid: deviceDescriptor.uuid

	updatedData: (deviceDescriptor) ->
		name: deviceDescriptor.name
		uuid: deviceDescriptor.uuid
		services: deviceDescriptor.services

	itemDescription: (deviceDescriptor) ->
		logger.info("deviceDescriptor[#{deviceDescriptor.uuid}]: #{util.inspect(deviceDescriptor)}")
		"#{deviceDescriptor.uuid.toUpperCase()}"

	createStorableItem: (deviceDescriptor) ->
		new DeviceDescriptor(deviceDescriptor)

	modelClass: () ->
		DeviceDescriptor

	synchronizer: (params, callback) =>
		deviceDescriptors = JSON.parse(fs.readFileSync("#{__dirname}/../../data/deviceDescriptors.json"))
		callback(undefined, deviceDescriptors)

module.exports = DeviceDescriptorSynchronizer
