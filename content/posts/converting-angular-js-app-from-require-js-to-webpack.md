+++
author = "Monica"
type = "post"
comments = true
tags = ["angular", "webpack", "require js"]
date = "2015-08-03 18:29:56+00:00"
slug = "converting-angular-js-app-from-require-js-to-webpack"
title = "Converting an Angular.js app from Require.js to Webpack"
wordpress_id = 433
+++

I've recently converted my webapp at work from Require.js to webpack, and although the initial setup was a little tricky, it clearly offers numerous benefits to make the switch when it comes to performance, loading times, and development workflow. In this post, I will only cover a basic switch from Require.js to Webpack. In a following post, I'll go into lazy-loading with webpack and ui-router.

## Possible Require.js setups, and their pitfalls

In essence, there are two basic setups you can have for your Require.js if you plan to use lazy-loading. One where you try to bundle your code by module, and another where you make a request for every component required by file. Here's an example:

**Option 1: Require everything needed on a component-basis.**

<pre><code class="language-javascript">
/*
 * Presume 'app' is an angular module, and the other included files are
 * other Angular services.
 */
// FILE: feed/news_feed_service.js
define(['app', 'some/dependency', 'common/other_dep'], function() {
   var SERVICE_NAME = 'myService';
   Service.$inject = ['SomeDependency', 'OtherDep'];
   function Service(SomeDependency, OtherDep) {
      // Do something
   });
   app.service(SERVICE_NAME, Service);
});
</code></pre> 

<pre><code class="language-javascript">
// FILE: app.js
define([], function() {
   var md = angular.module('NewsFeed', []);
   md.config([
      '$controllerProvider',
      '$compileProvider',
      '$filterProvider',
      '$provide',
      function($controllerProvider, $compileProvider, $filterProvider,
      $provide) {
        md.controller = $controllerProvider.register;
        md.directive = $compileProvider.directive;
        md.filter = $filterProvider.register;
        md.factory = $provide.factory;
        md.service = $provide.service;
      }
    ]);
   return md;
});
</code></pre>

Pros:

* You only require what you need. So the first time you use this service, you will only get the service and its direct dependencies.

Cons:

* The number of requests will be mind-blowing for something like, say, a controller, that is requiring a couple services, which all also have dependencies.
* Number of requests is not solved by the build, because you would have to denote many many modules in the build process, and Require.js has no way of knowing what is already included by your app, so you run a high risk of loading a lot of duplicate data.

**Option 2: Require all your components into a module index.**

<pre><code class="language-javascript">
  // FILE: feed/news_feed_service.js
  define(['some/dependency', 'common/other_dep'], function() {
     var SERVICE_NAME = 'NewsFeedService';
     Service.$inject = ['SomeDependency', 'OtherDep'];
     function Service(SomeDependency, OtherDep) {
        // Do something
     });
     return {
       name: SERVICE_NAME,
       component: Service
     };
  });
</code></pre>
    
<pre><code class="language-javascript">
  // FILE: app.js
  define(['feed/news_feed_service'], function(service) {
     var md = angular.module('NewsFeed', []);
     md.config([
        '$controllerProvider',
        '$compileProvider',
        '$filterProvider',
        '$provide',
        function($controllerProvider, $compileProvider, $filterProvider,
        $provide) {
          md.controller = $controllerProvider.register;
          md.directive = $compileProvider.directive;
          md.filter = $filterProvider.register;
          md.factory = $provide.factory;
          md.service = $provide.service;
        }
      ]);
      md.service(service.name, service.component);
  });
</code></pre>

Pros:
  
* In your build step, you can specify each module, and Require.js will bundle it together. So you don't have the problem of making a bunch of requests.

Cons:
  
* Dependencies between modules gets tricky. You have to make sure the other modules are loaded, but you don't want to include them in the define() of your module index, because you will end up bundling in a lot of duplicate code. Even using 'exclude' and 'shallowExclude' options in the Require.js does not solve this, because you then have to manage loading all the dependencies of your app, making the routing code more complex.
* You're always going to get code that you don't need right away. It also can be inconvenient to make your modules granular enough to bring down the bundle size. Every module could end up with its own shared submodule, and so on. Eventually you are spending more time organizing and splitting your code than writing it. And with every "tiny module" you make, you have to adjust the build, and you'll need more requests.

