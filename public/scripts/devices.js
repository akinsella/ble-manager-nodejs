(function() {

    'use strict';

    /* Application */
    angular.module('ble-manager')

        /* Factories */
        .factory('DeviceData', ['$http', function($http) {
            return {
                devices : function() {
                    return $http({
                        method: 'JSONP',
                        url: '/devices?callback=JSON_CALLBACK'
                    });
                }
            }
        }])


        /* Controllers */
        .controller('DevicesCtrl', ['$scope', 'DeviceData', function ($scope, DeviceData) {
                console.log("Devices Controller");
                DeviceData.devices().then(function(response) {
                    $scope.devices = response.data;
                    console.log("Devices", response.data);
                });
            }
        ]);

})();
