cronJob = require('cron').CronJob

logger = require '../log/logger'
conf = require '../conf/config'

DeviceDiscoverySynchronizer = require './device/DeviceDiscoverySynchronizer'

init = () ->
    logger.info "Starting scheduler ..."

    startJob "DeviceDiscovery", conf.scheduler.syncDeviceDiscovery, new DeviceDiscoverySynchronizer().synchronize

    logger.info "Scheduler started ..."

startJob = (jobName, syncJobConf, synchronizeFunction) ->
	logger.info "Starting task 'Sync #{jobName}' with cron expression: '#{syncJobConf.cron}', timezone: '#{syncJobConf.timezone}' and RunOnStart: '#{syncJobConf.runOnStart}'"
	syncJob = new cronJob syncJobConf.cron, synchronizeFunction, syncJobConf.runOnStart, syncJobConf.timezone
	syncJob.start()


module.exports =
	init: init
