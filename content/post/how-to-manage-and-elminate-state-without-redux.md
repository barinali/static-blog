+++
draft = true
author = "Monica"
date = "2017-06-10T14:29:42+02:00"
description = ""
tags = ["react", "redux", "javascript"]
title = "Patterns and strategies for managing and eliminating state in React"

+++

There's a lot of buzz around Redux, and a lot of people developing with
React start out by assuming that Redux is part of the proverbial
package. If you spend enough time on Twitter or Hacker News, it probably
looks like Redux is the silver bullet for all your state-management problems.

But unless you take additional steps to create components with state that is
simple to manage, Redux can ultimately facilitate _shifting_ complexity, but
it doesn't eliminate it for you. That's still the job
of the developer.

These patterns and strategies can be used to manage state in a more elegant
way, which you can use with or without Redux.

There are a couple of main strategies:

1. Remove things from `this.state` that don't belong there
2. Extract repetative state-management logic into small, composable functions
3. Use `context` to shield away state coordination between tightly-coupled components
4. Think differently about when you need a stateful component in the first place

This isn't meant to be an exhaustive list, but these are techniques
I wish I had learn about before digging myself into state-shaped holes.

Let's go!

## 1. Remove things from `this.state` that don't belong there

There are a couple of main things that often creep into `this.state`
but shouldn't actually be there.

1. Data that will never change
2. Data that can be calculated from `props`
3. Data that can be calcuated from other properties on `this.state`

Let's look at some examples, and some alternatives:

### Don't put un-changing data on `this.state`

When I first started using React, I basically treated `this.state` as the
way to expose data that I want to access to other methods inside the component.
For example, if I wanted my `render()` function to know about a query
parameter in the URL, I might set that in the constructor, like this:

    import React, { Component } from 'react';

    MyComponent extends Component {
      constructor(props) {
        super(props);
        this.state = {
          hideOption: window.location.search.indexOf('hide_option') !== -1
        };
      }

      render() {
        if (this.state.hideOption) { return null; }
        return (<div>You have an option</div>);
      }
    }

But in reality, a query parameter like this is never actually going to change.
And if it's not going to change, then there's no reason for this data
to live on my `state`.

It's easy to forget that behind the syntactic sugar, a stateful React
component is just a function with some data inside. Meaning, you can also
just do this:

    import React, { Component } from 'react';

    MyComponent extends Component {
      constructor(props) {
        super(props);
        this.hideOption = window.location.search.indexOf('hide_option') !== -1;
      }

      render() {
        if (this.hideOption) { return null; }
        return (<div>You have an option</div>);
      }
    }

But, again, since we're actually just working on a simple function,
you can choose do this in a number of ways. For example, if you don't want
all your un-changing data to pollute the `this` space, you can also arrange
it like so:

    constructor(props) {
      super(props);
      this.data = {
        hideOption: window.location.search.indexOf('hide_option') !== -1
      };
    }

Or, you can put the data outside the universe of React altogether:

    import React, { Component } from 'react';

    const DATA = { 
      hideOption: window.location.search.indexOf('hide_option') !== -1
    };

    MyComponent extends Component {
      render() {
        if (DATA.hideOption) { return null; }
        return (<div>You have an option</div>);
      }
    }

The point is, wherever you decide to put data that isn't going to change,
_don't put it on `this.state`_ because it doesn't belong there!

> Takeaway: Removing data that doesn't change from your state is the first,
> easiest step to making your `state` object smaller and more manageable.

### Don't put data in `this.state` if you don't want it to trigger a re-render

Sometimes, you need to store data that the component receives, but when
the data changes, you don't actually have to re-render the component. You
just want to update some internal storage of that data.

> Example needed!

### Avoid storing state that can be calculated from props or other state

