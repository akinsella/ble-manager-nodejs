util = require 'util'

logger = require '../../log/logger'
Device = require '../../model/device'

EXPECTED_MANUFACTURER_DATA_LENGTH = 25;
APPLE_COMPANY_IDENTIFIER = 0x004c; # https://www.bluetooth.org/en-us/specification/assigned-numbers/company-identifiers
IBEACON_TYPE = 0x02;
EXPECTED_IBEACON_DATA_LENGTH = 0x15;

transform = (device) ->
	logger.info("device[#{device.uuid}]: #{util.inspect(device)}")
	device = new Device(
		uuid: device.uuid
		advertisement:
			localName: device.advertisement.localName
			txPowerLevel: device.advertisement.txPowerLevel
			manufacturerData: if device.advertisement.manufacturerData then device.advertisement.manufacturerData.toString('hex') else ''
			serviceData: device.advertisement.serviceData
			serviceUuids: device.advertisement.serviceUuids.map (serviceUuid) ->
				uuid: serviceUuid
			services: device.advertisement.services
		rssi: device.rssi
	)

	if hasBeaconData(device)
		device.beaconData = extractBeaconData(device)
	device

hasBeaconData = (device) ->
	manufacturerData = device.advertisement.manufacturerData

	manufacturerData and
	EXPECTED_MANUFACTURER_DATA_LENGTH == manufacturerData.length and
	APPLE_COMPANY_IDENTIFIER == manufacturerData.readUInt16LE(0) and
	IBEACON_TYPE == manufacturerData.readUInt8(2) and
	EXPECTED_IBEACON_DATA_LENGTH == manufacturerData.readUInt8(3)

extractBeaconData = (device) ->
	logger.debug "onDiscover: #{device}"
	manufacturerData = device.advertisement.manufacturerData
	logger.debug "onDiscover: manufacturerData = #{manufacturerData?.toString("hex")}, rssi = #{device.rssi}"
	uuid = manufacturerData.slice(4, 20).toString("hex")
	major = manufacturerData.readUInt16BE(20)
	minor = manufacturerData.readUInt16BE(22)
	measuredPower = manufacturerData.readInt8(24)
	logger.debug "onDiscover: uuid = %#{uuid}, major = #{major}, minor = #{minor}, measuredPower = #{measuredPower}"
	accuracy = Math.pow(12.0, 1.5 * ((device.rssi / measuredPower) - 1))
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

module.exports =
	transform: transform