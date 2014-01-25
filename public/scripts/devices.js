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
		.controller('DeviceCtrl', ['$scope', '$routeParams', 'DeviceData', function ($scope, $routeParams, DeviceData) {
			console.log("Device Controller");

		    $scope.fetchDevice = function() {
			    console.log("Fetching device with id '" + $scope.deviceId + "' started");
			    DeviceData.deviceWithId($scope.deviceId).success(function(data, status, headers, config) {
				    console.log("Fetching Ddevice ended");
				    $scope.device = data;
				    console.log("Devices", data);
			    });
		    };

		    $scope.reformatDate = function(date) {
			    return moment(date, "YYYY-MM-DDTHH:mm:ss.Z").format("YYYY-MM-DD HH:mm:ss")
		    };

		    $scope.deviceId = $routeParams.id;
			$scope.fetchDevice();
		}]);

})();
