+++
author = "Monica"
date = "2017-06-10T14:29:42+02:00"
description = ""
tags = ["react", "redux", "javascript"]
title = "Patterns and strategies for managing state in React"
+++

Main strategies:

1. **[Remove things from `this.state` that don't belong there]({{< relref "#remove-things-from-state" >}})**
  - Avoid using state for data that doesn't change
  - Avoid using state for data which can be calculated from props
  - Avoid using state for data which can be calcuated from other state
  - Avoid transforming data you receive from the API
  - Avoid using state for data that isn't relevant for rendering
2. **[Extract state management that follows other components around]({{< relref "#extract-state-management" >}})**
  - Export state management functions alongside components
  - Build more complex state management logic out of small, composable functions
3. **[Use `context` to sheild away state coordination between tightly-coupled components]({{< relref "#use-context" >}})**
  - Tightly couple some kinds of components by design
  - Use context to hide complex coordination from consumers
4. **Use non-rendering components to coordinate data when you need lifecycle methods**
  - Move state-coordination into a component that sits between the two you're coordinating
5. **[Think differently about when you need a stateful component in the first place]({{< relref "#think-differently" >}})**
  - Avoid introducing state merely for fetching data from the server
  - Avoid introducing state merely for handling UI state

Let's go through these one-by-one with examples of code before
and after.

## 1. Remove things from `this.state` that don't belong there {#remove-things-from-state}

This might feel like cheating, because I'm telling you that
you should manage state by not having it. But that's more or less
what I'm going for! There are a lot of things that can end up on
our `state` but don't need to be there.

### Avoid storing data that doesn't change

``` jsx
import React, { Component } from 'react';

class MyComponent extends Component {
  constructor(props) {
    super(props);
    this.state = {
      // If my component is going to render differently
      // based on a query parameter, this doesn't change
      hideOption: window.location.search.indexOf('hide_option') !== -1
    };
  }

  render() {
    if (this.state.hideOption) { return null; }
    return (<div>You have an option</div>);
  }
}
```

Data that never changes doesn't belong in the state, because state
is meant to trigger the `render()` function when it updates.
If you store static data in `this.state`, you're just cluttering the
information present.

**Alternative #1: Attach your data directly to `this`**

``` jsx
class MyComponent extends Component {
  constructor(props) {
    super(props);

    // React classes are just fancy functions
    // We can just attach the data to `this`

    this.hideOption = window.location.search.indexOf('hide_option') !== -1;

    // Or, organize it inside another object on `this`
    this.data = {
      hideOption: window.location.search.indexOf('hide_option') !== -1;
    };
  }

  render() {
    if (this.hideOption) { return null; }
    return (<div>You have an option</div>);
  }
}
```

**Alternative #2: Store your data outside the component declaration**

``` jsx
// Import your data from an external module
import { VALID_VALUES } from './valid-values';

// Or, declare it as a variable
const VALID_VALUES = ['a', 'b', 'c'];

class MyComponent extends Component {
  render() {
    if (!VALID_VALUES.includes(this.props.value)) { return null; }
    return (<div>Your value is valid</div>);
  }
}
```

### Avoid storing data in `this.state` which can be calculated from props

As I said before, the easiest way to avoid state managment is by putting
fewer pieces of data on state. Another pitfall comes when you have
to start coordinating data, and potentially using react's lifecycle methods
to keep data from the outside in-sync with internal data.

Here's a silly example, where I want that any incoming message
gets an exclamation point:

``` jsx
class MyComponent extends Component {
  constructor(props) {
    super(props);
    this.state = { message: props.message + "!" };
  }
  componentWillReceiveProps(props) {
    this.setState({ message: props.message + "!" });
  }
  render() {
    return (
      <div>{this.state.message}</div>
    );
  }
}
```

Alternative: whenever you need to render based on props, keep the logic for
doing that inside the `render` method. For instance:


``` jsx
render() {
  const excitedMessage = this.props.message + "!";
  return (<div>{excitedMessage}</div>);
}
```

> Exception: Sometimes you want to use the data you pass into a component
as props for an initial value. Like a message you want to edit.
This is fine, because you need some way to store the intermediary value,
and you'll probably propagate that to the parent component anyways.

### Avoid storing data in `this.state` which can be calculated from other state

One of the code smells that results from ignoring this pattern
is that you find yourself manually synchronizing data, or changing
multiple pieces of data at once. It can result in unnecessarily
complicated code as soon as you have to interact with the server,
and then update the view model.

Let me give you an example.

Let's imagine I have a Shop, which shows me a list of Products, and allows me
to add or remove a product from my basket.

I need to determine if a product is in my order to know which button to show,
and whether to add/remove the product when I click it.

``` jsx
import React, { Component } from 'react';
import api from 'api';

MyShop extends Component {
  constructor(props) {
    super(props);
    this.state = { products: [], order: {} };
  }

  componentWillMount() {
    Promise.all[
      api.shop.getProducts(),
      api.shop.getCurrentOrder()
    ].then(([products, order]) => {
      // Get the ids of all the products that are in my order now
      const orderProductIds = order.products.map(p => p.id);

      // Set a "selected" flag on the item in the list of all products
      const uiProducts = products.map(p => {
        const selected = orderProductIds.indexOf(p.id) !== -1;
        return { ...p, selected };
      });

      this.setState({ products: uiProducts, order });
    });
  }

  toggleProductInOrder(product) {
    // What's going to happen here...
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
```

Already, this is a bit tedious, right? Now imagine that I have
to add/remove products from my order. Suddenly, I have to coordinate my
`order.products` and my normal `products` whenever I make a change,
because I have to update the `selected` field AND get the new order
(containing things like a new total, etc.).

``` jsx
toggleProductsInOrder(product) {
  // Take all our products, flip the selected one,
  // and get a new list to send to the server
  const newProducts = this.state.products.map(p => {
    if (product.id !== p.id) { return p; }
    return { ...p, selected: !p.selected };
  });

  // Filter out the selected products
  const newOrderProducts = newProducts.filter(p => p.selected);
  const updatedOrder = { ...this.state.order, products: newOrderProducts };

  // Update both the order and the products
  return api.shop.updateOrder(updatedOrder)
    .then(newOrder => {
      this.setState({ order: newOrder, products: newProducts });
    });
```

You can see how now, we are manually coordinating two pieces of data
so we can support the format that the API wants and the format
our view expects. 

Here are some strategies for avoiding this pitfall:

- **Avoid changing data you get from the API.** Sometimes you may need
  to make a tradeoff for performance reasons, but usually it can be
  avoided.
- **Calcuate properties of your data during `render()`** Avoid mapping
  data for the view and then having to "unmap" it to get it into
  a state meant for the server.
- **Notice when you have to coordinate 2 or more pieces of state in conjunction** This is an easy way to spot that you code is getting too entangled.

Let's look at how this code could look if we calculated the
selected products during `render()` instead of when we get it from
the server.

``` jsx
import api from 'api';
import { without } from 'lodash';

MyShop extends Component {
  constructor(props) {
    super(props);
    this.state = { order: {}, products: [] };
  }

  componentWillMount() {
    Promise.all[
      api.shop.getProducts(),
      api.shop.getCurrentOrder()
    ].then(([products, order]) => {
      // Benefit 1: No pre-processing of our data from the server
      this.setState({ products, order });
    });
  }

  toggleProductInOrder(product) {
    const { products, order } = this.state;
    const selectedProduct = this.getSelected(product);

    // Benefit 2: Updating an order is just adding or removing on item
    // from an array. You get to send the data as-is to the API.
    const updatedOrder = !selectedProduct
      ? { ...order, products: [...order.products, { ...product, quantity: 1 }] }
      : { ...order, products: without(products, product) };

    return api.shop.updateOrder(updatedOrder)
      .then(newOrder => {
        // Benefit 3: After updating the order, just one piece
        // of data must be changed on state
        this.setState({ order: newOrder });
      });
  }

  getSelected(product) {
    return this.state.order.products.find(p => p.id === product.id);
  }

  render() {
    const { order, products } = this.state;

    // Benefit 4: The render code barely changed,
    // but the logic and data juggling is gone!
    return (
      <ul>
        {products.map(product => (
          <li key={product.id}>
            {product.name}
            <button
              type="button"
              onClick={() => this.toggleProductInOrder(product)}>
              {!this.getSelected(product) ? '+ Add' : '- Remove'}
            </button>
          </li>
        )}
      </ul>
    );
  }
}
```

### Avoid storing data in `this.state` if it isn't relevant for rendering

This one is a quickie. If you don't need something to render, you
can store it privately inside the component rather than on `this.state`.

> Example needed

**Takeaways**

- Avoid storing data that doesn’t change
- Avoid storing data in this.state which can be calculated from props
- Avoid storing data in this.state which can be calculated from other state
- Avoid changing data you get from the API if it results in data-juggling
  for updates.
- Avoid storing data in this.state if it isn’t relevant for rendering

## 2. Extract repetative state-management logic into small, composable functions {#extract-state-management}

Sometimes, you end up with components that always need to have their
state managed. For example, an input field -- how often do you find
yourself typing something like this:

``` jsx
onChangeValue1(e) {
  const v1 = e.target.value;
  this.setState({ value1: v1 });
}
```

When you start to have state management logic that follows around
a component, the question arises:

* Do I need a higher-order component?
* Do I need to put this make the child a stateful component so I don't have to
  deal with it all the time?
* But then I lose access to certain data that I need in the parent.
* Argh!

How can we stop this repetition while still storing the state of the
component in the container?

### Extract state management logic into external modules

It seems obvious, but often times people are looking for the "React
solution" to this problem. In reality, the solution has nothing to do
with React -- it's just javascript!

``` jsx
// Form.js
export function onChangeInput(prop, value, state) {
  return {
    ...state,
    [prop]: value
  };
}

export function Input({ value, onChange }) {
  return (
    <input value={value} onChange={onChange}/>
  );
}
```

By storing the component and its state-handling function in the same
file, it's super easy to import them and use them together.

``` jsx
// MyForm.js
import { Input, onChangeInput } from './Form';
class MyForm extends Component {
  constructor(props) {
    props(props);
    this.state = { name: 'A name' };
  }

  onChange(prop) {
    return e => {
      this.setState(prevState =>
        onChangeInput(prop, e.target.value, prevState)
      );
    }
  }

  render() {
    return (
      <Input
        value={this.state.name}
        onChange={this.onChange('name')}/>
    );    
  }
}
```

Now, this is arguably _almost_ the same amount of code as we had before.
We we actually saving an repeition?

Let's imagine our form is more complex (which, let's be real, is _always_ the case).

