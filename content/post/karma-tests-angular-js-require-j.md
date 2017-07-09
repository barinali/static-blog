+++
author = "Monica"
comments = true
date = "2015-02-11 15:53:00+00:00"
slug = "karma-tests-angular-js-require-j"
title = "Karma tests with AngularJS + RequireJS"
tags = ["angular", "require js", "karma", "javascript"]
wordpress_id = 392
+++

Setting up testing is usually a little painful -- but setting up testing when you're using some kind of weird Angular + Require setup is even worse! Furthermore, the Karma documentation is a little bit terse, so it's hard to tell exactly what combination of configuration settings will get you your intended result. Here's how I accomplished this.

# File Hierarchy

Here is a typical, sample hierarchy. My top-level directory is something like /opt/some-app. However, since all of the configurations will use relative paths, this is not really important. All you need to know is that my project root contains "app" as a subdirectory.

<pre>
app/
-- scripts/
--- filters/my_filter.js
--- app.js
--- main.js
-- test/
---- spec/
------ filters/my_filter_spec.js
------ karma.conf.js
------ test-app.js
------ test-main.js
Gruntfile.js
package.json
bower.json
etc.
</pre>

As you can probably deduce, for this post I will discuss how we'll test a filter, which is used in our app. Next let's look at the key files in play here:

* **my_filter.js** The filter we want to test.
* **my_filter_spec.js** The file with our tests in it.
* **app.js** Our Angular module.
* **karma.conf.js** Configuration file, which tell the karma server what files to watch and serve.
* **main.js** vs. **test-main.js** Main.js is our app's real Requirejs configuration, which we want to mirror as closely as possible in `test-main.js`, so that all our `define` statements that work in our app also work in our tests.

# Setting up Angular modules with Require

In general, the thing to remember is that if you want to test something, each AMD module must return the function you want to test, so we can inject it later. I will assume you already have some kind of working Angular+Require setup that you want to test, and will gloss over the details of bootstrapping your core Angular module. Here's just a tiny example of a "requireable" Angular module and a filter.

**1. Review the main.js for your Require setup**
I'm going to assume you're familiar with Require, and only discuss the parts of the Requirejs setup that we need to get testing to work.


<pre><code class="language-javascript">require.config({
  baseUrl: '/scripts',
  paths: {
    angular: '../vendor/angular/angular'  
  },
  shim: {
    angular: { exports: 'angular' }
  }
});
</code></pre>

So you see, we're telling Require to start looking in `scripts/` automatically, so this way, when we define a new module, Require will begin to resolve where to look for a file to include as a dependency by using this baseUrl.

**2. Define a module**
This allows us to define components on a module at runtime. Once we create this module, we'll be able to include it anywhere using `define(['app'], function() { ... })` because main.js knows that "app" really means "scripts/app.js".
    
<pre><code class="language-javascript">/* app/scripts/app.js */

define(['angular'], function(angular) {
  var module = angular.module('app', []);
  module.config([
    '$controllerProvider',
    '$compileProvider', 
    '$filterProvider', 
    '$provide',
    function($controllerProvider, $compileProvider, $filterProvider, $provide) {
      module.controller = $controllerProvider.register;
      module.directive = $compileProvider.directive;
      module.filter = $filterProvider.register;
      module.factory = $provide.factory;
      module.service = $provide.service;
     }
 ]);

 return module;

});</code></pre>

**3. Create a filter, register it on the module**

<pre><code class="language-javascript">/* app/scripts/filters/my_filter.js */

define(['app'], function(app) {
   
  var FILTER_NAME = 'myFilter';
  var filter = function() {
    return function(input, option) {
      return input + option;
    }
  };
  
  app.filter(FILTER_NAME, filter);
  return filter;
   
});</code></pre>

Okay, so now you have the three main "normal" components needed for this example: 

  1. main.js
  2. my_filter.js
  3. app.js

Now we create the "testing" counterparts: 

  1. test-main.js
  2. my_filter_spec.js

...and of course, the Karma configuration itself.

# Karma.conf.js

Now is a good time to install Karma and its variable components if you haven't already.

```
npm install karma karma-jasmine karma-phantomjs-launcher karma-requirejs --save-dev
npm install -g karma-cli
```

You can now navigate to `app/test/` and run:

```
karma init
```
When one of the prompts asks you whether you're using RequireJS, say YES. This will generate the bases of our two important configuration files: `karma.conf.js` and `test-main.js`. Naturally, they won't work out of the box, but we'll get there.

Start by opening `karma.conf.js`. This file has a bunch of interesting settings, which we will discuss in turn. First, I'll show you the working configuration for our sample project:

