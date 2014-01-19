(function() {

	'use strict';

	/* Application */

	angular.module('ble-manager', [])


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
				.otherwise({ redirectTo: '/' });
			return $httpProvider.responseInterceptors.push('errorHttpInterceptor');
		}])
		.run(['$rootScope', '$http', '$location', function ($rootScope, $http, $location) {
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
						url: "#/devices",
						items: [
							{
								id: 'all',
								name: 'All',
								url: "#/devices"
							}
						]
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
