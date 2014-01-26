mongo = require '../lib/mongo'

pureautoinc = require 'mongoose-pureautoinc'

Device = new mongo.Schema(
	id: Number
	uuid: {type: String, "default": '', trim: true}
	rssi: Number
	advertisement:{
		localName: {type: String, "default": '', trim: true}
		txPowerLevel: {type: String, "default": '', trim: true}
		manufacturerData: {type: String, "default": '', trim: true }
		serviceData: {type: String, "default": '', trim: true}
		serviceUuids: [{
			uuid: {type: String, "default": '', trim: true}
		}]
		beaconData:{
			major: Number
			minor: Number
			measuredPower: Number
			accuracy: Number
			proximity: {type: String, "default": '', trim: true}
		}
		services: [{
			uuid: {type: String, "default": '', trim: true}
			name: {type: String, "default": '', trim: true}
			type: {type: String, "default": '', trim: true}
			characteristics: [{
				uuid: {type: String, "default": '', trim: true}
				name: {type: String, "default": '', trim: true}
				type: {type: String, "default": '', trim: true}
				properties: [{
					type: String, "default": '', trim: true
				}]
				descriptors: [{
					uuid: {type: String, "default": '', trim: true}
					name: {type: String, "default": '', trim: true}
					type: {type: String, "default": '', trim: true}
				}]
			}]
		}]
	}
	createAt: { type: Date, "default": Date.now }
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

