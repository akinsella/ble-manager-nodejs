logger = require 'winston'
_ = require('underscore')._
util = require 'util'

utils = require '../../lib/utils'
Device = require "../../model/device"
DeviceSynchronizer = require './DeviceSynchronizer'
noble = require 'noble'
Q = require 'q'

EXPECTED_MANUFACTURER_DATA_LENGTH = 25;
APPLE_COMPANY_IDENTIFIER = 0x004c; # https://www.bluetooth.org/en-us/specification/assigned-numbers/company-identifiers
IBEACON_TYPE = 0x02;
EXPECTED_IBEACON_DATA_LENGTH = 0x15;

noble.on 'stateChange', (state) ->
	logger.info("BLE state: #{state}")

scanning = false

class DeviceDiscoverySynchronizer extends DeviceSynchronizer

	constructor: (@timeout) ->
		logger.info("Instanciating Device discovery Synchronizer with a timeout of #{timeout}ms")
		super("Device")

	itemTransformer: (peripherals) =>
		peripherals = _(peripherals).sortBy (peripheral) =>
			"#{peripheral.uuid} - #{peripheral.advertisement.localName}".toUpperCase()
		devices = peripherals.map (peripheral) =>
			logger.info("peripherial[#{peripheral.uuid}]: #{util.inspect(peripheral)}")
			device = new Device(
				uuid: peripheral.uuid
				advertisement:
					localName: peripheral.advertisement.localName
					txPowerLevel: peripheral.advertisement.txPowerLevel
					manufacturerData: if peripheral.advertisement.manufacturerData then peripheral.advertisement.manufacturerData.toString('hex') else ''
					serviceData: peripheral.advertisement.serviceData
					serviceUuids: peripheral.advertisement.serviceUuids.map (serviceUuid) ->
						uuid: serviceUuid
				rssi: peripheral.rssi
			)

			if @hasBeaconData(peripheral)
				device.beaconData = @extractBeaconData(peripheral)
			device

		devices

	hasBeaconData: (peripheral) ->
		manufacturerData = peripheral.advertisement.manufacturerData
		manufacturerData and EXPECTED_MANUFACTURER_DATA_LENGTH is manufacturerData.length and APPLE_COMPANY_IDENTIFIER is manufacturerData.readUInt16LE(0) and IBEACON_TYPE is manufacturerData.readUInt8(2) and EXPECTED_IBEACON_DATA_LENGTH is manufacturerData.readUInt8(3)

	extractBeaconData: (peripheral) ->
		logger.debug "onDiscover: #{peripheral}"
		manufacturerData = peripheral.advertisement.manufacturerData
		logger.debug "onDiscover: manufacturerData = #{manufacturerData?.toString("hex")}, rssi = #{peripheral.rssi}"
		uuid = manufacturerData.slice(4, 20).toString("hex")
		major = manufacturerData.readUInt16BE(20)
		minor = manufacturerData.readUInt16BE(22)
		measuredPower = manufacturerData.readInt8(24)
		logger.debug "onDiscover: uuid = %#{uuid}, major = #{major}, minor = #{minor}, measuredPower = #{measuredPower}"
		if (not @_uuid or @_uuid is uuid) and (not @_major or @_major is major) and (not @_minor or @_minor is minor)
			accuracy = Math.pow(12.0, 1.5 * ((peripheral.rssi / measuredPower) - 1))
			proximity = null
			if accuracy < 0
				proximity = "unknown"
			else if accuracy < 0.5
				proximity = "immediate"
			else if accuracy < 4.0
				proximity = "near"
			else
				proximity = "far"
			bleacon =
				major: major
				minor: minor
				measuredPower: measuredPower
				accuracy: accuracy
				proximity: proximity
			bleacon
		else
			undefined

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
		if scanning
			callback new Error('Already scanning')

		noble.startScanning([], false)
		@discoverDevices (err, results) ->
			noble.stopScanning()
			callback(err, results)
			scanning = false

	discoverDevices : (callback) ->
		peripherals = []
		noble.on 'discover', (peripheral) ->
			console.log("peripheral with UUID #{peripheral.uuid} found")
			peripherals.push(peripheral)
		setTimeout () ->
			callback(undefined, peripherals)
		, @timeout

module.exports = DeviceDiscoverySynchronizer
