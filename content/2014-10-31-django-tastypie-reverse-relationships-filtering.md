---
author: Monica
comments: true
date: 2014-10-31 17:54:27+00:00
layout: post
slug: django-tastypie-reverse-relationships-filtering
title: 'Django Tastypie: Tips, Tricks, and Troubleshooting'
wordpress_id: 326
categories:
- Python
tags:
- django
- python
- tastypie
---

Tastypie is one of the most popular REST API frameworks for Django, and surprisingly easy to get up and running if you're already working with Django's Models. It can, however, be a bit difficult to debug, and produce some cryptic error messages. Here are a couple of tasks I've had to figure out while working with this framework, tips for troubleshooting, and some general reflections.



* * *



<!-- more -->



## Table of Contents





   
  1. Adding Fields to a Resource

   
  2. Mapping Attributes of an Object through a Reverse Relationship

   
  3. Filtering via Through Relationships

   
  4. Self-Referential Resources





* * *





## Adding Fields to a Resource


It seems simple enough -- and it is -- but there are really a number of ways to do it, so you have to decide which is most appropriate for your use case. 

**1. Implementing the field-specific `dehydrate` function**


    
    <code class="language-python">
    from tastypie import fields
    from tastypie.resources import ModelResource
    from app.models import MyModel
    
    class MyModelResource(ModelResource):
        FOO = fields.CharField()
    
        class Meta:
            queryset = MyModel.objects.all()
    
        def dehydrate_FOO(self, bundle):
            return bundle.obj.data.FOO.upper()
    
    </code>



Here, we work on the object referenced after the underscore in the function name (e.g. function `dehydrate_FOO` operates on the FOO field, accessible within the function as `bundle.obj`). Once you've updated it in some way, Tastypie will automatically update `bundle.data['FOO']` for you.

**2. Implementing the (resource-wide) `dehydrate` function**


    
    <code class="language-python">
    from tastypie import fields
    from tastypie.resources import ModelResource
    from app.models import MyModel
    
    class MyModelResource(ModelResource):
        class Meta:
            queryset = MyModel.objects.all()
    
        def dehydrate(self, bundle):
            bundle.data['new_FOO'] = 'This came from nowhere!'
            return bundle
    </code>



This makes sense if you need to add a new field, which is based on the value of several other fields, or none of the other fields at all. In the example above, the string 'some data' is not derived from any other field, so it makes sense to put it in the `dehydrate` function.

**3. Additional methods**

