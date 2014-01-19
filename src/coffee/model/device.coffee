mongo = require '../lib/mongo'

pureautoinc  = require 'mongoose-pureautoinc'

Device = new mongo.Schema(
	id: Number,
	name: {type: String, "default": '', trim: true}
	uuid: {type: String, "default": '', trim: true}
	model: {type: String, "default": '', trim: true}
	advertisement:{
		localName: {type: String, "default": '', trim: true}
		txPowerLevel: {type: String, "default": '', trim: true}
		manufacturerData: {type: String, "default": '', trim: true }
		serviceData: {type: String, "default": '', trim: true}
		serviceUuids: [
			uuid: {type: String, "default": '', trim: true}
		]
	}
	rssi: Number
	createAt: { type: Date, "default": Date.now },
	lastModified: { type: Date, "default": Date.now }
)

Device.options.toObject =
	transform: (doc, ret, options) ->
		delete ret.__v;
		delete ret._id;
		ret

deviceModel = mongo.client.model 'Device', Device

Device.plugin(pureautoinc.plugin, {
    model: 'Device',
    field: 'id'
});

module.exports = deviceModel

