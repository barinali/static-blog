+++
author: Monica
comments: true
date: 2014-06-15 12:21:41+00:00
layout: post
slug: parse-tree-editor-d3-editable-tree-layout
title: Building a Parse Tree Editor in d3 with Tree Layout (Pt. 1 - Display)
wordpress_id: 191
categories:
- d3
- Data Visualization
- JavaScript
- Tech
tags:
- computational linguistics
- d3
- javascript
- linguistics
- parse trees
- tree layout
+++

[caption id="attachment_193" align="aligncenter" width="475"][![](http://monicalent.com/blog/wp-content/uploads/2014/05/Screen-Shot-2014-05-20-at-4.26.31-PM.png)](http://monicalent.com/blog/wp-content/uploads/2014/05/Screen-Shot-2014-05-20-at-4.26.31-PM.png) "In this way, the Athenians came to the circumstances under which they grew in power." The first sentence from Thucydides' [Pentecontaetia](http://en.wikipedia.org/wiki/Pentecontaetia). [/caption]


This is a long post and chances are you only need information from part of it. Here's a table of contents:



<!-- more -->




   
  1. Background

   
      
    1. Trees: In Linguistics and in d3

      
    2. Our Incoming Data

      
    3. Dependencies

   
   
  2. Base Code

   
      
    1. Our HTML

      
    2. Our Main for Require.js

      
    3. Our JS Base

   
   
  3. Key Functions

   
      
    1. Initialize Module

      
    2. Convert Data

      
    3. Render SVG canvas

      
    4. Update Tree to Use our Data

   
   



**External Resources**



   
  * [View this code as a GitHub Gist](https://gist.github.com/mlent/4a08236e3d07514357c3)

   
  * [View this code on JSFiddle](http://jsfiddle.net/6rH9b/2/)





## Background




### Trees: In Linguistics and in d3




In computational linguistics, a parse tree is essentially a way to represent the syntactic relationships and structure in a string. Here I'll be working with data in the form of [dependency-based parse trees](http://en.wikipedia.org/wiki/Parse_tree#Dependency-based_parse_trees) for Ancient Greek, specifically the format used by the [Perseus Digital Library](http://www.perseus.tufts.edu/hopper/).





In d3, [the tree layout](https://github.com/mbostock/d3/wiki/Tree-Layout) refers to one of d3's ways to display hierarchical data. In order to get d3 to show display our data with the tree layout, **you only have to convert the incoming data format to one d3 expects**. More on the data next!





### Our Incoming Data




We will get a sentence with words and punctuation as tokens. Each token will contain an ID for itself (`id`) and an attribute `head`, which refers to the `id` of its parent. **This is all we need to build the tree.** We do, however, have other data which we'll display in order to show the user all the attributes of the tree. Here's a look at what one of our words looks like in JSON (snipped): 




    
    
    <code class="language-javascript">
    {
       id: 1,
       head: 3,
       value: "οἱ",
       relation: "ATR"
    }
    </code>
    





### Dependencies


I'll be using d3 with vanilla javascript. Since d3 handles selecting DOM elements well enough itself, you don't really need jQuery to do such a job. 



* * *





## Base Code




We've got three files on our hands:





   
  1. _index.html_ -- The place our tree appears! 

   
  2. _main.js_ -- Our require.js file which loads our dependencies. 

   
  3. _parsetree.js_ -- Our d3 code goes here.





### Our HTML


**index.html**
Things such as the CSS, which we'll use to style the tree, can go into a separate file if you'd like. 

    
    
    <code class="language-html">
    <!DOCTYPE html>
    <html>
       <head>
          <meta charset="utf-8">
          <!-- Here you can simple include our dependencies if you don't want to use Require.js -->
          <script data-main="main" src="//cdnjs.cloudflare.com/ajax/libs/require.js/2.1.11/require.min.js"></script>
       </head>
       <body>
          <div data-toggle="parsetree"></div>
       </body>
    </html>
    </code>
    





### Our Main for Require.js


If you choose not to use Require, you can just make sure that d3.js loads before our parse tree editor.
**main.js**

    
    
    <code class="language-javascript">
    requirejs.config({
        'baseUrl': '.',
        'paths': {
            'd3': '//cdnjs.cloudflare.com/ajax/libs/d3/3.4.8/d3.min',
            'parsetree': 'parsetree'
        },
        'shim': {
            'd3': {
                'exports': 'd3'
            },
            'parsetree': {
                'exports': 'parsetree',
                'deps': ['d3']
            }
        }
    });
    
    require(['parsetree'], function(parseTree) {
    
        new parseTree('div[data-toggle="parsetree"]').init();
    
    });
    </code>
    





### Our JS base code


**parsetree.js**

    
    
    <code class="language-javascript">
    define(['d3'], function(d3) {
    
        var parsetree = function(selector, options) {
            this.el = document.querySelector(selector);
            this.options = options || {};
     
            if (this.el == null)
                console.log("Could not find DOM object");
     
            return this;
        };
    });
    </code>
    





## Key Functions


It only requires a couple of functions to get our data from flat to beautiful d3 tree. We'll start by initializing our module and giving it some data to play with.




### Initializing the Module



    
    
    <code class="language-javascript">
    define(['d3'], function(d3) {
    
        var parsetree = function(selector, options) {
            this.el = document.querySelector(selector);
            this.options = options || {};
     
            if (this.el == null)
                console.log("Could not find DOM object");
     
            return this;
        };
    
        // For our purposes, I'll hardcode our data in.
        parsetree.prototype.init = function() {
    
            words = [
                  { id: 1, head: 3, relation: "OBJ", value: "ταῦτα" },
                  { id: 2, head: 3, relation: "AuxY", value: "γὰρ" },
                  { id: 3, head: 0, relation: "PRED", value: "εἶχον", },
                  { id: 4, head: 3, relation: "SBJ", value: "Ἀθηναῖοι" },
                  { id: 5, head: 1, relation: "ATR", value: "Πελοποννησίων" },
                  { id: 6, head: 0, relation: "AuxK", value: "." }
               ];
    
            // We'll convert our flat word object into hierarchical data -- read on to find out how!
            this.data = this.convertData(words);
            this.render();
    
            return this;
        };</strong>
    
        // By AMD standards, module exports are all lowercase
        return parsetree;
    });
    </code>
    



Here we're defining an AMD module which states that our only dependency is d3, and `parsetree` is what we want to export. Typically you'll want to load your data externally instead of hardcoding it into the module. Check out [d3's Request Documentation](https://github.com/mbostock/d3/wiki/Requests) for useful information on this.



### Transforming our Data from Flat to Hierarchical




d3 gladly handles data that comes to it in a hierarchical format. For example, a JSON list of nodes, wherein each node has a nested array of nodes, called `children`. There are samples available here: [d3 Tree Layout documentation](https://github.com/mbostock/d3/wiki/Tree-Layout#children). This is what _our data_ will look after we've run the aforementioned `convertData` function (described after this):




    
    
    <code class="language-javascript">
    var words = [
       { "id": 0, "value": "root", "pos": "root",
          "children": [
             { <strong style="color: #F00">"id": 3</strong>, "head": 0, "value": "εἶχον", "relation": "PRED",
                "children": [
                   { "id":1, <strong style="color: #F00">"head": 3</strong>, "value": "ταῦτα", "relation": "OBJ",
                      "children": [
                         { "id": 5, "head": 1, "value": "Πελοποννησίων", "relation": "ATR" }
                      ]
                   },
                   { "id": 2, <strong style="color: #F00">"head": 3</strong>, "value": "γὰρ", "relation": "AuxY" },
                   { "id": 4, <strong style="color: #F00">"head": 3</strong>, "value": "Ἀθηναῖοι", "relation": "SBJ" }
                ]
             },
             { "id": 6, "head": 0, "value": ".", "relation": "AuxK" }
          ]
       }
    ];
    </code>
    






We will take our flat data, which you saw in our `init` function, and transform it into hierarchical data, which you see above. This is done very simply for us, given the `id` parameter and the `head` parameter in our JS object (taken from [Generating a tree diagram from ‘flat’ data](http://www.d3noob.org/2014/01/tree-diagrams-in-d3js_11.html)). We'll add that function to our module called `convertData`:





    
    
    <code class="language-javascript">
    parsetree.prototype.convertData = function(words) {
    
        // Create a root node
        var rootNode = { 'id': 0, 'value': 'root', 'pos': 'root' };
        words.push(rootNode);
    
        var dataMap = words.reduce(function(map, node) {
            map[node.id] = node;
            return map;
        }, {});
    
        var treeData = [];
        words.forEach(function(node) {
    
            var head = dataMap[node.head];
    
            // Then, create the hierarchical data d3 needs
            if (head)
                (head.children || (head.children = [])).push(node);
            else
                treeData.push(node);
            });
    
        return treeData;
    };
    </code>
    



Now our data is ready to feed to the tree! Let's write a render function to create the DOM elements that will contain our SVG.



### Render the SVG elements



    
    
    <code class="language-javascript">
    parsetree.prototype.render = function () {
        // To keep multiple instances from stomping on each other's data/d3 references
        this.tree = d3.layout.tree().nodeSize([100, 50]);
    
        // Tell our tree how to decide how to separate the nodes
        this.tree.separation(function (a, b) {
            var w1 = (a.value.length > a.relation.length) ? a.value.length : a.relation.length;
            var w2 = (b.value.length > b.relation.length) ? b.value.length : b.relation.length;
    
            var scale = 0.13;
    
            return Math.ceil((w1 * scale) + (w2 * scale) / 2);
        });
    
        // Create our SVG elements
        // this.svg is our reference to the parent SVG element
        this.svg = d3.select(this.el).append('svg')
            .attr('class', 'svg-container')
            .style('width', 700)
            .style('overflow', 'auto');
    
        // this.canvas is the group (<g>) that the actual tree goes into
        this.canvas = this.svg.append('g')
            .attr('class', 'canvas');
    
        // and we nest another one inside to allow zooming and panning
        this.canvas.append('g')
            .attr('transform', 'translate(' + (this.options.width || 500) + ', ' + (this.options.marginTop || 10) + ') scale(' + (this.options.initialScale || .8) +
            ')');
    
        // And at last, we tell the tree to consider our data.
        this.root = this.data[0];
    
        // this.update is called whenever our data changes
        this.update(this.root);
    
        return this;
    };
    </code>
    





### Update the Tree to Use our Data


This is the most important function in our code. I'll each plain each part in detail after you've seen the overview:


    
    
    <code class="language-javascript">
    parsetree.prototype.update = function (source) {
    
        // This function tells our tree to be oriented vertically instead of horizontally
        var diagonal = d3.svg.diagonal()
            .projection(function (d) {
                return [d.x, d.y];
            });
    
        var nodes = this.tree(this.root).reverse(),
            links = this.tree.links(nodes);
    
        nodes.forEach(function (d) {
            d.y = d.depth * 100;
        });
    
        var node = this.svg.select('.canvas g')
            .selectAll('g.node')
            .data(nodes, function (d, i) {
                return d.id;
            });
    
        var nodeEnter = node.enter()
            .append('g')
            .attr('class', 'node')
            .attr('transform', function (d) {
                return 'translate(' + source.x + ', ' + source.y + ')';
            });
    
        nodeEnter.append('circle')
            .attr('r', 10)
            .style('stroke', '#000')
            .style('stroke-width', '3px')
            .style('fill', '#FFF');
    
        // Our Greek Word
        nodeEnter.append('text')
            .attr('y', function (d, i) {
                return (d.pos == 'root') ? -30 : 15;
            })
            .attr('dy', '14px')
            .attr('text-anchor', 'middle')
            .text(function (d) {
                return d.value;
             })
            .style('fill', function (d, i) {
                return (d.pos == 'root') ? '#CCC' : '#333';
            })
            .style('font-family', 'Cambria, Serif')
            .style('letter-spacing', '2px')
            .style('font-size', '18px')
            .style('fill-opacity', 1);
    
        // Relation of Node to Parent
        nodeEnter.append('text')
            .attr('y', function (d, i) {
                return (d.pos == 'root') ? 0 : -30;
            })
            .attr('dy', '12px')
            .attr('text-anchor', 'middle')
            .attr('class', 'label')
            .style('font-family', 'sans-serif')
            .style('font-size', '12px')
            .style('font-weight', 500)
            .style('letter-spacing', '1px')
            .style('fill', '#666')
            .text(function (d) {
                return d.relation;
            });
    
        var nodeUpdate = node.transition()
            .duration(this.options.duration || 500)
            .attr('transform', function (d) {
                return 'translate(' + d.x + ', ' + d.y + ')';
            });
    
        var link = this.svg.select('.canvas g')
            .selectAll('path.link')
            .data(links, function (d) {
                return d.target.id;
            });
    
        link.enter()
            .insert('path', 'g')
            .attr('class', 'link')
            .style('stroke', '#CCC')
            .style('stroke-width', '2px')
            .style('fill', 'none')
            .attr('d', function (d) {
                var o = {
                    x: source.x,
                    y: source.y
                };
    
                return diagonal({
                    source: o,
                    target: o
                });
            });
    
        link.transition()
            .duration(this.options.duration || 500)
            .attr('d', diagonal);
    
        nodes.forEach(function (d, i) {
            d.x0 = d.x;
            d.y0 = d.y;
        });
    };
    </code>
    



**Explanation of Update function**


    
    <code class="language-javascript">
        var nodes = this.tree(this.root).reverse(),
            links = this.tree.links(nodes);
    
        nodes.forEach(function (d) {
            d.y = d.depth * 100;
        });
    </code>


Here we're passing our root into the d3 tree object in order to create nodes, and then passing those nodes in as links in the tree. d3 will do all of the calculation about where they're supposed to go.

We then iterate over the nodes and adjust the y axis of each node based on its depth in the hierarchical data. Making `100` bigger or smaller will adjust how "vertically stretched" your parse tree is.


    
    <code class="language-javascript">
        var node = this.svg.select('.canvas g')
            .selectAll('g.node')
            .data(nodes, function (d, i) {
                return d.id || (d.id = ++i);
            });
    </code>


Here we're performing a subselection within our `this.svg` element. Since we perform all of our selections as subselections of that element, we're making sure to be acting on a _specific_ instance of a tree rather than _any_ instance of a tree. You need to do this especially if you'd like to display more than one tree per page and be able to update them without their data/display clashing.

Performing `selectAll('g.node')` looks for a group `<g>` with the class `.node` and binds data to each of the nodes previously declared as `var nodes = this.tree(this.root).reverse()`. Since d3 is all about making selections and applying all actions at once, you'll probably never need to loop through these nodes manually. 


    
    <code class="language-javascript">
        var nodeEnter = node.enter()
            .append('g')
            .attr('class', 'node')
            .attr('transform', function (d) {
                return 'translate(' + source.x + ', ' + source.y + ')';
            });
    
        nodeEnter.append('circle')
            .attr('r', 10)
            .style('stroke', '#000')
            .style('stroke-width', '3px')
            .style('fill', '#FFF');
    </code>


The concept of "entering" and element in d3 is critical to being able to successfully update the tree. When you call `.enter()` on a d3 selection, it will only return a selection **if it did not previously exist.** That's why you want to use this `nodeEnter` variable when appending the circle SVG element -- that circle is only appended once, because element didn't exist. When you update, `nodeEnter` will return nothing, so that `nodeEnter.append()` doesn't happen every time you want to `update()` the tree.


    
    <code class="language-javascript">
        // Our Greek Word
        nodeEnter.append('text')
            .attr('y', function (d, i) {
                return (d.pos == 'root') ? -30 : 15;
            })
            .attr('dy', '14px')
            .attr('text-anchor', 'middle')
            .text(function (d) {
                return d.value;
             })
            .style('fill', function (d, i) {
                return (d.pos == 'root') ? '#CCC' : '#333';
            })
            .style('font-family', 'Cambria, Serif')
            .style('letter-spacing', '2px')
            .style('font-size', '18px')
            .style('fill-opacity', 1);
    
        // Relation of Node to Parent
        nodeEnter.append('text')
            .attr('y', function (d, i) {
                return (d.pos == 'root') ? 0 : -30;
            })
            .attr('dy', '12px')
            .attr('text-anchor', 'middle')
            .attr('class', 'label')
            .style('font-family', 'sans-serif')
            .style('font-size', '12px')
            .style('font-weight', 500)
            .style('letter-spacing', '1px')
            .style('fill', '#666')
            .text(function (d) {
                return d.relation;
            });
    </code>


The same concept goes for our Greek words and our relationship attribute. We append those to the nodeEnter variable, and they go right into the same `<g>` element as the circle. Here's an example of what the SVG generated by d3 is going to look like (trimmed to remove the styling):


    
    <code class="language-html">
    <g class="node" transform="translate(250,300)">
        <circle r="10"></circle>
        <text y="15" dy="14px">πράγματα</text>
        <text y="-30" dy="12px">OBJ</text>
    </g>
    </code>



It's important that everything go into this `<g>` element so that when we want to edit our parse tree, the node itself, its greek text, and its relation attribute all move with it. If you want to include further fields, like a translation or POS, here's the place to do it.


    
    <code class="language-javascript">
        var nodeUpdate = node.transition()
            .duration(this.options.duration || 500)
            .attr('transform', function (d) {
                return 'translate(' + d.x + ', ' + d.y + ')';
            });
    </code>


`nodeUpdate` is code that will actually get executed the first time you run `this.update()` and each subsequent time. In this case, it is performing a transition on the x, y coordinates of the node. 


    
    <code class="language-javascript">
        var link = this.svg.select('.canvas g')
            .selectAll('path.link')
            .data(links, function (d) {
                return d.target.id;
            });
    
        link.enter()
            .insert('path', 'g')
            .attr('class', 'link')
            .style('stroke', '#CCC')
            .style('stroke-width', '2px')
            .style('fill', 'none')
            .attr('d', function (d) {
                var o = {
                    x: source.x,
                    y: source.y
                };
    
                return diagonal({
                    source: o,
                    target: o
                });
            });
    
        link.transition()
            .duration(this.options.duration || 500)
            .attr('d', diagonal);
    </code>


The same concepts apply to the links. 

That's about it! You've got everything you need for a basical display of a parse tree. In following blog posts I'll discuss adding additional functionality to the parse tree such as editing, answer-checking, and exporting its data. 



* * *





## Questions, Comments, Mistakes?


Get in touch via the comments (preferable, so others can use them to troubleshoot), or Twitter at [@monicalent](http://www.twitter.com/monicalent), or Google at [+MonicaLent](https://plus.google.com/+MonicaLent/).
