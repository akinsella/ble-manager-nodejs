DeviceDescriptorSynchronizer = require "../task/device/DeviceDescriptorSynchronizer"
DeviceDescriptor = require '../model/deviceDescriptor'
Q = require 'q'
util = require 'util'
sinon = require 'sinon'
fs = require 'fs'
should = require 'should'
mocha = require 'mocha'

describe "Device Descriptor Synchronizer", ->

	before (done) ->
		# Mock noble
		###
	    # sinon.stub(noble, 'doSomething').yields(null, {statusCode: 200}, tracks)
		###
		done()

	after (done) ->
		###
		# noble.doSomething.restore()
		###
		done()

	it "it should save Device Descriptors", (done) ->
		Q.nfcall(DeviceDescriptor.remove.bind(DeviceDescriptor), {})
			.then () ->
				synchronizer = new DeviceDescriptorSynchronizer(5 * 1000)
				Q.nfcall(synchronizer.synchronize)
			.then (deviceIds) ->
				console.log("Saved #{deviceIds.length} device descriptors")
				deviceIds.length.should.greaterThan 0
				done()
			.fail (err) ->
				throw err
			.done()
