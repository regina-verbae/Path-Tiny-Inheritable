# Path::Tiny::Inheritable

Drop-in replacement for `Path::Tiny` that allows inheritance

As such, it is less *tiny* than `Path::Tiny`, but does adhere
to a more traditional object-oriented design.

## Features

* All `Path::Tiny` methods are available
* All constructors (except `path`) may be called with a bare class name or as a method from an existing object.
```perl
    my $path1 = Path::Tiny::Inheritable->new(...);
    my $path2 = $path1->new(...);
```
* `Path::Tiny` methods which return `Path::Tiny` objects have been overloaded to return objects constructed using `$self->new()`, guaranteeing that they will be of the same class type as `$self`.
* Auto-stringification is enabled and inheritable.
