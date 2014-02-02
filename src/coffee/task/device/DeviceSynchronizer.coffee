async = require 'async'
request = require 'request'

logger = require '../../log/logger'
config = require '../../conf/config'
utils = require '../../lib/utils'
DataSynchronizer = require '../DataSynchronizer'

class DeviceSynchronizer extends DataSynchronizer

	constructor: (name) ->
		super name

	itemTransformer: (items) -> items

	compareFields: (item) -> {}

	query: (item) -> ""

	itemDescription: (item) -> item.toString()

	createStorableItem: (item) -> item

	modelClass: () -> undefined

	synchronizer : (params, callback) ->
		callback()

	synchronizeData: (callback) =>

		@synchronizer {}, (error, data) =>
			logger.info("Transforming response ...")
			items = @itemTransformer(data)
			async.map items, @synchronizeItem, callback

	synchronizeItem: (item, callback) =>
		@modelClass().findOne @query(item), (err, itemFound) =>
			if err
				callback err
			else if itemFound
				if utils.isNotSame(item, itemFound, @compareFields())
					@modelClass().update @query(item), @updatedData(item), (err, numberAffected, raw) ->
						callback err, item
				else
					callback err, itemFound
			else
				@createStorableItem(item).save (err) =>
					logger.info("New #{@name} synchronized: #{@itemDescription(item)}")
					callback err, item

module.exports = DeviceSynchronizer
