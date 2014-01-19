(function() {

   'use strict';

/*
   var user;

   user = {
       firstName: "Alexis",
       lastName: "Kinsella",
       avatarUrl: "images/avatar_placeholder.png",
       fullName: "Alexis Kinsella",
       email: "alexis.kinsella@gmail.com"
   };
*/


   /* Application */

   angular.module('ble-manager')

       /* Controllers */

       .controller('UserDetailsCtrl', function ($scope) {
       })

       .controller('AuthCtrl', function ($scope) {
       })


       /* Factories */

       .factory('errorHttpInterceptor', function ($q, $location, ErrorService, $rootScope) {
           return function (promise) {
               return promise.then(function (response) {
                   return response;
               }, function (response) {
                   if (response.status === 401) {
                       $rootScope.$broadcast('event:loginRequired');
                   } else if (response.status >= 400 && response.status < 500) {
                       ErrorService.setError('Server was unable to find  what you were looking for... Sorry!!');
                   }
                   return $q.reject(response);
               });
           };
       })
       .factory('authHttp', function ($http, Authentication) {
           var authHttp, extendHeaders;
           authHttp = {};
           extendHeaders = function (config) {
               config.headers = config.headers || {};
               return config.headers['Authorization'] = Authentication.getTokenType() + ' ' + Authentication.getAccessToken();
           };
           angular.forEach(['get', 'delete', 'head', 'jsonp'], function (name) {
               return authHttp[name] = function (url, config) {
                   config = config || {};
                   extendHeaders(config);
                   return $http[name](url, config);
               };
           });
           angular.forEach(['post', 'put'], function (name) {
               return authHttp[name] = function (url, data, config) {
                   config = config || {};
                   extendHeaders(config);
                   return $http[name](url, data, config);
               };
           });
           return authHttp;
       });

})();

