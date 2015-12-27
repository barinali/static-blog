---
author: Monica
comments: true
date: 2014-08-10 12:02:59+00:00
layout: post
slug: internationalization-with-django-backbone-underscore-template-and-sass-ltr-and-rtl-languages
title: Internationalization with Django, Backbone, Underscore templates, and Sass
  (LTR and RTL languages)
wordpress_id: 288
categories:
- CSS
- Internationalization
- JavaScript
- Localization
- Python
- Sass
- Tech
---

Let's be honest: No developer wakes up in the morning and thinks, "Oh goody! Today I get to internationalize my giant website with tons of content and files. I bet supporting right-to-left languages is going to be a blast." 

**However, I'm here to tell you that it's not nearly as bad as you would expect.** 

In fact, Django makes it downright easy to do. Unfortunately, there's not a lot of information on the web about internationalizing (also known as **i18n**) in Django besides [the official documentation](https://docs.djangoproject.com/en/dev/topics/i18n/). Hopefully these tips and tricks will be useful for you.



# What Django gives you





	
  * Preferred language of the user, and uses the files you generate to serve translated and localized templates.

	
  * Gives you tools for translating strings in both HTML files (i.e. templates) and Javascript files.

	
  * Gives you helpful variables in your templates to help you serve the correct content for left-to-right and right-to-left users.



<!-- more -->



# Step 1: Enabling Localization in Django


Create a folder in your site root's directory (or elsewhere if you see fit), called `locale`. This will contain a folder for each language, as well as the files used for translation themselves.

Open up your `settings.py` and include or update the following settings:


    
    <code class="language-python">
    # Path to locale folder
    LOCALE_PATHS = (
        '/path/to/folder/locale',
    )
    
    # The language your website is starting in
    LANGUAGE_CODE = 'en'
    
    # The languages you are supporting
    LANGUAGES = (
        ('en', 'English'),   # You need to include your LANGUAGE_CODE language
        ('fa', 'Farsi'),
        ('de', 'German'),
    )
    
    # Use internationalization
    USE_I18N = True
    
    # Use localization
    USE_L10N = True
    </code>



Also, in each of your views (e.g. in `views.py`), you should be setting the request language as a session. For example:


    
    <code class="language-python">
    	if hasattr(request.user, 'lang'):
    		request.session['django_language'] = request.user.lang
    </code>





# Step 2: Internationalizing your Django content


This is really the easy part. Chances are, you've got a folder in your Django app called "templates". Inside, you've got HTML, some variables, and whatnot. All you have to do is go through and mark up the strings that need to be translated, like so:


    
    <code>
    {% trans "My English" %}
    {% trans myvar %}
    </code>



