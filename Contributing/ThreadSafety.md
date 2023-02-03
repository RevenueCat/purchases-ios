# Thread Safety 👾
---

## What is it?

There are several places in the SDK that require synchronization. In other words, the SDK needs to ensure that multiple users can't simultaneously read and write while causing data races.

To aid with that task there are several abstractions available:

### `Lock`

This type is a building block to guarantee such synchronization. Its only method `perform` can be used to do that:
```swift
class Data {
    private let lock = Lock()

    private var calls = 0

    func threadSafeMethod() -> Int {
        return self.lock.perform {
            self.calls += 1
            return self.calls
        }
    }
}
```

If you need the lock to be _reentrant_ (so that calling `perform` recursively won't cause deadlocks), you can use `Lock(.recursive)`:

```swift
class Data {
    private let lock = Lock(.recursive)

    private var calls = 0

    func threadSafeMethod() -> Int {
        return self.lock.perform {
            self.threadSafeIncrement()
            return self.calls
        }
    }

    private func threadSafeIncrement() {
        return self.lock.perform {
            self.calls += 1
        }
    }
}
```

### `Atomic`

If what needs to be synchronized is a piece of data, this can be more easily accomplished using `Atomic`. It serves the same purpose as `Lock`, but makes handling data in a thread-safe manner easier.

It encapsulates a type `T`, and guarantees no read or write to that value can result in race conditions:

```swift
class Data {
    private let calls = Atomic<Int>(0)

    func threadSafeIncrement() -> Int {
        return self.calls.modify { calls in
            calls += 1
            return calls
        }
    }

    var threadSafeValue: Int {
        return self.calls.value
    }
}
```


### `SynchronizedUserDefaults`

Some places in the SDK (`DeviceCache` being one example) need to provide safety around reads and writes to `UserDefaults`.

`SynchronizedUserDefaults` can be used in such cases to provide the same guarantees. It's built on top of `Atomic`, so it works in a similar way:
```swift
class Data {
    private let userDefaults = SynchronizedUserDefaults(userDefaults: .main)

    func threadSafeIncrement() {
        self.userDefaults.write {
            let calls = $0.integer(forKey: "key") + 1
            $0.set(calls, forKey: "key")
        }
    }

    var threadSafeValue: Int {
        return self.userDefaults.read {
            $0.integer(forKey: "key")
        }
    }
}
```
