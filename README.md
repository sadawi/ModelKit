# ModelKit

This is a framework for working with model objects.

```ruby
pod 'ModelKit'
```

Or, include only some components:
* 'ModelKit/Fields'
* 'ModelKit/Models'
* 'ModelKit/RemoteModelStore' (Alamofire dependency)

## Fields

Fields give you:
* type-safe change observation
* automatic timestamps
* validations

Basic usage:

```swift
class Person {
  let age = Field<Int>()
}
person.age.value = 10
```

For multivalued fields, there is `ArrayField`, which wraps a field object describing the single-valued type.

```swift
let tags = ArrayField(Field<String>(), name: "Tags")
```

The inner field is responsible for validations, transformations, etc..  The `ArrayField` owns top-level attributes like `name`, `key`, etc. -- but for convenience, it will copy them from the inner field at initialization.

The unary postfix operator `*` is provided to wrap a `Field` in an `ArrayField`.  So you can also write the above declaration like this:

```swift
let tags = Field<String>(name: "Tags")*
```

### Validations

Simple closure validations:

```swift
let age = Field<Int>().require { $0 > 0 }
```

Rules can be chained, too, implying an AND.  Order is not important.

```swift
let age = Field<Int>().require { $0 > 0 }.require { $0 % 2 == 0 }
```

By default, `nil` values will be considered valid.  To change that for a given rule, pass `allowNil: false` to `require`.

To validate a field value, call `field.validate()`, which returns a `ValidationState` enum:

```swift
public enum ValidationState:Equatable {
    case unknown
    case invalid([String])
    case valid
}
```

The associated value of the `.invalid` case is a list of error messages (e.g., `["must be greater than 0", "is required"]`).

### Timestamps

Fields will automatically have the following timestamps:
* `updatedAt`: the last time any value was set
* `changedAt`: the last time a new value was set (compared using `==`)

### Observers

This library includes the `ValueObserver` and `ValueObservable` protocols for generic, type-safe change observation.  Fields implement both protocols.

A `ValueObservable` can have any number of registered `ValueObserver` objects.  The `-->` operator is a shortcut for the `addObserver` method (`<--` works the same, only with its arguments swapped). Observation events are triggered once when the observer is added, and after that whenever a field value is set.

#### Adding an observer

An observer can be added if it implements the `ValueObserver` protocol, which has a `valueChanged(observable, value: value)` method.

```swift
field --> observer
```

Or, a closure can be provided.  In place of an observer object, an `owner` is used only to identify each closure.

```swift
field --> owner { value in
  print(value)
}
```

We can still register a closure even if no observer is given.  This is effectively registering the closure with a null observer.

```swift
age --> { value in 
  print("Age was changed to \(value)")
}
```

#### Binding a field to another field

Since `Field` itself implements both `ValueObservable` and `ValueObserver`, the `-->` operator can be used to create a link between two field values.

```swift
sourceField --> destinationField
```
This will set the value of `destinationField` to that of `sourceField` immediately, and again whenever `sourceField`'s value changes.

The `<-->` operator is a shortcut for `<--` followed by `-->` (and can only be used between two Fields).

```swift
field1 <--> field2
```

Since `<--` is called first, both fields will initially have the value of `field2`.

#### Unregistering

Unregistering observers is done with the `removeObserver` method, or the `-/->` operator.  All observers can be removed with `removeAllObservers()`.

### Value transformers

When serializing and deserializing, every field value goes through a value transformer. You can implement your own `ValueTransformer` subclasses and tell fields to always use them:

```swift
let birthday = Field<Date>().transform(with: MyDateTransformer())
```

### Value transformer contexts

Transformer contexts provide a way to distinguish different situations in which values are (de)serialized, and configure serialization differently in each case. 

A context contains some global rules, like: 

* Automatic casing of field keys (`keyCase`: `.snake`, `.upperCamel`, `.lowerCamel`)
* Whether nil values should be included in the serialization (`explicitNull`)

A context also provides a registry of value types to transformers. You can modify this at runtime:

```swift
ValueTransformerContext.defaultContext.transform(Float.self, with: MyCustomFloatValueTransformer())
```

You can also register a new context in an extension:

```swift
extension ValueTransformerContext {
    static let myCustomContext: ValueTransformerContext = {
        let context = ValueTransformerContext(name: "custom")
        context.transform(Int.self, with: MyCustomIntTransformer())
        return context
    }()
}
```

Finally, you can tell each field which ValueTransformer to use in each context:

```swift
let name = Field<Int>().transform(with: MyCustomIntTransformer(), in: .myCustomContext)
```

## Models

A `Model` object automatically converts to and from a dictionary representation of its `Field` properties.

```swift
person.dictionaryValue()
// --> ["name": "Bob", "tags": ["red", "blue", "green"]]
```

You can optionally provide a `ValueTransformerContext`:
```swift
person.dictionaryValue(in: .myCustomValueTransformerContext)
```

If your field's value is a subclass of `Model`, you should use the `ModelField` subclass.

```swift
let companies = ModelField<Company>()*
```

## ModelStore

This library provides a [Promise](https://github.com/mxcl/PromiseKit)-based interface for abstract data stores, specified in the `ModelStore` protocol, as well as several concrete implementations.

```swift
func create<T: Model>(model:T) -> Promise<T>
func update<T: Model>(model:T) -> Promise<T>
func delete<T: Model>(model:T) -> Promise<T>
func lookup<T: Model>(modelClass:T.Type, identifier:String) -> Promise<T>
func list<T: Model>(modelClass:T.Type) -> Promise<[T]>
```

### MemoryModelStore

This stores models in memory.  It adds a `lookupImmediately` method for synchronous identifier-based lookups.

### RemoteModelStore

This is intended as a base class for your RESTful server interface.  It includes a number of overridable hooks that you can customize for your particular needs, like:

* `defaultHeaders`
* `handleError`
* `constructResponse`

A `RESTRouter` is responsible for generating paths for resource locations.

```swift
collectionPath(for: Person.self)
instancePath(for: person)
```

Nested routes are generated automatically if your model conforms to `HasOwnerField`, which requires it to specify an owning field. If a person's owner field is its `company` field, for example, you might get `"/companies/10/employees/45"` for its instance path.

It also contains a `ValueTransformerContext` var that can be used to customize serialization.
