(function() {

    'use strict';

    /* Application */
    angular.module('ble-manager')

        /* Factories */
        .factory('NotificationData', ['$http', function($http) {
            return {
                notifications : function() {
                    return $http({
                        method: 'JSONP',
                        url: '/notifications?callback=JSON_CALLBACK'
                    });
                }
            }
        }])

        /* Controllers */
        .controller('NotificationsCtrl', ['$scope', '$location', 'NotificationData', function ($scope, $location, NotificationData) {
            console.log("Notifications Controller");
            NotificationData.notifications().then(function(response) {
                $scope.notifications = response.data;
                console.log("Notifications", response.data);
            });

            $scope.createNotification = function() {
                $location.path("#/notification/createNotification.html");
            }
        }]);
})();
