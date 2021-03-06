/* eslint import/no-unresolved: 0 */
let root;
if (typeof global !== 'undefined') root = global;
else if (typeof window !== 'undefined') root = window;
else root = {};

(function (window) {
  'use strict';

  // util
  window.moment = require('moment');
  window.locale = require('../etc/moment');
  window._ = require('lodash');
  window.Promise = require('bluebird');
  window.fetch = require('isomorphic-fetch');
  window.queryString = require('querystring');


  // jQuery
  window.$ = window.jQuery = require('jquery');
  require('jquery-serializejson');
  // require('materialize-css/dist/js/materialize.js');
  require('jquery.scrollto');

  // riot
  window.riot = require('riot');
  window.riot.route = require('riot-route');
  // window.redux = require('redux');

  // slick
  require('slick-carousel');
  require('slick-lightbox');

  // selectize
  require('selectize');

  // tether
  window.Tether = require('tether');
  window.Drop = require('tether-drop');

  // scrollmagic
  window.ScrollMagic = require('scrollmagic');

  // Leaflet
  require('leaflet');

  // pikaday
  window.Pikaday = require('pikaday');

  // cookie
  window.Cookie = require('js-cookie');
}(root));
