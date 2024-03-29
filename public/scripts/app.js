(function() {

	'use strict';

	/* Application */

    angular.module("ngScrollTo",[])
        .directive("scrollTo", ["$window", function($window){
            return {
                restrict : "AC",
                compile : function() {

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

	angular.module("ngLink",[])
		.directive('link', ['$location', function($location) {
			return {
				link: function(scope, element, attrs) {
					element.bind('click', function() {
						scope.$apply(function() {
							$location.path(attrs.link);
						});
					});
				}
			}
		}]);

	angular.module('ble-manager', ['ngScrollTo', 'ngLink'])

		/* Config */

		.config(['$routeProvider', '$locationProvider', '$httpProvider', function ($routeProvider, $locationProvider, $httpProvider) {
			$routeProvider
				.when('/', { templateUrl: 'partials/index.html', controller: 'RootCtrl' })
				.when('/login', { templateUrl: 'partials/login.html', controller: 'AuthCtrl' })
				.when('/account', { templateUrl: 'partials/account.html', controller: 'AuthCtrl' })
				.when('/notifications', { templateUrl: 'partials/notifications/list.html', controller: 'NotificationsCtrl' })
				.when('/notifications/create', { templateUrl: 'partials/notifications/create.html', controller: 'NotificationsCtrl' })
				.when('/notifications/update', { templateUrl: 'partials/notifications/update.html', controller: 'NotificationsCtrl' })
				.when('/devices', { templateUrl: 'partials/devices/list.html', controller: 'DevicesCtrl' })
				.when('/devices/create', { templateUrl: 'partials/devices/create.html', controller: 'DevicesCtrl' })
				.when('/devices/update', { templateUrl: 'partials/devices/update.html', controller: 'DevicesCtrl' })
				.when('/devices/discover', { templateUrl: 'partials/devices/discover.html', controller: 'DevicesCtrl' })
				.when('/devices/:id', { templateUrl: 'partials/devices/device.html', controller: 'DeviceCtrl', tab: 'general' })
				.when('/devices/:id/general', { templateUrl: 'partials/devices/device.html', controller: 'DeviceCtrl', tab: 'general' })
				.when('/devices/:id/services', { templateUrl: 'partials/devices/device.html', controller: 'DeviceCtrl', tab: 'services' })
				.otherwise({ redirectTo: '/' });
			return $httpProvider.responseInterceptors.push('errorHttpInterceptor');
		}])
		.run(['$rootScope', '$http', '$location', function ($rootScope, $http, $location) {
			$rootScope.breadcrum = [{label:'Home', url: '/'}];

			$rootScope.$on('event:loginRequired', function () {
				window.location = "/login";
			});
			$rootScope.user = {
				role: "ROLE_ANONYMOUS"
			};
			$http.get('/users/me').success(function (user) {
				user.fullName = user.firstName + " " + user.lastName;
				$rootScope.user = user;
			});

			$rootScope.Auth = {
				user: function() {
					return $rootScope.user;
				},
				isAuthenticated: function () {
					return this.hasNotRole("ROLE_ANONYMOUS");
				},
				isNotAuthenticated: function () {
					return !this.isAuthenticated();
				},
				hasRole: function (role) {
					return  $rootScope.user.role === role;
				},
				hasNotRole: function (role) {
					return  $rootScope.user.role !== role;
				}
			};
		}])

		/* Controllers */

		.controller('RootCtrl', [
			'$scope', '$location', 'ErrorService', function ($scope, $location, ErrorService) {

				$scope.selectedMenuItem = undefined;
				$scope.errorService = ErrorService;

				$scope.selectMenuItem = function(menuItem) {
					console.log("Select MenuItem: [" + menuItem.id + "]");
					$scope.selectedMenuItem = menuItem;
				};

				$scope.$watch('selectedMenuItem', function(newVal, oldVal) {
					console.log(newVal, oldVal);
				});

				$scope.isMenuActive = function(selectedMenuItem, menuItem) {
					console.log("MenuItem is Active ? [" + menuItem.id + "]");
					console.log("Selected MenuItem: [" + selectedMenuItem.id + "]");
					return menuItem.id === selectedMenuItem.id;
				};

				$scope.menus = [
					{
						id: "devices",
						name: "Devices",
						url: "#/devices"
					}
				];

				$scope.selectedMenuItem = $scope.menus[0];

			}
		])

		.controller('SidebarCtrl', function ($scope) {

		})

		.controller('ContentCtrl', function ($scope) {
			$scope.sidebar = 'no';
		})

		.controller('IndexCtrl', function ($scope) {
			$scope.title = "Home";
			$scope.user = user;
			$scope.authenticated = false;
		})


		/* Directives */

		.directive('appVersion', ['version', function (version) {
			return function (scope, elm, attrs) {
				elm.text(version);
			};
		}])
		.directive('alertBar', ['$parse', function ($parse) {
			return {
				restrict: 'A',
				template: '<div class="alert alert-error alert-bar" ng-show="errorMessage">\n	<button type="button" class="close" ng-click="hideAlert()">x</button>\n	{{errorMessage}}\n</div>',
				link: function (scope, elem, attrs) {
					var alertMessageAttr;
					alertMessageAttr = attrs['alertmessage'];
					scope.errorMessage = null;
					scope.$watch(alertMessageAttr, function (newVal) {
						return scope.errorMessage = newVal;
					});
					return scope.hideAlert = function () {
						scope.errorMessage = null;
						return $parse(alertMessageAttr).assign(scope, null);
					};
				}
			};
		}])


		/* Factories */

		.factory('ErrorService', function () {
			return {
				errorMessage: null,
				setError: function (msg) {
					this.errorMessage = msg;
				},
				clear: function () {
					this.errorMessage = null;
				}
			};
		})


		/* Filters */

		.filter('interpolate', ['version', function (version) {
			return function (text) {
				return String(text).replace(/\%VERSION\%/mg, version);
			}
		}])


		/* Services */

		.value('version', '0.1');
})();
