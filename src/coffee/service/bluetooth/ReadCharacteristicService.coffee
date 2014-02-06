noble = require 'noble'
async = require 'async'
Q = require 'q'
_ = require('underscore')._

logger = require '../../log/logger'
DiscoveryService = require './DiscoveryService'
DeviceQueryExecutor = require './DeviceQueryExecutor'

readDeviceServiceCharacteristic = (deviceUuid, serviceUuid, characteristicUuid, timeout, callback) ->
	logger.info("Reading device characteristic ...")

	DiscoveryService.discoverDevice deviceUuid, timeout, (err, device) ->
		promise = Q.fncall(readDeviceServiceCharacteristicPromise, device, serviceUuid, characteristicUuid)
		DeviceQueryExecutor.executeQuery device, promise, timeout, callback

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