### Build more complex state mangement logic out of small, composable function

Say your form also has to check for errors AND you want to be able to manually
set errors from the outside.  Maybe the server returned an error, or we want to
set a timeout to warn the user that they are typing too slowly.

``` jsx
// MyForm.js
import React, { Component } from 'react';
import { some, values } from 'lodash';
import api from 'api';

// Expose `setError` to containers of the input field
import { Input, onChangeInput, setError } from './Form';

MyForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      name: {
        value: '',
        errors: { required: true },
        isValid: false  
      }
    };
  }

  onChangeInput(prop) {
    return e => {
      const value = e.target.value;

      // onChangeInput must also set errors
      this.setState(prevState => onChangeInput(prop, value, prevState));
    }
  }

  submitForm() {
    const { name } = this.state;
    api.submitData({ name })
      .catch(() => {
        this.setState(prevState =>
          // And we need to have control of those errors,
          // which isn't tied only to changing the input
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
          onChange={e => this.onChangeInput('name')}/>
        <ul>
          {mapValues(errors, err =>
            (<li key={err}>{err}</li>)
          )}
        </ul>
        <button onClick={this.submitForm}>
          Submit
        </button>
      </div>
    );
  }
}
```

How can we keep the code simple, while exposing the right amount
of control to the container component?

