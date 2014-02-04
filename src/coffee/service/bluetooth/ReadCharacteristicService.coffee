noble = require 'noble'
async = require 'async'
Q = require 'q'
_ = require('underscore')._

logger = require '../../log/logger'
DiscoveryService = require './DiscoveryService'
DeviceQueryService = require './DeviceQueryService'

readDeviceServiceCharacteristic = (deviceUuid, serviceUuid, characteristicUuid, callback) ->
	logger.info("Reading device characteristic ...")

	DiscoveryService.discoverDevice deviceUuid, 2000, (err, device) ->
		promise = Q.fncall(readDeviceServiceCharacteristicPromise, device, serviceUuid, characteristicUuid)
		DeviceQueryService.executeQuery device, promise, 2000, callback

readDeviceServiceCharacteristicPromise = (device, serviceUuid, characteristicUuid, callback) ->
	device.discoverServices [serviceUuid], (err, services) ->
		service = _(services).find (service) -> service.uuid == serviceUuid
		if !service
			callback(err)
		else
			logger.info("Discovered service with uuid '#{service.uuid}' to device with uuid: '#{device.uuid}'")
			if err || !service
				callback(err)
			else
				service.discoverCharacteristics [characteristicUuid], (err, characteristics) ->
					characteristic = _(characteristics).find (characteristic) -> characteristic.uuid == characteristicUuid
					if err || !characteristic
						callback(err)
					else
						logger.info("Discovered characteristic with uuid '#{characteristic.uuid}' service with uuid '#{service.uuid}' to device with uuid: '#{device.uuid}'")
						if err || !characteristic
							callback(err)
						else
							characteristic.read (err, data) ->
								if err || !data
									callback(err)
								else
									logger.info("Read data: '#{data}' for characteristic with uuid '#{characteristic.uuid}' service with uuid '#{service.uuid}' to device with uuid: '#{device.uuid}'")
									callback(undefined, data)

module.exports =
	readDeviceServiceCharacteristic: readDeviceServiceCharacteristic