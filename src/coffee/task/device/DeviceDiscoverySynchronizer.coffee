logger = require 'winston'
_ = require('underscore')._
util = require 'util'

utils = require '../../lib/utils'
Device = require "../../model/device"
DeviceSynchronizer = require './DeviceSynchronizer'
noble = require 'noble'
Q = require 'q'

noble.on 'stateChange', (state) ->
	logger.info("BLE state: #{state}")


class DeviceDiscoverySynchronizer extends DeviceSynchronizer

	constructor: (@timeout) ->
		logger.info("Instanciating Device discovery Synchronizer with a timeout of #{timeout}ms")
		super("Device")

	itemTransformer: (peripherals) =>
		peripherals = _(peripherals).sortBy (peripheral) =>
			"#{peripheral.uuid} - #{peripheral.advertisement.localName}".toUpperCase()
		devices = peripherals.map (peripheral) =>
			logger.info("peripherial[#{peripheral.uuid}]: #{util.inspect(peripheral)}")
			new Device(
				uuid: peripheral.uuid
				advertisement:
					localName: peripheral.advertisement.localName
					txPowerLevel: peripheral.advertisement.txPowerLevel
					manufacturerData: peripheral.advertisement.manufacturerData.toString('hex')
					serviceData: peripheral.advertisement.serviceData
					serviceUuids: peripheral.advertisement.serviceUuids.map (serviceUuid) ->
						uuid: serviceUuid
				rssi: peripheral.rssi
			)

		devices

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

	synchronizer : (params, callback) =>

		logger.info("Into synchronizer")
		logger.info("Noble: #{noble}");

		noble.startScanning([], false)
		@discoverDevices (err, results) ->
			noble.stopScanning()
			callback(err, results)

	discoverDevices : (callback) ->
		peripherals = []
		noble.on 'discover', (peripheral) ->
			console.log("peripheral with UUID #{peripheral.uuid} found")
			peripherals.push(peripheral)
		setTimeout () ->
			callback(undefined, peripherals)
		, @timeout

module.exports = DeviceDiscoverySynchronizer
