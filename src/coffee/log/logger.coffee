fs = require 'fs'
mkdirp = require 'mkdirp'
moment = require 'moment'
winston = require 'winston'

loggerConfig =
	levels:
		debug: 0
		info: 1
		warn: 2
		error: 3

	colors:
		debug: 'blue'
		info: 'green'
		warn: 'yellow'
		error: 'red'

	transports:
		console:
			level: 'debug'
			colorize: true
			pattern: "YYYY-MM-SS HH:MM:SS.sss"
		file:
			dir: "#{__dirname}/logs"
			filename: "logs.log"
			level: 'debug'
			json: false
			pattern: "YYYY-MM-SS HH:MM:SS.sss"
			maxsize: 1024 * 1024 * 10

winston.addColors(loggerConfig.colors)

if (!fs.existsSync("#{loggerConfig.transports.file.dir}"))
	mkdirp.sync("#{loggerConfig.transports.file.dir}")

console.log("Logging to file: '#{loggerConfig.transports.file.dir}/#{loggerConfig.transports.file.filename}'");

logger = new (winston.Logger)(
	level: "debug"
	levels: loggerConfig.levels
	transports: [
		new (winston.transports.Console)({
			level: loggerConfig.transports.console.level,
			levels: loggerConfig.levels,
			colorize: loggerConfig.transports.console.colorize,
			timestamp: () ->
				moment(Date.now()).format(loggerConfig.transports.console.timestamp)
		})
	]
)

module.exports = logger

#logger.debug("Testing 'debug' log level")
#logger.info("Testing 'info' log level")
#logger.warn("Testing 'warn' log level")
#logger.error("Testing 'error' log level")

###
		,
		new (winston.transports.File)({
			filename: "#{loggerConfig.transports.file.dir}/#{loggerConfig.transports.file.filename}",
			level: loggerConfig.transports.file.level,
			levels: loggerConfig.levels,
			colorize: loggerConfig.transports.file.colorize,
			json: loggerConfig.transports.file.json
			timestamp: () -> moment(Date.now()).format(loggerConfig.transports.file.timestamp)
		})
###
