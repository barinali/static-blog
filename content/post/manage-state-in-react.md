+++
author = "Monica"
date = "2017-07-23T14:29:42+02:00"
tags = ["react", "redux", "javascript"]
title = "How to manage or eliminate React state without Redux"
description = "These patterns and strategies will help you manage or eliminate state in your React app in a cleaner way, without Redux."
+++

When I started writing React -- I made a big mess. Many of my components
took too many props, or my component had an immense amount of state.
Doing simple things required a lot of data manipulation, and ultimately
led to a lot of bugs. It didn't take long for simple tasks to become
extremely tedious.

I think this happens to a lot of people who start out with React. It's almost
too easy to write a lot of code, when in reality, the answer may be that
_less is more_.

A natural question while learning React inevitably crops up: Do I need to
introduce Redux into my codebase?  Will this solve some of the trouble that
I've been getting myself into?

If you're having the same kinds of problems I did, adding Redux may result in
shifting complexity to a different place in the codebase, without
actually eliminating it. In some ways, this can make it even worse:
**you've actually added indirection without reducing complexity**.

Luckily, there are a lot of ways to manage or even eliminate state
without resorting to Redux. In fact, many of these patterns are also
applicable to codebases that use Redux as well.

I wish I had known about a lot of these before I made my first spaghetti
monster of `setState`.

I hope some of these techniques can help you re-think
how you're managing state, and evaluate whether Redux will actually solve your
problems or simply move them into another file.

---

## How to better manage and eliminate state without Redux

