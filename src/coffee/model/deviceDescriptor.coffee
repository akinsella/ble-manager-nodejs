mongo = require '../lib/mongo'

pureautoinc = require 'mongoose-pureautoinc'

DeviceDescriptor = new mongo.Schema(
	id: Number
	uuid: {type: String, "default": '', trim: true}
	name: {type: String, "default": '', trim: true}
	services: [{
		uuid: {type: String, "default": '', trim: true}
		name: {type: String, "default": '', trim: true}
		characteristics: [{
			uuid: {type: String, "default": '', trim: true}
			name: {type: String, "default": '', trim: true}
		}]
	}]
	createAt: { type: Date, "default": Date.now }
	lastModified: { type: Date, "default": Date.now }
)

DeviceDescriptor.options.toObject =
	transform: (doc, ret, options) ->
		delete ret.__v;
		delete ret._id;
		ret

deviceDescriptorModel = mongo.client.model 'DeviceDescriptor', DeviceDescriptor

DeviceDescriptor.plugin(pureautoinc.plugin, {
	model: 'DeviceDescriptor',
	field: 'id'
});

module.exports = deviceDescriptorModel