There are a couple different strategies floating around for adding fields manually to a Tastypie resource. Here are some resources you may find helpful, if you have 




   
  * [Tastypie Documentation](http://django-tastypie.readthedocs.org/en/latest/resources.html#dehydrate)

   
  * [Blogpost on adding fields during alter_list_data_to_serialize](http://fan-zf.blogspot.de/2013/07/add-extra-object-to-tastypie-returned.html)

   
  * [Stackoverflow Post: "How to add extra object to Tastypie Return JSON"](http://stackoverflow.com/questions/13302240/how-to-add-extra-object-to-tasty-pie-return-json-in-python-django)

   
  * [Stackoverflow Post: "Can Tastypie display a different set of fields in List and Detail views?"](http://stackoverflow.com/questions/10693379/can-django-tastypie-display-a-different-set-of-fields-in-the-list-and-detail-vie)



**Troubleshooting**



<blockquote>'Bundle' object does not support item assignment</blockquote>



This occurs because you are trying to assign a new field to `bundle` rather than to `bundle.data`. Make sure that when you are adding or removing fields from the bundle, particularly when implementing resource-wide `dehydrate`, you are operating on its `data` dictionary. 


    
    <code class="language-python">bundle['new_field'] = 'This will not work.'
    bundle.data['new_field'] = 'This works!'</code>





* * *





## Mapping attributes of an object, related via a foreign key, through a reverse relationship


This is a completely insane title for a section, so let me start by giving you a use-case.




   
  * I have a list of `Grammar` topics (objects). 

   
  * I have content written for these topics in many languages.

   
  * Each `Content` object has a `ForeignKey` relationship to a Grammar topic.

   
  * When looking at the list view of Grammar topics, I want to see the languages and titles of corresponding available content.



**My starting JSON**

    
    <code class="language-javascript">
    {
        meta: {
            limit: 20,
            next: "/api/v1/grammar/?offset=20&limit;=20&format;=json",
            offset: 0,
            previous: null,
            total_count: 1
        },
        objects: [
            {
                id: 18,
                resource_uri: "/api/v1/grammar/18/",
                name: "First Declension Nouns - Feminine (α-stem)",
            }
        ]
    }
    </code>



**My target JSON**

    
    <code class="language-javascript">
    {
        meta: {
            limit: 20,
            next: "/api/v1/grammar/?offset=20&limit;=20&format;=json",
            offset: 0,
            previous: null,
            total_count: 1
        },
        objects: [
            {
                id: 18,
                resource_uri: "/api/v1/grammar/18/",
                name: "First Declension Nouns - Feminine (α-stem)",
                titles: {
                    de: "Die a-Deklination",
                    en: "First Declension Nouns",
                    it: "Sostantivi femminili"
                }
            }
        ]
    }
    </code>



As you can see, the goal is to end up with a dictionary of related content titles, with the `short_code` of the language as their key. We'll achieve this by grabbing the content, filtering by the grammar relationship, and the ultimately mapping the full `Content` object into a short and sweet dictionary entry. 

**The Django Models**
For good measure, here are the relevant Django models.


    
    <code class="language-python">
    from django.db import models
    import textwrap
    
    class Language(models.Model):
        """ 
        Languages that Content is available in.
        """
        name = models.CharField("language name (english)", 
                                max_length=200, 
                                help_text='(e.g. German)')
    
        short_code = models.CharField("shortcode", 
                                max_length=5, 
                                help_text='(e.g. \'de\')')
    
        def __unicode__(self):
            return unicode(self.name) or u''
    
    class Grammar(models.Model):
        """
        A unit of learning.
        """
        name = models.CharField("title of grammar section",
                                max_length=200,
                                help_text=textwrap.dedent("""
                                    Short, descriptive title of the grammar
                                    concept.
                                """))
    
        class Meta:
            verbose_name = 'Grammar Topic'
            ordering = ['name']
    
        def __unicode__(self):
            return unicode(self.name) or u''
    
    class Content(models.Model):
        """
        Content refers to small chunks of information that the user is 
        presented with inside a lesson.
        """
        title = models.CharField("title",
                                max_length=200,
                                help_text=textwrap.dedent("""
                                    Short, descriptive title of what 
                                    content is in this section.
                                """))
    
        grammar_ref = models.ForeignKey(Grammar,
                                verbose_name="grammar topic",
                                null=True,
                                blank=True,
                                help_text=textwrap.dedent("""
                                    The morphology directly described by 
                                    this content.
                                """))
    
        source_lang = models.ForeignKey(Language,
                                related_name='content_written_in',
                                help_text=textwrap.dedent("""
                                    Language the content is written in.
                                """))
    
        target_lang = models.ForeignKey(Language,
                                related_name='content_written_about',
                                help_text='Language the content teaches.')
    
        content = models.TextField("Learning Content",
                                help_text=textwrap.dedent("""
                                    Write this in Markdown.
                                """))
        def __unicode__(self):
            return unicode(self.title) or u''
    
    

`

**api/grammar.py** - `GrammarResource`
I use the `dehydrate` function to add a new field to the resource object, and a helper function to reduce the list of content objects to something simpler.


    
    <code class="language-python">
    from tastypie import fields
    from tastypie.resources import ModelResource
    from app.models import Grammar, Content
    from api.content import ContentResource
    
    class GrammarResource(ModelResource):
        # Here we are using Reverse Relationships to grab content
        # related to this grammar topic.
        content = fields.ToManyField(ContentResource, 'content_set', 
            related_name='content', blank=True, null=True, 
            use_in='detail', full=True)
    
        class Meta:
            queryset = Grammar.objects.all()
            allowed_methods = ['get']
    
        # Dehydrate helper function
        def build_title(self, memo, content):
            lang = content.source_lang.short_code
            memo[lang] = content
            return memo
    
        def dehydrate(self, bundle):
            bundle.data['titles'] = reduce(self.build_title, 
                Content.objects.filter(grammar_ref=bundle.obj), {})
            return bundle
    </code>



The code itself should be rather self explanatory if you are already comfortable with map/reduce. We're simply applying the function `build_title` to each item in the `Content.objects` list, which we pre-filter based on whether its grammar reference is the one we're currently working on. Lastly, we pass in `{}` as the initial value of our dictionary. Each language becomes a key in the dictionary, and each content title becomes a value.

This is how we end up with:


    
    <code class="language-javascript">
    titles: {
        de: "Die a-Deklination",
        en: "First Declension Nouns",
        it: "Sostantivi femminili"
    }
    </code>



**Additional Resources:**



   
  * [Tastypie Documentation on ToManyField](http://django-tastypie.readthedocs.org/en/latest/fields.html?highlight=tomanyfield#tomanyfield)





* * *





## Filtering via Through Relationships



One thing which Tastypie doesn't seem to support nicely out of the box is including the values of the through relationship to a model. Consider the following use-case:




   
  * You have a `Task` model. 

   
  * You want to order these tasks using another model, `TaskSequence`.

   
  * You relate a `Task` to a `TaskSequence` with metadata (through a 'through' relationship, in a model named `TaskContext`, which includes information about the order of the tasks.



If you just ask Tastypie for the `TaskSequence` (which is related to another Resource over a simple foreign key relationship, in our case, the same GrammarResource as above), you might end up with something like this:


    
    <code class="language-javascript">
    {
       id: 60,
       name: "The Aorist Tense",
       query: "pos=verb&tense;=aor",
       ref: "s542,s546",
       resource_uri: "/api/v1/grammar/60/",
       task_sequence: {
          id: 2,
          name: "Verbs for Beginners",
          resource_uri: "",
          tasks: [
              {
                  endpoint: "word",
                  hint_msg: "Try again.",
                  id: 4,
                  name: "identify_morph:person",
                  success_msg: "Good job!"
              },
              {
                  endpoint: "word",
                  hint_msg: "Try again.",
                  id: 5,
                  name: "identify_morph:number"
                  success_msg: "Good job!"
              }
        ]
    }
    

`

However, we really need the information in the through relationship in order to determine the order of the tasks. Therefore, our target JSON is something like this instead:


    
    <code class="language-javascript">
    {
       id: 60,
       name: "The Aorist Tense",
       query: "pos=verb&tense;=aor",
       ref: "s542,s546",
       resource_uri: "/api/v1/grammar/60/",
       task_sequence: {
          id: 2,
          name: "Verbs for Beginners",
          resource_uri: "",
          tasks: [
              {
                  id: 4,
                  max_attempts: 10,
                  order: 0,
                  resource_uri: "",
                  target_accuracy: 0.5,
                  task: {
                      endpoint: "word",
                      hint_msg: "Try again.",
                      id: 4,
                      name: "identify_morph:person",
                      success_msg: "Good job!"
                  }
              },
              {
                  id: 5,
                  max_attempts: 5,
                  order: 1,
                  target_accuracy: 0.8,
                  task: {
                      endpoint: "word",
                      hint_msg: "Try again.",
                      id: 5,
                      name: "identify_morph:number",
                      success_msg: "Good job!"
                  }
              }
        ]
    }
    </code>



**Relevant Resources**

Take a look at the Tastypie resources for each of these three components (`Task`, `TaskSequence`, `TaskContext`). The most interesting code occurs in the `TaskSequenceResource`, where we filter on tasks related to the object in question -- similarly to the example above.


    
    <code class="language-python">
    """
    Model Resource
    """
    from tastypie import fields
    from tastypie.resources import ModelResource
    from app.models import Task
    
    class TaskResource(ModelResource):
        
        class Meta:
            queryset = Task.objects.all()
            allowed_methods = ['get']
    </code>




    
    <code class="language-python">
    """
    Through Model
    """
    from tastypie import fields
    from tastypie.resources import ModelResource
    from app.models import TaskContext
    
    class TaskContextResource(ModelResource):
            task = fields.ToOneField('api.task.TaskResource', 
                                'task', 
                                full=True, 
                                null=True, 
                                blank=True)
    
            class Meta:
                    queryset = TaskContext.objects.all()
                    allowed_methods = ['get']
    </code>




    
    <code class="language-python">
    """
    Model Sequence Resource
    """
    from tastypie import fields
    from tastypie.resources import ModelResource
    from app.models import TaskSequence
    from api.task_context import TaskContextResource
    
    class TaskSequenceResource(ModelResource):
        tasks = fields.ManyToManyField(TaskContextResource, 
            attribute=lambda bundle: 
            bundle.obj.tasks.through.objects.filter(
                task_sequence=bundle.obj
            ) or bundle.obj.tasks, 
            full=True)
    
        class Meta:
            queryset = TaskSequence.objects.all()
            allowed_methods = ['get']
    </code>



**Troubleshooting**



<blockquote>object has no attribute 'through'</blockquote>



Be careful that you don't have `lambda bundle: bundle.obj.through.objects`. (Missing, in this example, 'tasks'). You need to specify the name of the field that contains the related objects.

**Additional Resources:**



   
  * [Tastypie Documentation on ToManyField](http://django-tastypie.readthedocs.org/en/latest/fields.html?highlight=tomanyfield#tomanyfield)





## Self-Referential Resources



Sometimes it makes perfect sense to have Models that refer to themselves. For example, may have a model Person, and this model may have a list of Relatives (which are also of type Person). 

The difficulty comes in when each of these Person models also has a list of Relatives. There are a couple of ways to deal with this without ending up with the following error:



<blockquote>
Maximum recursion depth exceeded
</blockquote>



**1. Make the relationship asymmetrical in the Model (and do not set full=True)**
In our example, this would mean that Person A can be related to Person B (e.g. in Person A's list of relatives) without Person B being related to Person A.

This makes it pretty easy for Tastypie to deal with, so long as you do not need the full resources in the Person list view.

**app/models.py**

    
    <code class="language-python">
    from django.db import models
    
    class Person(models.Model):
        relatives = models.ManyToManyField('self',
            related_name='relates_to',
            symmetrical=False,
            null=True,
            blank=True)
    </code>



**api/person.py**

    
    <code class="language-python">
    from tastypie import fields
    from tastypie.resources import ModelResource
    from myapp.models import Person
    
    
    class PersonResource(ModelResource):
        relatives = fields.ToManyField('self', 'persons')
    
        class Meta:
            queryset = Person.objects.all()
    </code>



**2. Use the `use_in` option**

    
    <code class="language-python">
    from tastypie import fields
    from tastypie.resources import ModelResource
    from myapp.models import Person
    
    
    class PersonResource(ModelResource):
        relatives = fields.ToManyField('self', 'persons', use_in='list')
    
        class Meta:
            queryset = Person.objects.all()
    </code>



This is rather straightforward. This way, the relatives will never try to flesh themselves out into detail forms when you're viewing the Person resource as a list. However, this precludes you from seeing this same information in the detail view.

**3. Create a 'shallow' version of the resource**
But, if you need `full=True` on your list view, you're kind of out of luck. The easiest solution to prevent exceeding the maximum recursion depth is to create two resources. Consider:

`api/person.py`

    
    <code class="language-python">
    from tastypie import fields
    from tastypie.resources import ModelResource
    from myapp.models import Person
    from api.relative import RelativeResource
    
    class PersonResource(ModelResource):
        relatives = fields.ManyToManyField(RelativeResource,
            'related_person',
             null=True,
             blank=True,
             full=True)
    
        class Meta:
           queryset = Person.objects.all()
           allowed_methods = ['get']
    </code>



`api/relative.py`

    
    <code class="language-python">
    from tastypie import fields
    from tastypie.resources import ModelResource
    from myapp.models import Person
    
    class RelativeResource(ModelResource):
        class Meta:
           queryset = Person.objects.all()
           allowed_methods = ['get']
    </code>



Notice that only the person resource has `full=True`. This means that, because the relative resource will not try to fill out its own m2m fields, you won't run into infinite recursion. 

**Troubleshooting**



<blockquote>'Options' object has no attribute 'api_name'</blockquote>



Make sure you are pointing to the resource, rather than the model. This can happen if you meant to type, for example, PersonResource, but instead typed Person.

**Additional Resources**



    
  * [Tastypie Documentation on Reverse Relationships](http://django-tastypie.readthedocs.org/en/latest/resources.html#reverse-relationships) (scroll down a little for self-referential relationships)





* * *





## Questions, Comments, Mistakes?


Get in touch via the comments (preferable, so others can use them to troubleshoot), or Twitter at [@monicalent](http://www.twitter.com/monicalent), or Google at [+MonicaLent](https://plus.google.com/+MonicaLent/).
