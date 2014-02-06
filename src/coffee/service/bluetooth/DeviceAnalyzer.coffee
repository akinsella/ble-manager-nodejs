noble = require 'noble'
async = require 'async'
Q = require 'q'
_ = require('underscore')._
util = require 'util'

logger = require '../../log/logger'
ScanningService = require './DiscoveryService'
DeviceQueryExecutor = require './DeviceQueryExecutor'

analyze = (device, timeout, callback) ->
	console.log("Processing device with UUID #{device.uuid}")
	fn = (callback) ->
		discoverServices device, (err, services) ->
			if err
				callback(err)
			else
				device.services = services
				callback(undefined, device)
	DeviceQueryExecutor.executeQuery(device, fn, timeout, callback)

discoverServices = (device, callback) ->
	device.discoverServices [], (err, services) ->
		if err
			callback(err)
		else
			async.mapSeries(services, processService, callback)

processService = (service, callback) ->
	console.log "Service[#{service.uuid}] = #{service.name}"
	discoverCharacteristics service, (err, characteristics) ->
		if err
			callback(err)
		else
			service.characteristics = characteristics
			callback(undefined, service)

discoverCharacteristics = (service, callback) ->
	service.discoverCharacteristics [], (err, characteristics) ->
		if err
			callback(err)
		else
			async.mapSeries(characteristics, processCharacteristic, callback)

processCharacteristic = (characteristic, callback) ->
	console.log "Characteristic[#{characteristic.uuid}] name = #{characteristic.name}, type = #{characteristic.type}, properties = #{characteristic.properties}"
	discoverDescriptors characteristic, (err, descriptors) ->
		if err
			callback(err)
		else
			characteristic.descriptors = descriptors
			callback(undefined, characteristic)

discoverDescriptors = (characteristic, callback) ->
	characteristic.discoverDescriptors (err, descriptors) ->
		if err
			callback(err)
		else
			async.mapSeries(descriptors, processDescriptor, callback)

processDescriptor = (descriptor, callback) ->
	console.log "Descriptor[#{descriptor.uuid}] name = #{descriptor.name}, type = #{descriptor.type}"
	callback(undefined, descriptor)


module.exports =
	analyze: analyze