One way is to provide low-level functions, like `setErrors` and
`setValue`, but also compose these functions
into convenient aggregates, like `onChangeInput`.

> **On currying and composition** -- If you're not familiar with currying
  and function composition, here's a quick intro. **TODO**

Here's one way to do that:

``` jsx
// Form.js
import { curry, some, values, flowRight as compose } from 'lodash';

// I have a function that gets the errors and the state,
// and returns a new state with errors set
export const setErrors = curry((prop, errs, state) => {
  const errors = { ...state[prop].errors, ...errs };
  const isValid = !some(values(errors));
  return { ...state, [prop]: { ...state[prop], errors, isValid } };
});

// And a function that gets the value and state, and return a new state
export const setValue = curry((prop, value, state) => {
  return { ...state, [prop]: { ...state[prop], value } };
});

// And lastly, since I want to both set the value AND set errors when
// the input is changed, I create a third function that
// composes the previous two
export const onChangeInput = curry((prop, value, state) => {
  const notEmpty = value && value.length;
  const errors = { required: !notEmpty };

  return compose(
    setErrors(prop, errors),
    setValue(prop, value)
  )(state);
});

// And, the component itself
export function Input({ value, onChange }) {
  return (
    <input value={value} onChange={onChange}/>
  );
}
```

This way, a consumer of the `Input` can really decide how hands-on
they want to be when using the component. `onChangeInput` does it all,
but if you want to meddle, it's easy to do.

There are a lot of places where you can use this pattern:

- Create the initial state used by the component
- Make gradual changes to the state (setErrors, setValue)
- Make grouped changes to the state (onChangeInput)

**Takeaways**

- Extract state management logic into external modules
- Build more complex state mangement logic out of small, composable function
- Providing these functions creates consistency and convenience for consumers of the component

## 3. Use `context` to sheild away state coordination between tightly-coupled components {#use-context}

## 4. Think differently about when you need a stateful component in the first place {#think-differently}

What are some of the reasons we introduce state into a react component in the
first place?

### To fetch data from the server

### To handle UI state

### 
