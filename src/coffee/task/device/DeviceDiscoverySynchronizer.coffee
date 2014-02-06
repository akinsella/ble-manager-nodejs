_ = require('underscore')._
util = require 'util'
noble = require 'noble'
Q = require 'q'
async = require 'async'

logger = require '../../log/logger'
utils = require '../../lib/utils'
Device = require "../../model/device"

DeviceSynchronizer = require './DeviceSynchronizer'

DeviceTransformer = require '../../service/bluetooth/DeviceTransformer'
DeviceAnalyzer = require '../../service/bluetooth/DeviceAnalyzer'
DiscoveryService = require '../../service/bluetooth/DiscoveryService'

class DeviceDiscoverySynchronizer extends DeviceSynchronizer

	constructor: (@discoveryTimeout, @readCharacteristicsTimeout) ->
		logger.info("Instanciating Device discovery Synchronizer with a timeout of #{discoveryTimeout}ms")
		super("Device")

	itemTransformer: (devices) =>
		devices = _(devices).sortBy (device) =>
			"#{device.uuid} - #{device.advertisement.localName}".toUpperCase()
		devices = devices.map (device) =>
			logger.info("device[#{device.uuid}]: #{util.inspect(device)}")
			DeviceTransformer.transform device

	compareFields: () ->
		["uuid"]

	query: (device) ->
		id: device.id
		uuid: device.uuid

	updatedData: (device) ->
		name: device.name
		uuid: device.uuid
		model: device.model

	itemDescription: (device) ->
		logger.info("device[#{device.uuid}]: #{util.inspect(device)}")
		"#{device.uuid.toUpperCase()} - #{device.advertisement.localName}"

	createStorableItem: (device) ->
		new Device(device)

	modelClass: () ->
		Device

	synchronizer: (params, callback) =>
		DiscoveryService.discoverDevices @discoveryTimeout, (err, devices) =>
			async.mapSeries devices, @analyzeDevice, (err, devices) =>
				callback err, devices

	analyzeDevice: (device, callback) =>
		DeviceAnalyzer.analyze(device, @readCharacteristicsTimeout, callback)

module.exports = DeviceDiscoverySynchronizer
