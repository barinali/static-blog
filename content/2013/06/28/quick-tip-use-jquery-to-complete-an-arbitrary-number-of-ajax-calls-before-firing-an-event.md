+++
author = "Monica"
comments = true
date = 2013-06-28 16:40:14+00:00
layout = post
slug = quick-tip-use-jquery-to-complete-an-arbitrary-number-of-ajax-calls-before-firing-an-event
title = 'Quick Tip = Use jQuery to Complete an Arbitrary Number of AJAX Calls Before
  Firing an Event'
wordpress_id = 112
categories:
- JavaScript
- Tech
tags:
- ajax
- jquery
+++

Somewhat recently, I encountered an issue where my expected user input is an arbitrarily long list of words. While I could get the word count, I had no reliable way to know whether all of the ajax requests had been completed before firing an event that created a list of definitions for each word. I had several realizations in my quest:



	
  1. I could do the entire process synchronously. However, this meant that one bad ajax return or error could cause the entire process to hang. It also meant that slow and intensive requests would cause the application to perform especially poorly as well.

	
  2. Doing a simple for-loop of ajax requests would definitely not work, because the entire control structure would be done evaluating before even the first request completed.

	
  3. I couldn't keep an internal counter, because the data returned by ajax's success method basically gets eaten by the larger ajax object, which returns a deferred object. I had no way of passing an integer into the ajax object and then getting it back out.

	
  4. Since I wanted to do this asynchronously, I also couldn't guarantee which ajax request would complete last, even if it was at the end of my list of requests to fire.


Here is a simple way to address this problem, using jQuery.

<!-- more -->


    
    <code class="language-javascript">// Inside the ajax call here, deal with the success and errors states for each call. 
    // Refer to <a href="http://api.jquery.com/jQuery.ajax/" target="_blank">jQuery's documentation on $.ajax</a> if unfamiliar with it.
    
    var ajax_caller = function(data) {
        return $.ajax({
            url: data.url, 
            method: data.method
        });
    }</code>




    
    <code class="language-javascript">// Create an array of <a href="http://api.jquery.com/category/deferred-object/" target="_blank" title="jQuery Documentation for Deferred Objects">deferred objects</a>
    
    var ajax_calls = [];
    for (var i = 0; i < arbitrary_number; i++)
        ajax_calls.push(ajax_caller({
            url: '/api/endpoint/' + i,
            method: 'GET'
        }));</code>




    
    <code class="language-javascript">// <a href="http://api.jquery.com/jQuery.when/" target="_blank" title="jQuery Documentation for $.when">$.when</a> takes a comma separated list of deferred objects.
    // Apply unpacks array into a suitable list for $.when to handle.
    
    $.when.apply(this, ajax_calls).done(function() {
        // Event to be fired after all ajax calls complete
    });</code>
