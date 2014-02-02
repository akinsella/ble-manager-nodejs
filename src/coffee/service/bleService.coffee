noble = require 'noble'
Q = require 'q'
_ = require('underscore')._

logger = require '../log/logger'

noble.on 'stateChange', (state) ->
	logger.info("BLE state: #{state}")

readDeviceServiceCharacteristic = (deviceUuid, serviceUuid, characteristicUuid, callback) ->
	logger.info("Reading device characteristic ...")

	discoverPeripheral deviceUuid, (err, peripheral) ->
		if !peripheral
			callback(new Error("No device found"))
		else
			peripheralHolder = {}
			promise = Q.nfcall(readDeviceServiceCharacteristicPromise, peripheral, serviceUuid, characteristicUuid, peripheralHolder)
			doWithTimeout promise, 2000, (err, data) ->
				if peripheralHolder.peripheral
					logger.info("Stop connection to device with id: #{peripheralHolder.peripheral.uuid}")
					peripheralHolder.peripheral.disconnect()

				logger.info("Stop scanning with Noble")
				noble.stopScanning()
				callback(err, data)

discoverPeripheral = (deviceUuid, callback) ->
	logger.info("Start scanning with Noble")

	device = undefined
	timeout = undefined

	listener = (peripheral) ->
		logger.info("Discovered peripheral with uuid: '#{peripheral.uuid}'")
		device = peripheral
		clearTimeout(timeout)
		timeoutCallback(undefined, peripheral)

	timeoutCallback = (err, peripheral) ->
		logger.info("Stop scanning with Noble")
		noble.removeListener('discover', listener)
		noble.stopScanning()
		callback(err, peripheral)

	noble.on 'discover', listener
	noble.startScanning([], false)
	timeout = setTimeout(timeoutCallback, 2000)

readDeviceServiceCharacteristicPromise = (peripheral, serviceUuid, characteristicUuid, dataHolder, peripheralCallback) ->

	peripheral.connect (err) ->
		logger.info("Connected to peripheral with uuid: '#{peripheral.uuid}'")
		if err
			peripheralCallback(err)
		else
			dataHolder.peripheral = peripheral
			peripheral.discoverServices [serviceUuid], (err, services) ->
				service = _(services).find (service) -> service.uuid == serviceUuid
				if !service
					peripheralCallback(err)
				else
					logger.info("Discovered service with uuid '#{service.uuid}' to peripheral with uuid: '#{peripheral.uuid}'")
					if err || !service
						peripheralCallback(err)
					else
						service.discoverCharacteristics [characteristicUuid], (err, characteristics) ->
							characteristic = _(characteristics).find (characteristic) -> characteristic.uuid == characteristicUuid
							if err || !characteristic
								peripheralCallback(err)
							else
								logger.info("Discovered characteristic with uuid '#{characteristic.uuid}' service with uuid '#{service.uuid}' to peripheral with uuid: '#{peripheral.uuid}'")
								if err || !characteristic
									peripheralCallback(err)
								else
									characteristic.read (err, data) ->
										if err || !data
											peripheralCallback(err)
										else
											logger.info("Read data: '#{data}' for characteristic with uuid '#{characteristic.uuid}' service with uuid '#{service.uuid}' to peripheral with uuid: '#{peripheral.uuid}'")
											peripheralCallback(undefined, data)


doWithTimeout = (promise, timeout, callback) ->
	Q.timeout(promise, timeout)
	.then (peripherals) ->
			callback(undefined, peripherals)
	.fail (err) ->
			callback(err)
	.done()


module.exports =
	readDeviceServiceCharacteristic: readDeviceServiceCharacteristic