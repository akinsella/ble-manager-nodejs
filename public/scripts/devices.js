(function() {

    'use strict';


	/* Application */
    angular.module('ble-manager')
        /* Factories */
        .factory('DeviceData', ['$http', function($http) {
            return {
	            devices : function() {
		            return $http({
			            method: 'GET',
			            url: '/devices'
		            });
	            },
	            deviceWithId : function(deviceId) {
		            return $http({
			            method: 'GET',
			            url: '/devices/' + deviceId
		            });
	            },
	            deleteDeviceWithId : function(deviceId) {
		            return $http({
			            method: 'DELETE',
			            url: '/devices/' + deviceId
		            });
	            },
	            discover : function() {
		            return $http({
			            method: 'GET',
			            url: '/devices/discover'
		            });
	            },
	            fetchDeviceDescriptorByDevice:function(deviceUuid) {
		            return $http({
			            method: 'GET',
			            url: '/devices/' + deviceUuid + '/descriptor'
		            });
	            },
	            read : function(deviceUuid, serviceUuid, characteristicUuid, timeout) {
		            return $http({
			            method: 'GET',
			            url: '/devices/' + deviceUuid + '/services/' + serviceUuid + '/characteristics/' + characteristicUuid + '?timeout=2000'
		            });
	            }

            }
        }])


	    /* Controllers */
	    .controller('DevicesCtrl', ['$scope', 'DeviceData', function ($scope, DeviceData) {
		    console.log("Devices Controller");

		    $scope.fetchDevices = function() {
			    console.log("Fetching devices started");
			    DeviceData.devices().success(function(data, status, headers, config) {
				    console.log("Fetching devices ended");
				    $scope.devices = data;
				    console.log("Devices", data);
			    });
		    };

		    $scope.loading = false;

		    $scope.discoverDevices = function() {
			    console.log("Discovering devices started");
			    $scope.loading = true;
			    DeviceData.discover().success(function(data, status, headers, config) {
				    console.log("Discovering devices ended with response: " + data);
				    $scope.loading = false;
				    $scope.fetchDevices();
			    });
		    };

		    $scope.deleteDevice = function(device) {
			    DeviceData.deleteDeviceWithId(device.id).success(function(data, status, headers, config) {
				    $scope.fetchDevices();
			    });
		    };

		    $scope.fetchDevices();
	    }])

		/* Controllers */
		.controller('DeviceCtrl', ['$scope', '$rootScope', '$location', '$anchorScroll', '$route', '$routeParams', 'DeviceData', function ($scope, $rootScope, $location, $anchorScroll, $route, $routeParams, DeviceData) {
			console.log("Device Controller");

		    $scope.tabSelected = $route.current.tab == 'general' ? 'general' : 'services';
		    $scope.deviceId = $routeParams.id;

		    $scope.fetchDevice = function() {
			    console.log("Fetching device with id '" + $scope.deviceId + "' started");
			    DeviceData.deviceWithId($scope.deviceId)
				    .success(function(device, status, headers, config) {
					    console.log("Fetching device ended");
					    $scope.device = device;
					    console.log("Device", device);
					    $scope.selectService(device.advertisement.services[0]);
					    $scope.computeBreadcrum();
					    $scope.deviceDescriptorByDevice(device)
				    });
		    };

		    $scope.reformatDate = function(date) {
			    if (!date) {
				    return undefined;
			    }
			    console.log("Date to reformat: ", date);
			    return moment(date, "YYYY-MM-DDTHH:mm:ss.Z").format("YYYY-MM-DD HH:mm:ss")
		    };

		    $scope.selectService = function (service) {
			    $scope.selectedService = service;
			    $scope.selectCharacteristic(service.characteristics[0]);
			    console.log("Selected service: ", service.uuid);
			    $scope.computeBreadcrum();
		    };

		    $scope.selectCharacteristic = function (characteristic) {
			    $scope.selectedCharacteristic = characteristic;
			    console.log("Selected characteristic: ", characteristic.uuid);
			    $scope.computeBreadcrum();
		    };

		    $scope.computeBreadcrum = function () {
				$rootScope.breadcrum = [
					{ label: 'Devices', url: '/devices' },
					{ label: $scope.device.advertisement.localName || $scope.device.uuid, url: '/devices/' + $scope.device.id },
					{ label: $scope.tabSelected == 'general' ? 'General' : 'Services', url: '/devices/' + $scope.device.id + '/' + $scope.tabSelected }
				];

			    if ($scope.tabSelected == 'services') {
				    [
					    { label: $scope.selectedService.uuid + ' - ' + $scope.selectedService.name || $scope.selectedService.uuid, url: '/devices/' + $scope.device.id },
					    { label: $scope.selectedCharacteristic.uuid + ' - ' + $scope.selectedCharacteristic.name || $scope.selectedCharacteristic.uuid, url: '/devices/' + $scope.device.id }
				    ].forEach(function(breadcrumItem) {
						$rootScope.breadcrum.push(breadcrumItem);
					});
			    }
		    };

		    $scope.executeCharacteristicProperty = function(device, service, characteristic, property) {
			    if (property == 'read') {
				    $scope.readCharacteristic(device, service, characteristic);
			    }
		    };

		    $scope.readCharacteristic = function(device, service, characteristic) {
			    DeviceData.read(device.uuid, service.uuid, characteristic.uuid, 2000)
				    .success(function(response, status, headers, config) {
					    console.log("Fetching device characteristic ended");
					    $scope.read.putDevice(device);
					    $scope.read.devices[device.uuid].putService(service);
					    $scope.read.devices[device.uuid].services[service.uuid].characteristics[characteristic.uuid] = response.data;
				    });
		    };

		    $scope.read = {
			    devices: [],
			    putDevice: function(service) {
			        this.devices[service.uuid] = this.devices[service.uuid] || {
				        services: [],
				        putService: function(service) {
					        this.services[service.uuid] = this.services[service.uuid] || {
						        characteristics: []
					        }
				        }
			        }
		        }
		    };

		    $scope.deviceDescriptors = {};

		    $scope.deviceDescriptorByDevice = function(device) {
			    console.log("Fetching device descriptor started");
			    if (!$scope.deviceDescriptors[device.uuid]) {
				    DeviceData.fetchDeviceDescriptorByDevice(device.uuid).success(function(data, status, headers, config) {
					    console.log("Fetching device descriptor ended");
					    $scope.deviceDescriptors[device.uuid] = data;
					    console.log("Device Descriptor: '", data, "'");
				    });
			    }
		    };

		    $scope.serviceNameUsingDeviceDescriptor = function(deviceUuid, serviceUuid) {
			    if (!$scope.deviceDescriptors) {
				    return $scope.deviceDescriptors;
			    }

			    var deviceDescriptor = $scope.deviceDescriptors[deviceUuid];
			    if (!deviceDescriptor) {
				    return undefined;
			    }

			    var services = deviceDescriptor.services;
			    if (!services) {
				    return undefined;
			    }

			    var service = _(services).find(function(service) {
				    return service.uuid == serviceUuid;
			    });

			    if (!service) {
				    return undefined;
			    }

			    return service.name;
		    };

		    $scope.serviceLabel = function(device, service) {
			    if (service) {
				    var serviceName = service.name != undefined ? service.name : $scope.serviceNameUsingDeviceDescriptor(device.uuid, service.uuid);
				    return serviceName ? service.uuid + " - " + serviceName : service.uuid;
			    }
			    else {
				    return undefined;
			    }
		    };

		    $scope.fetchDevice();

		}]);

})();
