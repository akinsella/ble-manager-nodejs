(function() {

    'use strict';


	angular.module("ngScrollTo",[])
		.directive("scrollTo", ["$window", function($window){
			return {
				restrict : "AC",
				compile : function(){

					var document = $window.document;

					function scrollInto(idOrName) {//find element with the give id of name and scroll to the first element it finds
						if(!idOrName)
							$window.scrollTo(0, 0);
						//check if an element can be found with id attribute
						var el = document.getElementById(idOrName);
						if(!el) {//check if an element can be found with name attribute if there is no such id
							el = document.getElementsByName(idOrName);

							if(el && el.length)
								el = el[0];
							else
								el = null;
						}

						if(el) //if an element is found, scroll to the element
							el.scrollIntoView();
						//otherwise, ignore
					}

					return function(scope, element, attr) {
						element.bind("click", function(event){
							scrollInto(attr.scrollTo);
						});
					};
				}
			};
		}]);

	/* Application */
    angular.module('ble-manager', ['ngScrollTo'])

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
		.controller('DeviceCtrl', ['$scope', '$location', '$anchorScroll', '$routeParams', 'DeviceData', function ($scope, $location, $anchorScroll, $routeParams, DeviceData) {
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
			    if (!date) {
				    return undefined;
			    }
			    console.log("Date to reformat: ", date);
			    return moment(date, "YYYY-MM-DDTHH:mm:ss.Z").format("YYYY-MM-DD HH:mm:ss")
		    };

		    $scope.deviceId = $routeParams.id;
			$scope.fetchDevice();
		}]);

})();