This one is super easy to spot, but befalls all of us at one point or
another. Let's imagine you're getting a list of products from and endpoint,
and you also have a list of products that are in the user's order.

    import React, { Component } from 'react';
    import api from 'api';

    MyShop extends Component {
      constructor(props) {
        super(props);
        this.state = { products: [] };
      }

      componentWillMount() {
        Promise.all[
          api.shop.getProducts(),
          api.shop.getCurrentOrder()
        ].then(([products, order]) => {
          const orderProductIds = order.products.map(p => p.id);
          const uiProducts = products.reduce((memo, p) => {
            const selected = orderProductIds.indexOf(p.id) !== -1;
            return [...memo, { ...p, selected }];
          }, []);
          this.setState({ products: uiProducts, order });
        });
      }

      toggleProductInOrder(product) {
        # ...
      }

      render() {
        return (
          <ul>
            {this.state.products.map(product => (
              <li key={product.id}>
                {product.name}
                <button onClick={e => this.toggleProductInOrder(product)}>
                  {!product.selected ? '+ Add' : '- Remove'}
                </button>
              </li>
            )}
          </ul>
        );
      }
    }

It might be tempting to maintain one list of products, with a `{ selected: true }`
attribute if the product is in the user's cart, especially
if you're coming from the world of Angular.

But what happens as soon as you have to add or that product
from the order? Or, in fact, make any update request to the server?

Then it gets complicated.

You find yourself doing a lot of unnecessary iteration, and maintaining
a separate version of the data for the UI and for requests to the server.
Eventually, the data becomes increasingly separated from the version
you use to communicate with the API.

> Takeaway: One of the easiest code smells that results by ignoring this rule is
> that you find yourself manually synchronizing data, or changing multiple
> pieces of data at the same time.

Let's look at how you'd have to implement adding and removing products
from an order in this example.

    toggleProductsInOrder(product) {
      # Take all our products, flip the selected one,
      # and get a new list to send to the server
      const newProducts = this.state.products.reduce((memo, p) => {
        if (product.id !== p.id) { return [...memo, p]; }
        const newP = { ...p, selected: !p.selected };
        return [...memo, newP];
      }, []);

      # Filter out the selected products
      const newOrderProducts = newProducts.filter(p => p.selected);
      const updatedOrder = { ...this.state.order, products: newOrderProducts };

      # Update both the order and the products
      return api.shop.updateOrder(updatedOrder)
        .then(newOrder => {
          this.setState({ order: newOrder, products: newProducts });
        });

This is gross and overly complicated. We can avoid all this noise by
keeping the data as it comes to us, and calculating selected products
in the `render()` function.

    import axios from 'axios';
    import api from 'api';
    import { without } from 'lodash';

    MyShop extends Component {
      constructor(props) {
        super(props);
        this.state = { order: {}, products: [] };
      }

      componentWillMount() {
        axios.all[
          api.shop.getProducts(),
          api.shop.getCurrentOrder()
        ].then(([products, order]) => {
          # Benefit 1: No pre-processing of our data from the server
          this.setState({ products, order });
        });
      }

      toggleProductInOrder(product) {
        const { products, order } = this.state;
        const isSelected = this.isSelected(product);

        # Benefit 2: Updating an order involves changing just ONE piece of data
        const updatedOrder = !isSelected
          ? { ...order, products: [...products, { ...product, quantity: 1 }] }
          : { ...order, products: without(products, product) };

        return api.shop.updateOrder(updatedOrder)
          .then(updatedOrder => {
            this.setState({ order: updatedOrder });
          });
      }

      isSelected(product) {
        return this.state.order.products.find(p => p.id === product.id);
      }

      render() {
        const { order, products } = this.state;

        # Benefit 3: The render code barely changed,
        # but the logic and data juggling is gone
        return (
          <ul>
            {products.map(product => (
              <li key={product.id}>
                {product.name}
                <button onClick={e => this.toggleProductInOrder(product)}>
                  {!this.isSelected(product) ? '+ Add' : '- Remove'}
                </button>
              </li>
            )}
          </ul>
        );
      }
    }

Immediately, you notice some benefits:

- We don't do any initial mapping of our data. We can use it as it comes
to us from the server.
- We don't need to re-map the data when it's getting ready to go to the
server, or when it comes back.
- After updating the order, I only need to `setState` on one piece of
data, rather than two. In fact, you could argue that the `products`
don't even need to belong inside `this.state` at all, as they never
ever change.

You might start by thinking, "Wow, isn't it super inefficient to
figure out selected products on every render?"

But the fact is that since `this.render` will only execute if
`props` or `state` change, you only re-calculate this information
when it's needed. It could become a problem if this component starts to do too
many other things, but for our example, it eliminates a lot of data-munging.

> Takeaway: As much as possible, don't touch the data coming from the server.
  If you need to derive a UI state from it, try to do that in the `render`
  function instead of maintaining variations of your data on `this.state`.

## 2. Extract repetative state-mangement logic

How many times have you typed something along the lines of this:

    import React, { Component } from 'react';

    MyComponent extends Component {
      constructor(props) {
        super(props);
        this.state = { value1: '', value2: '' };
      }

      onChangeValue1(e) {
        const v1 = e.target.value;
        this.setState({ value1: v1 });
      }

      onChangeValue2(e) {
        const v2 = e.target.value;
        this.setState({ value2: v2 });
      }

      render() {
        return (
          <ul>
            <li>
              <label>Value 1</label>
              <input value={this.state.value1} onChange={this.onChangeValue1}/>
            </li>
            <li>
              <label>Value 2</label>
              <input value={this.state.value2} onChange={this.onChangeValue2}/>
            </li>
          </ul>
        );
      }
    }

All you want to do update some simple state once an input value has changed.
You might be thinking, "This girl is silly, of course you can simplify that,
like so:"

    onChange(key) {
      return e => {
        const value = e.target.value;
        this.setState({ [key]: value });
      }
    }

    render() {
      return (
        <input value={this.state.value} onChange={this.onChange('value')}/>
      );
    }

But the fact is, that everywhere you use an `input`, you have to copy
and paste this function. Okay, four lines is not a sin.

But sometimes it's not so simple -- such as in the case of form validations.
Imagine that you have a form object, which contains `values`, `errors`, and a
derived value `isValid`.

You can easily end up juggling a bunch of data. And you have to do it
_every time_ you create a new form. For example:

    import React, { Component } from 'react';

    MyForm extends Component {
      constructor(props) {
        super(props);
        this.state = {
          name: {
            value: 'My name',
            errors: { required: true },
            isValid: false
          }
        };
      }

      onChange(prop, value) {
        const notEmpty = value && value.length;
        const errors = { required: !notEmpty };
        const isValid = Object.values(errors).reduce((validity, err) => err, false);
        this.setState({
          [prop]: { value, errors, isValid }
        });
      }

      render() {
        const { value, errors } = this.state.name;
        return (
          <div>
            <input
              value={value}
              onChange={e => this.onChange('name', e.target.value)}/>
            <ul>
              {mapValues(errors, err => (<li key={err}>{err}</li>))}
            </ul>
          </div>
        );
      }
    }

It might be tempting to make an `Input` component that will handle
these things, but you can end up with the exact same problem when
implementing all sorts of input types, like select boxes, number inputs,
etc. And if you hide the data _inside_ the `Input`, you won't be able to
expose it to other components that might be interested in it (such
a form label, a list of errors, or a button that should be disabled if
the form is invalid).

So we know we don't want to do state management inside the `Input`,
but how can we stop from copy-pasting this code into every component
that has an input in it?

### Share functions between components

Instead, why not extract this common handling of `onChange` to a separate
module, like so:

# Form.js
    export function onChangeInput(prop, value, state) {
      const notEmpty = value && value.length;
      const errors = { required: !notEmpty };
      const isValid = Object.values(errors).reduce((validity, err) => err, false);
      return { ...state, [prop]: { value, errors, isValid } };
    }

# MyForm.js
    import React, { Component } from 'react';
    import { onChangeInput } from './Form';
    import { mapValues } from 'lodash';

    MyForm extends Component {
      constructor(props) {
        super(props);
        this.state = { name: {} };
      }

      onChangeInput(prop, value) {
        this.setState(prevState => onChangeInput(prop, value, prevState);
      }

      render() {
        const { value, errors } = this.state.name;
        return (
          <div>
            <input
              value={value}
              onChange={e => this.onChangeInput('name', e.target.value)}/>
            <ul>
              {mapValues(errors, err => (<li key={err}>{err}</li>))}
            </ul>
          </div>
        );
      }
    }

In the end, any function that updates state, which is also a pure function,
can be extracted into a module of helper functions that can be used across
components with similar purpose. 

You can do this for a lot of purposes where you might repeat things:

1. Handle change events
2. Create initial state

But you can also use this pattern to keep your code DRY and decide what
level of granularity you actually need in your form.

For instance, imagine that you want to be able to also set server-side errors
on the form.

What's a simple way to update errors while the user is typing, but use
the same error-setting functionality to set unrelated errors?

### Compose these functions if you have to make multiple changes at once

Function compositionnnnn! Since these are just functions that accept some
data and the state and return a new state, we can compose them to aggregate
behavior into convenience functions.

For example: `onChangeInput` will both `setValue` and `setErrors`. Whereas
`setErrors` can be used on its own to trigger random errors that aren't related
to changing the input.

Let's see how that might work.

    # Form.js
    import { curry, flowRight as compose } from 'lodash';

    export const setErrors = curry((prop, errs, state) => {
      const errors = {
        ...state[prop].errors,
        ...errs
      };
      const isValid = Object.values(errors).reduce((validity, err) => err, false);
      return { ...state, [prop]: { ...state[prop], errors, isValid } };
    });

    export const setValue = curry((prop, value, state) => {
      return { ...state, [prop]: { ...state[prop], value } };
    });

    # Since we want to be able to setErrors without triggering onChangeInput
    # We just make the functions composable, so they can be reused in both contexts
    export const onChangeInput = curry((prop, value, state) => {
      const notEmpty = value && value.length;
      const errors = { required: !notEmpty };

      return compose(
        setErrors(prop, errors),
        setValue(prop, value)
      )(state);
    });

And here's how we can use those functions:

    # MyForm.js
    import React, { Component } from 'react';
    import { onChangeInput, setError } from './Form';
    import api from 'api';

    MyForm extends Component {
      constructor(props) {
        super(props);
        this.state = { name: {} };
      }

      onChangeInput(prop, value) {
        this.setState(prevState => onChangeInput(prop, value, prevState);
      }

      submitForm() {
        const { name } = this.state;
        api.submitData({ name })
          .catch(() => {
            this.setState(prevState =>
              setError('name', { serverError: true }, prevState)
            );
          });
      }

      render() {
        const { value, errors } = this.state.name;
        return (
          <div>
            <input
              value={value}
              onChange={e => this.onChangeInput('name', e.target.value)}/>
            <ul>
              {mapValues(errors, err => (<li key={err}>{err}</li>))}
            </ul>
            <button onClick={this.submitForm}>
              Submit
            </button>
          </div>
        );
      }
    }

By exposing functions, and providing convenient aggregations of those functions,
you let the person using your component decide how much control they
really need.

Most of the time, you'll want to couple these component into the same
file as the component that uses them. For instance:

    # Form.js
    export const setErrors # ...
    export const onChangeInput # ...
    export const Input = ({ value, field, onChange }) => (
      <input value={value} onChange={e => onChange(field, e.target.value)}/>
    );

    # MyForm.js
    import { setErrors, onChangeInput, Input } from './Form';

    MyForm extends Component {
      // ...

      onChangeInput(prop, value) {
        this.setState(prevState => onChangeInput(prop, value, prevState);
      }

      render() {
        const { value } = this.state.name;
        return (
          <Input value={value} field="name" onChange={this.onChangeInput}/>
        );
      }
    }

### Don't call `this.setState` multiple times at multiple levels

This is another quick benefit of composing functions that should be
fired on an event. 

## 3. Use `context` to shield away state coordination between tightly-coupled components

Okay, so at this point we've learned that we want to get rid of unnecessary state,
and that common operations to update state can be stored in a shared module,
and used by consum

### Make components aware of, but not necessarily dependent on, context

### Alternative: make a non-rendering component that coordinates the data

## 4. Think differently about when you need a stateful component in the first place

### Create more, smaller components

### Make your stateful components stateless by moving data-fetching into an HOC
