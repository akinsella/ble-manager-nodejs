DeviceDiscoverySynchronizer = require "../task/device/DeviceDiscoverySynchronizer"
Device = require '../model/device'
Q = require 'q'
util = require 'util'
sinon = require 'sinon'
fs = require 'fs'
should = require 'should'
mocha = require 'mocha'

describe "Device Discovery Synchronizer", ->
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


	it "it should Discover Devices", (done) ->
		Q.nfcall(Device.remove.bind(Device), {})
			.then () ->
					synchronizer = new DeviceDiscoverySynchronizer(2 * 1000)
					Q.nfcall(synchronizer.synchronize)
			.then (deviceIds) ->
					console.log("Saved #{deviceIds.length} devices")
					deviceIds.length.should.greaterThan 0
					done()
			.fail (err) ->
					throw err
			.done()