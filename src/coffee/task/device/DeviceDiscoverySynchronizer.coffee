_ = require('underscore')._
util = require 'util'
noble = require 'noble'
Q = require 'q'
async = require 'async'

logger = require '../../log/logger'
utils = require '../../lib/utils'
Device = require "../../model/device"
DeviceSynchronizer = require './DeviceSynchronizer'

EXPECTED_MANUFACTURER_DATA_LENGTH = 25;
APPLE_COMPANY_IDENTIFIER = 0x004c; # https://www.bluetooth.org/en-us/specification/assigned-numbers/company-identifiers
IBEACON_TYPE = 0x02;
EXPECTED_IBEACON_DATA_LENGTH = 0x15;

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
					services: peripheral.advertisement.services
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

	synchronizer: (params, callback) =>
		if scanning
			callback new Error('Already scanning')

		console.log("Starting scanning with Noble")
		noble.startScanning([], false)
		@discoverPeripherals (err, peripherals) ->
			console.log("Stopping scanning with Noble")
			noble.stopScanning()
			callback(err, peripherals)
			scanning = false

	discoverPeripherals: (callback) =>
		peripherals = []
		listener = (peripheral) =>
			console.log("Discovered peripheral with UUID #{peripheral.uuid} found")
			peripherals.push Q.nfcall(@processPeripheral, peripheral)
		noble.on 'discover', listener

		setTimeout () ->
			Q.all(peripherals)
				.then (peripherals) ->
					noble.removeListener 'discover', listener
					callback(undefined, peripherals)
				.fail (err) ->
					noble.removeListener 'discover', listener
					callback(err)
				.done()
		, @timeout

	processPeripheral: (peripheral, callback) =>
		console.log("Processing peripheral with UUID #{peripheral.uuid} found")
		console.log("Connecting to peripheral with UUID #{peripheral.uuid} found")
		peripheral.connect (err) =>
			if err
				callback(err)
			else
				@discoverServices peripheral, (err, services) =>
					if err
						console.log("Disconnecting from peripheral with UUID #{peripheral.uuid} found")
						peripheral.disconnect()
						callback(err)
					else
						peripheral.advertisement.services = services
						console.log("Disconnecting from peripheral with UUID #{peripheral.uuid} found")
						peripheral.disconnect()
						callback(undefined, peripheral)

	discoverServices: (peripheral, callback) =>
		peripheral.discoverServices [], (err, services) =>
			if err
				callback(err)
			else
				async.mapSeries(services, @processService, callback)

	processService: (service, callback) =>
		console.log "Service[#{service.uuid}] = #{service.name}"
		@discoverCharacteristics service, (err, characteristics) =>
			if err
				callback(err)
			else
				service.characteristics = characteristics
				callback(undefined, service)

	discoverCharacteristics: (service, callback) =>
		service.discoverCharacteristics [], (err, characteristics) =>
			if err
				callback(err)
			else
				async.mapSeries(characteristics, @processCharacteristic, callback)

	processCharacteristic: (characteristic, callback) =>
		console.log "Characteristic[#{characteristic.uuid}] name = #{characteristic.name}, type = #{characteristic.type}, properties = #{characteristic.properties}"
		@discoverDescriptors characteristic, (err, descriptors) =>
			if err
				callback(err)
			else
				characteristic.descriptors = descriptors
				callback(undefined, characteristic)

	discoverDescriptors: (characteristic, callback) =>
		characteristic.discoverDescriptors (err, descriptors) =>
			if err
				callback(err)
			else
				async.mapSeries(descriptors, @processDescriptor, callback)

	processDescriptor: (@descriptor, callback) =>
		console.log "Descriptor[#{descriptor.uuid}] name = #{descriptor.name}, type = #{descriptor.type}"
		callback(undefined, descriptor)


module.exports = DeviceDiscoverySynchronizer
