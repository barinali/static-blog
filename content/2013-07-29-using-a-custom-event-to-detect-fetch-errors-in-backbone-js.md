---
author: Monica
comments: true
date: 2013-07-29 11:59:40+00:00
layout: post
slug: using-a-custom-event-to-detect-fetch-errors-in-backbone-js
title: Custom event for detecting fetch errors in Backbone.js
wordpress_id: 123
categories:
- JavaScript
- Tech
tags:
- backbone.js
- jquery
---

One of Backbone's major strengths as a javascript MVC framework is the way it helps you do event handling. By extension, it's also great for handling errors that result from failed AJAX calls. As you can see in the [Backbone.js documentation](http://backbonejs.org/#Events-catalog), the `error` event is triggered when a model's attempt to save fails server-side. However, there is no Backbone event that detects when the `fetch` event fails. Since a fetch from the server is the first thing that happens when a page is loaded, you would need to know if it fails because that could indicate that the API is down or some other server error.

<!-- more -->

One way to handle this is that every time you call fetch, you specify an error function. However, this precludes us from being able to organize our failed fetches nicely within Views themselves, as we would with other events that occur on collections such as `add` or `reset`. For example:

    
    <code class="language-javascript">
    MyApp.Views.Foo = Backbone.View.extend({
      'tagName': 'div',
      template: _.template(MyApp.Templates.foo_template),
      initialize: function() {
        MyApp.models.bind('fail', this.show_failure, this);
      },
      render: function() {
        this.$el.html(this.template(this.model.toJSON()));
        return this;
      },
      show_failure: function() {
        // Update DOM to denote failure to fetch models
      }
    });
    </code>



You can trigger a 'fail' event, or any other kind of event, by modifying your base collection. In this case, I am modifying the `fetch` event handler to trigger a `fail` event in the case that it fails.


    
    <code class="language-javascript">
    MyApp.Collections.Base = Backbone.Collection.extend({
      fetch: function(options) {
        var self = this;
        var opts =  { 
          success: function() {
            if (options && options.success)
              options.success(self);
          },
          error: function() {
            // Allow views to respond to failed fetch calls
            self.trigger('fail');
            if (options && options.error)
              options.error(self);
          }	
        };
    
        // Combine options and custom handlers, apply to fetch prototype, call.
        (_.bind(Backbone.Collection.prototype.fetch, this, _.extend({}, options, opts)))();
      }
    });
    </code>



Looking at [Backbone.js annotated source code](http://backbonejs.org/docs/backbone.html#section-55) is really helpful to understand how to override certain functions.