You get a lot of flexibility here, as described in [the documentation](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#internationalization-in-template-code). Essentially what happens is that you label all of your strings that should be translated, and then Django generates a handy file that your translator can use to localize the interface.

Just make sure that at the top of any template you want localized, you actually load the i18n library.


    
    <code>
    {% load i18n %}
    </code>



**Test it out**
You only have to translate a string or two in order to see whether it's working. Create your translation files using the following command:


    
    <code>
    $ django-admin.py makemessages --locale=de --extension=html --ignore=env --ignore=*.py
    </code>



Explanation of the options:



	
  * `--locale=de`  
Change this from _de_ to whatever locale you're going for.

	
  * `--extension=html`  
Tells the django engine only to look for .html files.

	
  * `--ignore=env`  
In my app, env/ is the folder where my virtual environment exists. I probably don't want to localize everything that exists in this folder, so we can ignore it. 

	
  * `--ignore=*.py`  
For some reason, django keeps trying to localize some of my python files that exist at the project root. To avoid this, I explicitly ignore such files.



Once you've run this `django-admin.py` command, you should take a look inside your `locale/` directory. If your app exists at something like `/opt/app/`, you'll find a file structure like this:

    
    <code>
    /opt/app
    --- /locale
    ------ /LC_MESSAGES
    --------- /de
    ------------ django.po
    </code>



And within each of these `django.po` files, you'll find pairs of a string, and then a space for a translation, as so:


    
    <code class="language-python">
    # path/to/templates/blah.html:123
    msgid "My English."
    msgstr ""
    </code>



Obviously, if you're in `/opt/app/locale/LC_MESSAGES/de/django.po` you'd better provide a German translation as a `msgstr`.

**Now, compile your messages and we'll see what we get!**


    
    <code>
    $ django-admin.py compilemessages
    </code>



Next to each `django.po` file, you'll now also have a `django.mo` file. This is the binary file that Django actually uses to fetch translations in real time. 

Restart uWSGI and your web server.

Add the language you just localized for to your preferred languages in your browser settings, and pull it to first place. In Chrome, this is Preferences » Advanced » Manage Languages.

When you reload your site, you should see that your string has been translated! Anything that you haven't translate will remain visible in its original language (in my case, English).



# Step 3: Translation Javascript (Javascript itself)


Open up your `urls.py`. Append the following:


    
    <code class="language-python">
    # 'Packages' should include the names of the app or apps you wish to localize
    js_info_dict = {
    	'packages': ('app',)
    }
    </code>



And in your `urlpatterns`, include:


    
    <code class="language-python">
    url(r'^jsi8n/$', 'django.views.i18n.javascript_catalog', js_info_dict),
    </code>



Now, in your base template (whichever manages loading your javascript) and place this script first:


    
    <code class="language-html">
    <script type="text/javascript" src="{% url 'django.views.i18n.javascript_catalog' %}"></script>
    </code>



Now you can go into any javascript file and simply place `gettext("")` around any string and that string can be localized. For example:


    
    <code class="language-javascript">
    this.$el.find('.a')[0].attr('title', gettext('Show Resources'));
    </code>



**Generating the Javascript messages file**
Just as before, when you ran the `django-admin.py` command to gather all the strings needing translations in your html templates, you can do the same in your javascript files.


    
    <code>
    $ django-admin.py makemessages -d djangojs --locale de --ignore=env
    </code>



Again, specify the locale and ignore the files inside my virtual environment. Now, look at the files you have in your `locale/` subdirectories.


    
    <code>
    /opt/app
    --- /locale
    ------ /LC_MESSAGES
    --------- /de
    ------------ django.po
    ------------ django.mo
    ------------ djangojs.po
    </code>



Simply open up `djangojs.po`, translate a string, and run `django-admin.py compilemessages` again. You'll find, as you probably expected, a new file called `djangojs.mo`. As before, restart uWSGI and your server, and spin it up in the browser. Again, be sure that you've got your test language set as your preferred language in your browser settings.



# Step 3b: Translating Javascript Templates (Underscore)


This is where things get a little more interesting. The critical point is this: **We want our underscore templates to be served through Django, not through our web server directly (e.g. through Apache or Nginx)**. These are the steps I took to achieve this:



	
  1. Move my underscore templates out of my `static/` folder, and into my `templates/` folder.

	
  2. Write a urlpattern that will cause my underscore templates to be run through the django template engine first.

	
  3. Update the references to templates in my Javascript (I use RequireJS and the text plugin).



**1. Move Underscore Templates**
Previously, my project structure was something like this:

    
    <code>
    app/
    --- static/
    ------ css/
    ------ js/
    ---------- views/
    ---------- templates/
    -------------- underscore-template.html
    --- templates/
    ------ django-template.html
    </code>



And I had Nginx serving everything inside of `static/`, well, directly, using the following directive in my Nginx conf file:


    
    <code>
    location /static {
    	alias /opt/app/static;
    }
    </code>



Now, instead of this, I want Django to do its magic before Backbone and Underscore go to town on the templates. So I create a folder inside `app/templates/` called `js/`. I move all my underscore templates here. So now I have:


    
    <code>
    app/
    --- static/
    ------ css/
    ------ js/
    ---------- views/
    --- templates/
    ------ js/
    ---------- underscore-template.html
    ------ django-template.html
    </code>



**2. Write a urlpattern**
Now, I'm not positive this is the best way to do this, but it does work. Open up your `urls.py` and add this line:


    
    <code class="language-python">
    url(r'^templates/(?P<path>\w+)', 'web.views.static'),
    </code>



What happens now is that whenever Django receives a request for a URL that looks like _mysite.com/templates/some/thing.html_, it assigns `some/thing.html` to a variable `path`, and passes that to our web view. So now I open up `app/web/views.py` and append this code:


    
    <code class="language-python">
    def static(request, path):
    	
    	# Update this to use os.path
    	directory = '/opt/app/' + request.META['REQUEST_URI'];
    	template = loader.get_template(directory)
    
    	# This allows the user to set their language
    	if hasattr(request.user, 'lang'):
    		request.session['django_language'] = request.user.lang
    
    	# I use this email_hash to generate gravatars, incidentally
    	context = RequestContext(request, {
    		'email_hash': hashlib.md5(request.user.email).hexdigest() if request.user.is_authenticated() else ''
    	})
    
    	return HttpResponse(template.render(context))
    </code>



Now, we're taking whatever request it was, grabbing that file, and passing it through `template.render`. If needed, add this folder to your `settings.py`:


    
    <code class="language-python">
    TEMPLATE_DIRS = (
        # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
        # Always use forward slashes, even on Windows.
        # Don't forget to use absolute paths, not relative paths.
    	'/opt/app/templates/',
    	'/opt/app/templates/js'
    )
    </code>



Now you can go into any of your underscore template files and mark them up using typical django syntax. Just make sure you remember to include `{% load i18n %}` at the top of your underscore templates. For example:


    
    <code class="language-html">
    {% load i18n %}
    <!-- Page of Greek text for Reader view -->
    <div class="page">
    
    	<!-- Page corner, functions as navigation -->
    	<div class="corner <%= side %>">
    		<a href="#" data-toggle="tooltip" title="<% side == 'left' ? print('Previous') : print('Next') %> Page" data-placement="<% side == 'left' ? print('right') : print('left') %>"></a>
    	</div>
    
    	<!-- Page header -->
    	<h1><%= work %> <small>{% trans "by" %} <%= author %>{% trans "," %} <a href="#" data-toggle="tooltip" title="{% trans 'Jump to another section' %}">section</a></small></h1>
    	<hr>
    
    	<!-- Greek goes here! -->
    	<span class="page-content">
    		<% _.each(words, function(word) { %>
    			<% if (word.get('sentenceCTS') == cts) { %>
    				<span lang="<%= word.get('lang') %>" data-cts="<%= word.get('wordCTS') %>" class="<% if (word.get('value').match(/[\.,-\·\/#!$%\^&\*;:{}=\-_`~()]/)) print('punct'); %>"><%= word.get('value') %></span> 
    			<% } %>
    		<% }); %>
    	</span>
    </div>
    </code>



In the long run, it may be worth your time to simply switch your html templates purely to Django. However, since the syntax of Underscore and Django don't clash, it's a viable solution as far as I've experienced.

Once you've marked up your underscore templates, simply re-run the same `django_admin.py makemessages` command as before.

Just don't forget to go into your javascript files and change the paths where you're importing your templates from, so they're no longer pointing to a static directory. For example:


    
    <code class="language-javascript">
    define(['jquery', 'underscore', 'backbone', 'text!/templates/js/underscore-template.html'], function($, _, Backbone, Template) { 
    
    	var View = Backbone.View.extend({
    		tagName: 'div', 
    		template: _.template(Template),
    		render: function() {
    			this.$el.html(this.template(this.model));
    			return this;
    		}
    	});
    	return View;
    });
    </code>





# Supporting bidirectional languages


So far, I have had great success with the techniques suggested in this blogpost: 
[RTL CSS with Sass](http://www.matanich.com/2013/09/06/rtl-css-with-sass/). 
I'll just give you a couple of pointers on how to make it easy to implement this with Django.

First, I installed the [set_var template tag](http://www.soyoucode.com/2011/set-variable-django-template). This is because I want to use some of the useful `get_language` functions that Django makes available to me. Alternatively, you could probably clean this up by putting this logic in your `views.py`.

Then, in my `app/templates/base.html`, I make use of this template tag and template inheritance as so:


    
    <code>
    {% load i18n %}
    {% load set_var %}
    {% get_current_language_bidi as LANGUAGE_BIDI %}
    {% if LANGUAGE_BIDI %}
    	{% set dir = "rtl" %}
    {% else %}
    	{% set dir = "ltr" %}
    {% endif %}
    
    <!DOCTYPE html>
    <html dir="{{ dir }}">
        <head>
    	<meta charset="utf-8">
    	<meta name="viewport" content="width=device-width, initial-scale=1.0">
    	<title>
    		{% trans "My app" %}
    	</title>
    
    	{% block css %}
    		<link href="/static/css/{{ css_file }}.{{ dir }}.css" rel="stylesheet">
    	{% endblock %}
    
    	<script type="text/javascript" src="{% url 'django.views.i18n.javascript_catalog' %}"></script>
    	<script data-main="/static/js/main" src="/static/js/lib/require.js"></script>
    	<script>var csrf_token = "{{ csrf_token }}"; var locale = "{{ LANGUAGE_CODE }}"; var dir = "{{ dir }}"; </script>
        </head>
        <body>
            {% block content %} {% endblock %}
        </body>
    </html>
    </code>



What do we have here?



	
  1. We're using Django to get the direction our page is -- either ltr or rtl.

	
  2. We're making it possible to replace the CSS file based on the page we're on and the text direction.

	
  3. We make a couple of variables global (eek!) for use in our javascript.



Now, you can take any page which inherits from your base template, and set the css_file. For example:


    
    <code>
    {% extends "base.html" %}
    
    	{# Determine which CSS file to load #}
    	{% block css %}
    		{% with 'generic' as css_file %}
    			{{ block.super }}
    		{% endwith %}
    	{% endblock %}
    
    	{% block content %}
    
    	&ltr;!-- Content here -->
    
    	{% endblock %}
    </code>



Note: This assumes that you are generating your CSS files with a command such as this:

    
    <code>
    $ sass generic.scss generic.ltr.css
    </code>



And that inside of `generic.scss` you've got an `@import "directional"` wherein you switch the direction between LTR and RTL in order to generate your sets of CSS.



# And that's a wrap!


It's essentially everything you need to internationalize your Django website and get django to do a first pass over your underscore templates. If you've got suggestions for improving this work flow, by all means, pass them my way! I hope this helps give you some ideas on how to use Django's built in internationalization and localization tools to make your life easier :)



* * *





## Questions, Comments, Mistakes?


Get in touch via the comments (preferable, so others can use them to troubleshoot), or Twitter at [@monicalent](http://www.twitter.com/monicalent), or Google at [+MonicaLent](https://plus.google.com/+MonicaLent/).