<pre><code class="language-javascript">module.exports = function(config) {
  config.set({
    basePath: '../..',
    frameworks: ['jasmine', 'requirejs'],
    files: [
      'app/test/test-main.js',
      { pattern: 'app/vendor/**/*.js', included: false },
      { pattern: 'app/scripts/**/*.js', included: false },
      { pattern: 'app/test/spec/**/*.js', included: false }
    ],
    exclude: [],
    preprocessors: {},
    reporters: ['progress'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_DEBUG,
    autoWatch: true,
    browsers: ['PhantomJS'],
    singleRun: false
  });
};
</code></pre>

Most importantly, we care about **basePath**.  We want this to be the route of our project, so that Karma can find our angular files, vendor files, and test files, and **serve them to Require**. This is the critical point. Only files that are served by Karma can be found during testing, when Require is trying to pull together your dependencies. This is why, for example, we have the following line in `files`:

<pre><code class="language-javascript">{ pattern: 'app/vendor/**/*.js', included: false }
</code></pre>

Because without this, when we setup test-main.js, we will get 404 WARN's when trying to load Angular. **As a rule, any file that you want to test, or that is a dependency of a file you want to test, must be picked up by Karma by matching an entry in "files".**

I heightened the `logLevel` so we'll get more verbose output during debugging, and turned `autoWatch` to true, so that any changes to test-main.js are picked up. If you make changes to `karma.conf.js`, you will have to kill Karma and start the process again for it to consider these changes.

Time for the first test! Try running karma with your configuration file. It should spit out a biiiiig long list of all the files that you've told it to serve (especially because of the `config.LOG_DEBUG` setting).

```
karma start app/test/karma.conf.js
```

You should get output which says that it loaded your configuration file. If you get an error that it could not find the configuration file, make sure the file path after "karma start" is correct. I am running this from my top-level directory (/opt/some-app).

Now you can open up your browser at `http://localhost:9876`. If your `karma start` command is still running, you should see a cheerful green banner at the top of the screen.

# test-main.js

Think of `test-main.js` as a way of overriding `main.js` for the purpose of testing. This way, all your files keep the same `define` statements, but they're actually "looking somewhere else" for the purpose of testing.

First things first: **The default karma+requirejs setup is wrong**. Particularly, the way it decides how the files being passed to `deps` should be formatted. You will see a function called `fileToModule`. DELETE IT. This tries to truncate the .js extension of your test files, which we actually don't want it to do, because Karma actually make an HTTP request for `my_filter_spec` instead of `my_filter_spec.js`. Try this instead for collecting the test files:

<pre><code class="language-javascript">var allTestFiles = [];
var TEST_REGEXP = /(_spec|_test)\.js$/i;
for (var file in window.__karma__.files) {
  if (TEST_REGEXP.test(file)) allTestFiles.push(file);
}
</code></pre>

The next important part of this file is **baseUrl**. This is the long long loooong lost sibling of **basePath** in `karma.conf.js` -- it's difficult to imagine when you're looking at them, but they're working together in some mysterious way. 

For us, the following pairing works:
    
<pre><code class="language-javascript">
/* karma.conf.js */
basePath: '../..'

/* test-main.js */
baseUrl: '/base/app/scripts'
</code></pre>

This is because karma is serving our entire top-level directory at `/base`. So, to mirror our normal `main.js`, which has `baseUrl: '/scripts'`, in `test-main.js` we put `'/base/app/scripts'`. **So in both of our configurations for Require.js, Require is using our "scripts/" folder as a starting point.**

Following this logic, we can re-define where we want our paths in test-main to come from:

    /* app/test/test-main.js */
    
    require.config({
      baseUrl: '/base/app/scripts',
      deps: allTestFiles,
      callback: window.__karma__.start,
      paths: {
        angular: '/base/app/vendor/angular/angular'
      },
      shim: {
        angular: { exports: 'angular' }
      }
    });
    

Now this means, when we have a file with the following header:
    
    define(['path/to/somewhere'], function() { });

When it is loaded using `main.js`, "path/to/somewhere" will load _http://localhost:8080/scripts/path/to/somewhere_ from your normal webserver. When using `test-main.js`, the same file will require _http://localhost:9876/base/app/scripts/path/to/somewhere_ from karma. Meaning, the code can be used for running the app or for testing, with no modifications of the dependency paths in individual files!



# Our first spec file


Now we finally get to try to tie everything together with our first spec file. Start off by installing `angular-mocks`, as this will allow us to register our filter before we test it.

    npm install angular-mocks --save-dev

Add this to your `test-main.js` file under "paths":

    paths: {
      angular: '/base/app/vendor/angular/angular',
      angularMocks: '/base/app/vendor/angular-mocks/angular-mocks'
    },
    shim: {
      angular: { exports: 'angular' },
      angularMocks: { deps: ['angular'] }
    }

Once we include angularMocks as a dependency, we'll have `angular.mock` available on our instance of angular. We can use this to construct components on the fly as we test.

    /* app/tests/spec/filters/my_filter_spec.js */
    
    define(['angular',
      'filters/my_filter', 
      'angularMocks'], 
      function(angular, myFilter) {
        
        describe('myFilter', function() {
          
          // Here we register the function returned by the myFilter AMD module
          beforeEach(angular.mock.module(function($filterProvider) {
            $filterprovider.register('myFilter', myFilter);
          }));
    
          // Our first test!!!!
          it('should not be null', inject(function($filter) {
            expect($filter('myFilter')).not.toBeNull();
          }));
    
        });
      }
    );

Now it's time to `karma start` our tests!! You should see a very exciting message:
    
    INFO [karma]: Karma v0.12.31 server started at http://localhost:9876/
    INFO [launcher]: Starting browser PhantomJS
    INFO [PhantomJS 1.9.8 (Mac OS X)]: Connected on socket W9ErxZ86IapgwQqqNiPw with id 48168125
    PhantomJS 1.9.8 (Mac OS X): Executed 1 of 1 SUCCESS (0.004 secs / 0.027 secs)

Once this works, you can go ahead and write a real test:
    
    it("should concatenate strings", inject(function($filter) {
      expect($filter('myFilter')('a', 'b')).toBe('ab');
    });

* * *

# Conclusion

Clearly, this is just the tip of the iceberg, and there is a lot more work to be done to have a well-tested codebase with a combination of Angular and Require. Here are some additional resources on working with unit testing in an Angular+Require environment:

* [Testing AngularJS in a RequireJS environment](http://engineering.radius.com/post/77677879234/testing-angularjs-in-a-requirejs-environment)
* Contains some good information about testing directives, filters, and controllers. For whatever reason, they are able to use the module exported by angularMocks, whereas I have to use `angular.mock`.

* * *

## Questions, Comments, Corrections?

Get in touch via Twitter at [@monicalent](http://www.twitter.com/monicalent).
