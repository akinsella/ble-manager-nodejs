logger = require 'winston'

config = require '../conf/config'
utils = require '../lib/utils'

class DataSynchronizer
	constructor: (@name) ->
		logger.info("Instanciating Data Synchronizer with name: '#{@name}'")

	synchronize: (done) =>
		callback = (err, results) =>
			if err
				logger.info "#{@name} Data Synchronization ended with error: #{err.message} - Error: #{err}"
			else if !results
				logger.info "#{@name} Synchronization ended with no data"
			else
				logger.info "#{@name} Data Synchronization ended with success (#{results.length} items) !"
				done(err, results)

		if config.feature.stopWatch
			callback = utils.stopWatchCallbak callback

		logger.info "Start synchronizing #{@name} data ..."

		@synchronizeData(callback)

	synchronizeData: (callback) ->
		callback(null, null)

module.exports = DataSynchronizer