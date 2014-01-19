_ = require('underscore')._

if !config
	localConfig =
		apiVersion: process.env.API_VERSION
		offlineMode: process.env.OFFLINE_MODE == "true"
		hostname: process.env.APP_HOSTNAME
		port: process.env.APP_HTTP_PORT
		appname: 'ble-manager.helyx.org'
		devMode: process.env.DEV_MODE == "true"
		verbose: true
		processNumber: process.env.INDEX_OF_PROCESS || 0
		admin:
			email: process.env.ADMIN_EMAIL
		scheduler:
			syncDeviceDiscovery:
#				cron: '0 10,30 * * * 1-7'
				cron: '0,30 * * * * 1-7'
				timezone: "Europe/Paris"
				runOnStart: true
		auth:
			google:
				callbackUrl: process.env.AUTH_GOOGLE_CALLBACK_URL || 'http://localhost'
				realm: process.env.AUTH_GOOGLE_REALM || 'localhost'
		apns:
			enabled: true
			devMode: process.env.APNS_SANDBOX_ENABLED
		mongo:
			dbname: process.env.MONGO_DBNAME || "ble-manager"
			hostname: process.env.MONGO_HOSTNAME || "localhost"
			port: process.env.MONGO_PORT || 27017
			username: process.env.MONGO_USERNAME # 'ble-manager'
			password: process.env.MONGO_PASSWORD # 'Password123'
		monitoring:
			newrelic:
				apiKey: process.env.NEW_RELIC_API_KEY
				appName: process.env.NEW_RELIC_APP_NAME
			strongOps:
				apiKey: process.env.STRONG_OPS_API_KEY
			nodetime:
				apiKey: process.env.NODETIME_API_KEY
		feature:
			stopWatch: true
	config = _.extend({}, localConfig)

module.exports =
	apiVersion: config.apiVersion
	offlineMode: config.offlineMode
	devMode: config.devMode
	verbose: config.verbose
	hostname: config.hostname
	processNumber: config.processNumber
	port: config.port
	appname: config.appname
	auth: config.auth
	uri: config.uri
	mongo: config.mongo
	monitoring: config.monitoring
	feature: config.feature
	scheduler: config.scheduler
	apns: config.apns
	admin: config.admin




