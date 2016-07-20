# qml.nim - [Qt QML](http://doc.qt.io/qt-5/qtqml-index.html) bindings for [Nim](http://nim-lang.org/)

**QML bindings for Nim w/o pains**

qml.nim allows:
- Create QML Engine and load QML script
- QML can access Nim objects and invoke Nim procs

This project is a fork of [go-qml](https://github.com/go-qml/qml), with help from other projects:
- [DOtherSide](https://github.com/filcuc/DOtherSide)
- [nimqml](https://github.com/filcuc/nimqml)
- [qmlrs](https://github.com/cyndis/qmlrs)

## What's working
This project is under development, working features will be updated here.

- Load QML script and display window
- Read/write Nim data from QmlEngine
- Set and get QmlContext property
- Retrive instance of a QML component

## Requirements
- Qt5
- fasm (for compile coro module)

## Installation
```sh
$ nimble install qml
```

## Examples

See [examples](./examples) folder

## Licensing
This code is licensed under LGPL-3.0. See [LICENSE](./LICENSE) for details.