## Brief intro to Webpack for Require.js-users

Enter webpack. It's actually been around since about 2012, and has a lot of hype surrounding it as of late, especially with the presentation by Pete Hunt on [How Instagram.com works](https://www.youtube.com/watch?v=VkTCL6Nqm6Y). 

What webpack can do:

* Traverse the dependency tree of your app and serve "chunks" of code (tiny .js files), based on "split points" that you put in your code. Read: Only necessary code, but usually in one request.
* You can effect the output files more by the architecture of your code, rather than a complex build process.
* Many other bonus features: Replace your grunt tool, parse and bundle SCSS, transpile your code from ES6 to ES5, populate your ng-cache, and much more!!

## Comparing main.js to webpack.config.js: Convert your app by changing a single file!

Ok, let's get on to the practical stuff. How can you convert your app from Require.js to Webpack in one shot? Well, a big part of that depends on how your Require.js is setup. If you are bundling most things into your initial app.js, you're in luck -- that's the easiest case to convert. Otherwise, you may have to make some adjustments.

Start by installing webpack, of course:

<pre><code class="bash">npm install webpack -g</code></pre>

Here are an equivalent main.js and webpack.config.js (+ a bootstrap file):

File structure:
    
<pre>
root/
--- app/
------ scripts/
--------- main.js
--------- app.js
------ vendor/
--- dist/
------ scripts/
</pre>
    
<pre><code class="language-javascript">
require.config({
  baseUrl: '/scripts',
  paths: {
    angular: '../vendor/angular/angular',
    lodash: '../vendor/lodash/lodash',
    angularRoute: '../vendor/angular-ui-router/release/angular-ui-router',
    moment: '../vendor/moment/min/moment-with-locales.min',
    'angular-moment': '../vendor/angular-moment/angular-moment',
  },
  shim: {
    angular: {
      exports: 'angular'
    },
    angularRoute: {
      deps: ['angular']
    },
    'angular-moment': {
      deps: ['angular', 'moment']
    },
    lodash: {
      exports: '_'
    }
  }
});

require(['app'], function() {
  'use strict';
  angular.bootstrap(document, ['Dashboard']);
});
</code></pre>

File structure:
    
<pre>
root/
--- webpack.config.js
--- app/
------ scripts/
--------- bootstrap.js
---------  app.js
------ vendor/
--- dist/
------ scripts/
--------- app.js (built by webpack)
</pre>
   
<pre><code class="language-javascript">var webpack = require('webpack');
var path = require('path');

module.exports = {
  context: __dirname + '/app/scripts',
  entry: {
    app: 'bootstrap.js'
  },
  output: {
    path: __dirname + '/dist/scripts',
    filename: '[name].js',
    publicPath: '/scripts/'
  },
  plugins: [
    new webpack.ProvidePlugin({
      _: 'lodash'
    })
  ],
  module: {
    loaders: [
      { test: /[\/]angular\.js$/, loader: "exports?angular" }
    ]
  },
  resolve: {
    extensions: ['', '.js'],
    root: [ __dirname + '/app/scripts' ],
    alias: {
      angular: __dirname + '/app/vendor/angular/angular',
      lodash: __dirname + '/app/vendor/lodash/lodash',
      angularRoute: __dirname + '/app/vendor/angular-ui-router/release/angular-ui-router',
      moment: __dirname + '/app/vendor/moment/min/moment-with-locales.min',
      'angular-moment': __dirname + '/app/vendor/angular-moment/angular-moment',
    }
  }
};
</code></pre>
    
<pre><code class="language-javascript">require('angular');
require('./app');

angular.bootstrap(document, ['Dashboard']);
</code></pre>

Now, in both cases, you would end up with an app.js made by Require JS, and an app.js made by Webpack. Unlike require.js where you have to first load require.js, which then loads main.js, and boostraps your app, in Webpack you can just put your app.js in the script tag and it runs. Perhaps not a huge optimization, but it is one less request!

If your Require.js app is loaded lazily, and not ultimately all bundled into a single app.js, then you will have to wait until my follow-up post on lazy-loading Angular apps with webpack! It will also included information as impact webpack can have on your Angular build process, specifically regarding template loading and handling assets like SVGs.

* * *

## Questions, Comments, Corrections?

Get in touch via Twitter at [@monicalent](http://www.twitter.com/monicalent).