This is a long post. You should feel free to jump to a section that
you find most interesting. If you have more techniques or ideas
to share with me, please reach out on twitter [@monicalent](https://twitter.com/monicalent).

This post is not for people writing their first React component, but
for people who have done enough to think to themselves, "There must be a better
way!"

Here's an overview of this post:

1. **[Remove things from `this.state` that don't belong there]({{< relref "#remove-things-from-state" >}})**
  - Avoid using state for data which can be calculated from props
  - Avoid using state for data which can be calculated from other state
  - Avoid transforming data you receive from the API
  - Avoid using state for data that isn't relevant for rendering
2. **[Extract state management that follows other components around]({{< relref "#extract-state-management" >}})**
  - Export state management functions alongside components
  - Build more complex state management logic out of small, composable functions
3. **[Use `context` to shield away state coordination between tightly-coupled components]({{< relref "#use-context" >}})**
  - Tightly couple some kinds of components by design
  - Use context to hide complex coordination from consumers
4. **[Think differently about when you need a stateful component in the first place]({{< relref "#think-differently" >}})**
  - Avoid introducing state merely for fetching data from the server
  - Consider whether handling UI state belongs in the parent component
  - Consider whether you really need those lifecycle methods (or are falling into a trap!)

Let's go through these one-by-one with examples of code before
and after.

---

### 1. Remove things from `this.state` that don't belong there {#remove-things-from-state}

This might feel like cheating, because I'm telling you that
you should manage state by not having it. But that's more or less
what I'm going for! There are a lot of things that can end up on
our `state` but don't need to be there.

Here are a couple of things you can take off your `state` object right away.

#### Avoid storing data in `this.state` which can be calculated from props

One pitfall that often befalls us is having to coordinate data that
comes from outside the component with data that comes from the inside.
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
as state for an initial value. Like a message you want to edit.
This is fine, because you need some way to store the intermediary value,
and you'll probably propagate that to the parent component anyways.

#### Avoid storing data in `this.state` which can be calculated from other state

One of the code smells that results from ignoring this pattern
is that you find yourself manually synchronizing data, or changing
multiple pieces of data at once. It can result in unnecessarily
complicated code as soon as you have to interact with the server,
and then update the view model.

Let me give you an example.

Let's imagine I have a `Shop`, which shows me a list of `Products`, and allows me
to add or remove a product from my `Order`.
I need to determine if a product is in my order to know which button to show,
and whether to add/remove the product when I click it.

``` jsx
import React, { Component } from 'react';
import api from 'api';

class MyShop extends Component {
  constructor(props) {
    super(props);
    this.state = { products: [], order: {} };
  }

  componentWillMount() {
    Promise.all([
      api.shop.getProducts(),
      api.shop.getCurrentOrder()
    ]).then(([products, order]) => {
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
so we can support the format that the API wants _and_ the format
our view expects.

This is a super easy way to introduce bugs into your code, which result in
the information on the server diverging from that in the view. 

Here are some strategies for avoiding this pitfall:

- **Avoid changing data you get from the API.** Sometimes you may need
  to make a tradeoff for performance reasons, but often it can be
  avoided. If you have to calcuate something often, consider
  [memoizing](https://en.wikipedia.org/wiki/Memoization) that calculation
  instead of creating a view model that is totally divorced from the format
  provided by the API.
- **Calcluate derived properties of your data during `render()`** Avoid mapping
  data for the view and then having to "unmap" it to get it into a state meant
  for the server.
- **Notice when you have to coordinate 2 or more pieces of state in
  conjunction** This is an easy way to spot that your code is getting too
  entangled.

Let's look at how this code could look if we calculated the
selected products during `render()` instead of when we get it from
the server.

``` jsx
import api from 'api';
import { without, concat } from 'lodash';

MyShop extends Component {
  constructor(props) {
    super(props);
    this.state = { order: {}, products: [] };
  }

  componentWillMount() {
    Promise.all([
      api.shop.getProducts(),
      api.shop.getCurrentOrder()
    ]).then(([products, order]) => {
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
      ? { ...order, products: concat(order.products, product) }
      : { ...order, products: without(order.products, product) };

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

#### Avoid storing data in `this.state` if it isn't relevant for rendering

This one is a quickie. If you don't need something to render, you
can store it privately inside the component (e.g. `this.callbacksList = []`)
rather than on `this.state`. 

**Takeaways**

- Avoid storing data in `this.state` which can be calculated from props
- Avoid storing data in `this.state` which can be calculated from other state
- Avoid changing data you get from the API if it results in data-juggling
  for updates.
- Avoid storing data in `this.state` if it isn’t relevant for rendering

---

### 2. Extract state management that follows other components around {#extract-state-management}

Sometimes, you end up with components that always need to have their
state managed. For example, an input field -- how often do you find
yourself typing something like this:

``` jsx
onChangeValue(e) {
  const value = e.target.value;
  this.setState({ value });
}
```

When you start to have state management logic that follows around
a component, the question arises:

* Do I need a higher-order component?
* Do I need to put this make the child a stateful component so I don't have to
  deal with it all the time?
* But then I lose access to certain data that I need in the parent.
* Argh!

How can we stop this repetition while still storing the _state_ of the
component in the _parent_ component?

#### Extract state management logic into external modules

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

#### Build more complex state mangement logic out of small, composable functions

Say your form also has to check for errors AND you want to be able to manually
set errors from the outside.  Maybe the server returned an error, or we want to
set a timeout to warn the user that they are typing too slowly.

How can we keep the code simple, while exposing the right amount
of control to the parent component?

One way is to provide low-level functions, like `setErrors` and
`setValue`, but also compose these functions
into convenient aggregates, like `onChangeInput`.

Imagine interacting with your form like this:

``` jsx
// MyForm.js
import React, { Component } from 'react';
import { some, values } from 'lodash';
import api from 'api';

// Expose `setError` to parent of the input field
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

> **On currying and composition** -- If you're not familiar with currying
  and function composition, here's a simple way to think about it:<br><br>
  A "curried" function is one that, when supplied fewer arguments than it
  expects, will accept the initial set of arguments and return a new
  function to accept the remaining ones.<br><br>
  "Function composition" just means that you can glue together some functions
  and pass data through all of them. The result of the first function
  gets passed to the second, and so on.<br><br>
  By combining currying and function composition, you can get some
  small, simple building blocks that can be combined to handle more complex
  behaviors. Let's see how below! 

By having small functions, and aggregates of those small functions,
we can expose different levels of control to components that want
to manage our component.

And at the same time, the code remains DRY and, because of how much re-use
is happening, there's less room for bugs to creep in because of
inconsistent implementation of state management.

Let's see how we can implement `setErrors`, `setValue`, and then
aggregate them into `onChangeInput`:

``` jsx
// Form.js
import { curry, some, values, flow } from 'lodash';
```

First we want to import a couple helpers. Of course, you can implement
these manually as well.

```jsx
export const setErrors = curry((prop, errs, state) => {
  const errors = { ...state[prop].errors, ...errs };
  const isValid = !some(values(errors));
  return { ...state, [prop]: { ...state[prop], errors, isValid } };
});
```

Then, we want to implement our `setErrors` function. Notice that it
accepts some arguments, `prop` and `errs`, and always accepts
`state` last. This helps to make our function composable later!

All functions accept these three things, with state last, and
return a new state.

```jsx
export const setValue = curry((prop, value, state) => {
  return { ...state, [prop]: { ...state[prop], value } };
});
```

No surprises when we `setValue` either. Our arguments first, state last,
and return a new state.

```jsx
export const onChangeInput = curry((prop, value, state) => {
  const notEmpty = value && value.length;
  const errors = { required: !notEmpty };

  return flow(
    setValue(prop, value),
    setErrors(prop, errors)
  )(state);
});
```

Here's where it gets a little more interesting! You can see that
we are using our other functions, `setValue` and `setErrors`, and we
supply them only 2 of the 3 arguments they expect. Because these functions
are curried, we know that the result of executing these functions will
be functions that still accept `state`.

You could also see this in the following way:

```jsx
const withValue = setValue(prop, value);
const withErrors = setErrors(prop, errors);
return withErrors(withValue(state));
```

Using `flow` is just a nicer and more readable way to express the exact same
thing :)

```jsx
export function Input({ value, onChange }) {
  return (
    <input value={value} onChange={onChange}/>
  );
}
```

Lastly of course, we have the component itself, living in the same
file as its high-level and low-level state management functions. Anyone
who imports `Input` can also import the functions that will manage its state
as well.

This way, a consumer of the `Input` can really decide how hands-on
they want to be when using the component. `onChangeInput` does it all,
but if you want to meddle, it's easy to do.

There are a lot of places where you can use this pattern:

- Create the initial state used by the component (to ensure that the
  structure of the state is operable by the helper functions)
- Make gradual changes to the state (a la setErrors, setValue)
- Make grouped changes to the state (a la onChangeInput)

**Takeaways**

- Extract state management logic into external modules
- Build more complex state mangement logic out of small, composable functions
- Provide these functions to create consistency and convenience for consumers
  of the component, while still giving the parent component access to all the
  state.

---

### 3. Use `context` to shield away state coordination between tightly-coupled components {#use-context}

Context is an unstable API. Warnings abound. Disclaimer over.

> If you're not familiar with Context in React, you can
  [read about it in the React docs](https://facebook.github.io/react/docs/context.html).

### Tightly couple some kinds of components by design

Context is a really cool way to glue components together in a way that
makes their state handling transparent to the consumer.

In the previous section, we learned about how you can export state management
functions next to your component to keep from re-implementing the same thing
every time you need to use a "dumb" component.

But what if I told you there was a way to shield away all of that from
the parent? So you don't even _need_ to import those extra functions,
you can just delcare your components and they're going to
_magically_ work together.

You can accomplish this with React's `context` API.

The tradeoff (besides the fact that the API is unstable) is that
context inherently couples your components together. For
example, with a `Form` component that uses context to coordinate the
data of its children (e.g. `Input` or `Select`), those children
can't really work anymore without being wrapped in a `Form`.

It might seem scary, but at the same time, there are times when this
just makes sense.

When do `Input`s make sense without a `Form`? When does an
`CloseButton` make sense without a `Modal`?

Once you've decided that one or more components _should_ be tightly
coupled, you can make it extraordinarily painless to work with them
in your application. 

### Use context to hide complex coordination from consumers

Imagine if using your form looked like this:

```jsx
import React, { Component } from 'react';
import { Form, Input } from './Form';

class MyForm extends Component {
  constructor(props) {
    super(props);
    this.state = { name: { value: '' } };
  }

  onChange(form) {
    this.setState(form);
  }

  render() {
    return (
      <Form data={this.state} onChange={this.onChange}>
        <Input field="name" />
      </Form>
    );
  }
}
```

Yep, it can be that simple.

Let's look at the internals of `Form` and `Input` to get a better
idea of what is going on behind the scenes.

```jsx
const FORM_CONTEXT = {
  form: PropTypes.shape({
    data: PropTypes.object,
    onChange: PropTypes.func,
    onFieldChange: PropTypes.func
  }).isRequired
};
```

First we start by declaring our context. We can namespace it into
an object called `form`. This means that anytime we want to make
a component context-aware, we'll use `FORM_CONTEXT` (which you'll see below!)

Then we create our Form component, which must implement a function
called `getChildContext`. What this returns must be in the shape defined by
`FORM_CONTEXT`.

More or less, it just uses the `props` it receives, and provides one convenient
function on top called `onFieldChange`.

```jsx
class FormComponent extends Component {
  getChildContext() {
    const { data, onChange } = this.props;
    return {
      form: {
        data,
        onChange,
        onFieldChange: field => e => {
          e.stopPropagation();
          const nextData = {
            ...data,
            [field]: { value: e.target.value }
          };
          onChange(nextData);
        }
      }
    }
  }
  render() {
    return (
      <form>{children}</form>
    );
  }
}

FormComponent.childContextTypes = FORM_CONTEXT;
export const Form = FormComponent;
```

And as you can see, we need to tell the form that it should expose
a context to its children in the shape of `FORM_CONTEXT`. From this point,
and child can also opt-in to getting this data.

Let's see how our `Input` accesses the context!

```jsx
function Input(props, context) {
  const { field } = props;
  const { form: { data, onFieldChange } } = context;

  return (
    <input
      name={field}
      value={data[field].value}
      onChange={onFieldChange(field)}/>
  );
}

Input.contextTypes = FORM_CONTEXT;
```

Notice how the field's `value` and `onChange` come from the `context`,
rather than from `props`. This is how we shield away state
coordination logic into a layer of context, instead of implementing it
(or importing it) every time we have to use the component.

Now, simply updating a field's value is pretty simple, but imagine
introducing form validation. Suddenly, many different components have
to become aware of the error state of a field (e.g. labels, an error
list, the submit button).

The complexity of state coordination can become very intense, and without
shielding it away, you end up with a lot of boilerplate everytime you want
to use a form. This way, you can keep the boilerplate in one place and
expect consistent handling of your data whenever you use the component!

**Takeaways**

- Some components are tightly-coupled by nature.
- Avoid repetative state-management logic by hiding this coordination inside context.
- When you have to refactor this one day, you also only have to change
  what's happening inside the context provider, rather than in every
  single consumer that uses your component.

---

### 4. Think differently about when you need a stateful component in the first place {#think-differently}

What are some of the reasons we introduce state into a react component in the
first place? Three of the main use cases that come to mind are:

1. Fetching data from the server (e.g. during `componentDidMount`)
2. Handling UI state (e.g. something is loading, collapsed, disabled, etc.)
3. Using lifecycle methods (e.g. `componentWillReceiveProps`)

Let's have a quick look again at how, in these scenarios, we can actually
avoid having a stateful component in the first place!

#### Fetching data from the server

This can be one of the most annoying things when you're creating a new
component - it's _almost_ stateless, but it really needs data from
the server. Sometimes it makes sense to store that data in the parent,
but other times, it's just clutter for the parent state - especially
if this server data is never actually going to change.

This is something we can solve using a higher-order component (HOC),
named `withData`. Imagine you use it like this:

```jsx

function CountryList({ countries }) {
  return (
    <ul>
      {countries.map((country, i)=> (<li key={i}>{country}</li>))}
    </ul>
  );
}

const enhancedCountryList = withData({
  countries: () => api.countries.getCountries();
})(CountryList);
```

The idea is simply that instead of fetching data inside the component,
you wrap it in HOC which will fetch the data (using `componentWillMount`)
and, once the data has been fetched, render the original component with
the data as props.

Here's a super simple way you could implement a component like `withData`:

```jsx
import { pure } from 'recompose';
import { createElement, Component } from 'react';

class Container extends Component {
  constructor(super) {
    super(props);
    this.state = { pending: false, resolvedProps: null };
  }

  componentWillMount() {
    this.fetch(this.props);
  }

  /*
   * Take the object you got as props. Resolve all promises.
   * Then render the original component with a hash of data resulting
   * from those promises.
   */
  fetch(props) {
    this.setState({ pending: true });
    const { config } = props;
    const fns = Object.values(config);
    const keys = Object.keys(config);

    Promise.all(fns).then(results => {
      const resolvedProps = keys.reduce((memo, key, i) => {
        memo[key] = results[i];
        return memo;
      }, {});

      this.setState({ pending: false, resolvedProps });
    });
  }

  render() {
    const { pending, resolvedProps } = this.state;
    const { component, originalProps } = this.props;

    if (pending) {
      return null;
    }

    return createElement(component, { ...originalProps, resolvedProps });
  }
}

export default function withData(config) {
  return component => pure((originalProps) => {
    return createElement(Container, { component, originalProps, config });
  });
}
```

With a HOC like this, you can avoid creating a stateful component merely
because you need to make a request to provide data to the component.

#### Handling UI state

One of the other main reasons to create a stateful component in the first
place is to handle the state of the UI. Is this button disabled?
Is this section collapsed? Is this modal visible?

Here you have to make the important choice: does managing this
UI state belong in this component, or in its parent?

In many cases, this is a perfectly acceptable use of `state`, but you may
want to consider moving it into the parent of the component instead
of inside the component itself. Much of the time, you may be able to solve
this by [exporting components and state management functions together](#extract-state-management)
if it's a complex operation, or you can get away with one tiny function
to set a single value in the parent, which doesn't warrant all the ceremony.

This is one of the few good reasons to have state inside a component.

#### Using lifecycle methods

From time to time, you _do_ need to use lifecycle methods. Hopefully you've
already seen how to avoid using many of them (e.g. [by calculating values from
during `render` instead of storing values in `state`](#remove-things-from-state)), but
there are simply times where you need to use them.

This is another good reason to have state inside a component, but watch
out that you aren't falling into a trap related to having `state` that
ought to be calculated during `render`!

## Conclusion

You made it to the end - I'm impressed! I hope this post gives you some
resources to think differently about your state management problems, and
come up with solutions where you can remove logic instead of just moving
it around.

As I said at the beginning: if you have comments, questions, or corrections,
please feel free to reach out to me on twitter! [@monicalent](https://twitter.com/monicalent)
