+++
date = "2015-12-28T11:41:00-07:00"
title = "Lazy-loading an Angular application in bundles with UI Router and Webpack"
draft = true
+++

## TOC
* [General approach and tradeoffs]({{< relref "#general-approach-and-tradeoffs" >}})
* [Architecture of your Angular application]({{< relref "#architecture-of-your-angular-application" >}})
  * [Component-based vs Traditional]({{< relref "#component-based-vs-traditional" >}})
* [Registering Angular components lazily]({{< relref "#registering-angular-components-lazily" >}})
  * [Keeping our own registry of components]({{< relref "#keeping-our-own-registry-of-components" >}})
* [Bundling templates and populating the `$templateCache`]({{< relref "#bundling-templates-and-populating-the-templatecache" >}})
* [Handling common code]({{< relref "#handling-common-code" >}})
* [Using Webpack's local styles (optional)]({{< relref "#using-webpacks-local-styles-optional" >}})
* [Loading bundles with UI Router]({{< relref "#loading-bundles-with-ui-router" >}})
* [Configuring Webpack]({{< relref "#configuring-webpack" >}})
* [Development and production builds]({{< relref "#development-and-production-builds" >}})
* [Conclusion]({{< relref "#conclusion" >}})

## General approach and tradeoffs

The front-end stack I'll be using to demonstrate this includes:

* AngularJS + UI Router
* Webpack
* Gulp _(depending on application architecture)_

I'll write the examples in ES6 using ES6 modules, but you can also apply this to modules written in AMD or CommonJS format. Since Webpack doesn't yet support the ES6 version of async-loading modules, we have to use the `require.ensure` format regardless.

This approach is not perfect, and has some pros and cons. Briefly:

* **Pros:**
  * Smaller, and therefore faster, initial page load
  * Fewer requests to the server, since most of your code is bundled together
  * Lends itself nicely to a feature-organized codebase
  * Load what you need\*

* **Cons:**
  * It's up to you to organize your code optimally
  * Sometimes you will have to download the same code more than once
  * The dev watch task is WIP &mdash; it works, but with some hacks

My approach to lazy-loading an angular app hinges on the Webpack concept called [code splitting](https://webpack.github.io/docs/code-splitting.html). Basically, the way it works, is that you define the content of a new chunk inside your code &mdash; not by configuration. Here is an example from the Webpack documentation:

    require.ensure(["module-a", "module-b"], function(require) {
      var a = require("module-a");
      // ...
    });

If you put this somewhere in your code, you will see that this affects the output of your build. No longer will "module-a" and "module-b" be in your main, app.js file that Webpack builds for you. Instead, these modules will go into their own "chunk". So long as both these modules aren't used elsewhere by the parent, they will remain only in this chunk, isolated from your main code.

Our basic approach is to put these `require.ensure` blocks inside the `resolve` function, which is available to us from [UI Router](https://github.com/angular-ui/ui-router). Since navigation will not complete until the promises returned by each of the functions passed to `resolve`, this is where we can load our async chunks. 

    $stateProvider.$state('main.componentA', {
        url: '/component-a',
        template: `<component-a></component-a>`,
        resolve: {
          // "load" can be any name
          load: ['$q', function($q) {
            var defer = $q.defer();
            require.ensure([], function(require) {
              /*
              * Your component-a can be a controller, a directive,
              * whatever you need. Discussion on what to require here
              * will follow!
              */
              require('component-a');
              require('component-b');
              require('component-c');
              require('component-d');
              defer.resolve();
            }, 'Bundle-ABCD'); // Final string gives bundle a nice name,
                               // instead just a number.

            return defer.promise;
          }]
        },
      }
    });

## Architecture of your Angular application
The first thing to start thinking about is what belongs in your bundles. **You need to have your application designed in a module-friendly (e.g. component-based) way**. Some discussion about the _why_ and _how_ follows &mdash; feel free to skip if you've already purged standalone templates and controllers from your code. Otherwise, you'll see some ideas for refactoring, but don't worry if your codebase is too far-gone to refactor at once -- **we'll also handle how to lazy-load this "traditional" angular setup as well as component-based.** This is a conversion you can make gradually as well.

Since the premise of this article is how to load your code lazily, it makes sense that the easily way to do this is if all the code for your various routes are grouped together already. Meaning, instead of this:

<pre>
controllers/
services/
filters/
templates/
</pre>

We want something more like this:

<pre>
profile/
  profile.html
  profile-controller.js
  profile-service.js
shop/
  shop.html
  shop-service.js
  products/
    products.html
    product-controller.js
  checkout/
    checkout.html
    checkout-controller.js
</pre>

Perhaps you can already see how nicely the second set of files would translate into a bundle. Imagine that you click on a route like "mywebsite.com/shop/products" and you only have to load the code inside the `products/` folder.

### Component-based vs Traditional
Now, this second example shows a somewhat traditional approach to how you may want to organize your code. You've got a controller, a template, and probably a service. However, this can get a little bit tricky if you think about how we want to lazy-load. Consider our UI-router block again:

```
$stateProvider.$state('main.componentA', {
  'main.profile': {
    url: '/profile',
    templateUrl: '/profile/profile.html',
    resolve: {
      load: ['$q', function($q) {
        var defer = $q.defer();
        require.ensure([], function(require) {
          require('profile/profile-controller');
          defer.resolve();
        }, 'Profile');
        return defer.promise;
      }]
    },
  }
});
```
```
<!-- profile.html -->
<h1>Profile</h1>
<section ng-controller="ProfileController">
  <a-directive></a-directive>
  <b-directive></b-directive>
</section>
```

Perhaps you can already see that there are some tricky things here:

1. Where do you include all the components required by `profile.html`? Imagine the profile consists of several sections -- you either need to:
  * include them with the profile controller (which limits its reusability)

        ```
        import { profileModule } from 'modules';
        import 'profile/a-directive';
        import 'profile/b-directive';

        profileModule.controller('ProfileController', [function()]);
        ```

  * or write them out in the `require.ensure` block, like so:

        ```
        require.ensure([], function(require) {
          require('profile/profile-controller');
          require('profile/a-directive.html');
          require('profile/b-directive.html');
          defer.resolve();
        }, 'Profile'); 
        ```

Both of these are nasty! Plus, you have the problem of the `templateUrl`, which will cause Angular to automatically make an HTTP request **if the template cache isn't populated** -- and in this case, since you haven't loaded the bundle at the time that `templateUrl` is checked, your template cache -- which won't be loaded until the `resolve` -- isn't populated yet.

**Instead, you can make your router nice and your components nice by eliminating standlone controllers and templates.** Alternatively, imagine that your component is organized like this:

```
// profile/profile-component.js

import { profileModule } from 'modules';

import template from 'profile/profile.html';
import 'profile/a-directive';
import 'profile/b-directive';
import 'profile/profile-controller';

profileModule.directive('profile', {
  template,
  controllerAs: 'profile',
  bindToController: true,
  controller: 'ProfileController'
});

```

```
// router.js

const configs = {
  'main.profile': {
    url: '/profile',
    template: `<profile></profile>`,
    resolve: {
      load: ['$q', function($q) {
        var defer = $q.defer();
        require.ensure([], function(require) {
          require('profile/profile-component');
          defer.resolve();
        }, 'Profile');
        return defer.promise;
      }]
    },
  }
};
```

This setup renders you some nice benefits:

* You can re-use the `ProfileController` if you need to, and you won't drag along UI components with it.
* The view itself (also a directive) imports all of the directives that it uses -- which is nice and clear for dependency management. 
* No hassle with templates &mdash; the template comes with the directive that uses it directly.

## Registering Angular components lazily

### Keeping our own registry of components

## Bundling templates and populating the `$templateCache`

## Handling common code

## Using Webpack's local styles (optional)

## Loading bundles with UI Router

## Configuring Webpack

## Development and production builds

# Conclusion
