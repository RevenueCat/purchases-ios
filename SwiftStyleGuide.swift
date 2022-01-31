//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SwiftStyleGuide.swift
//
//  Created by Andrés Boedo on 7/12/21.
//

// imports should be alphabetized
import Foundation

// keep one empty line after type declarations, and one before the end of it
protocol ValuePrintable {

    // make protocol variables read-only unless needed
    func foo() -> String

}

// use protocol extensions for default implementations of protocols for types
extension ValuePrintable where Self: NSNumber {

    func foo() -> String {
        return "the number as float is: \(self.floatValue)"
    }

}

// prefer structs to classes whenever possible.
// keep in mind that structs are value types.
// More info here: https://developer.apple.com/documentation/swift/choosing_between_structures_and_classes

// documentation is required for each public entity.
// Use jazzy-compatible syntax for documentation: https://github.com/realm/jazzy#supported-documentation-keywords
/// The MyStruct struct is responsible for ...
struct MyStruct {

    // don't explicitly define types unless needed.
    // prefer let to var whenever possible.

    // public properties, then internal, then private.
    /// mercury is used for ...
    public let mercury = false

    /// saturn is used for ...
    public var saturn: String?

    /// eath is used for ...
    public static var Earth = "earth"

    // use public private(set) when a public var is only written to within the class scope
    /// this variable will be readonly to the outside, but variable from inside the scope
    public private(set) var onlyReadFromOutside = 2.0

    // for internal properties, omit `internal` keyword since it's default
    let mars = 4.0

    private var jupiter = 2

    // use the valuesByKey naming convention for dictionary types
    private var productsByIdentifier: [String: Product]

    // public methods in the main declaration

    /// This method prints the planets
    public func foo() {
        // use explicit `self` to make it clear that it's accessing a member
        // versus a global or value in the local context
        print(self.mercury)
    }

    func whenMethodIsTooLongToFitInOneLine(becauseOfTooMany: Int,
                                           parameters: String,
                                           eachOne: Float,
                                           shouldBeInItsOwnLine: Double) {}

    // swiftlint:disable:next multiline_parameters
    func whenMethodIsTooLongToFitInOneLine(
        becauseOfTooMany: Int,
        parameters: String,
        eachOne: Float,
        shouldBeInItsOwnLine: Double,
        // special file / function / line parameters may be grouped together in their own line
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) {

    }

}

// separate protocol conformance into extension
// so methods from the protocol are easy to locate
extension MyStruct: MyProtocol {

    // return can be omitted for one-liners
    func foo() -> String { "foo" }

}

// use protocol-oriented programming to add behaviors to types
// https://developer.apple.com/videos/play/wwdc2015/408/
extension MyStruct: PrettyPrintable { }

// add error extensions to make it easy to map errors to situations
enum MyCustomError: Error {

    case invalidDateComponents(_ dateComponents: DateComponents)
    case networkError

}

// private methods in an extension
private extension MyStruct {

    func somethingPrivate() -> String {
        return Bool.random() ? .saturn : .nepturn
    }

    func someMethodThatThrows() throws {
        throw Bool.random() ? MyCustomError.invalidDateComponents(DateComponents())
                            : MyCustomError.networkError
    }

    func methodThatNeedsToCaptureSelf() {
        // great guide on when and when not to capture self strongly
        // https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html#ID56

        // no need to explicitly capture self if you need a strong reference
        foo.methodThatNeedsStrongCapture {
            // ...
            self.bar()
        }

        // but of course we do add it for weak references
        foo.methodThatNeedsWeakCapture { [weak self] in
            // we need to make self strong again, because the object could be dealloc'ed while
            // this completion block is running.
            // so we capture it strongly only within the scope of this completion block.
            guard let self = self else { return }
            // from this point on, you can use self as usual
            self.doThings()
            // ...
        }
    }

}

// use private extensions of basic types to define constants
private extension String {

    static let saturn = "saturn"
    static let neptune = "neptune"

}

// Use one line per let in a guard with multiple lets.
let taco = restaurant.order("taco")
let coffee = restaurant.order("coffee")
guard let taco = taco,
      let coffee = coffee else {
    return
}

// Also use one line per condition.
guard 1 == 1,
      2 == 2,
      3 == 3 else {
    print("Universe is broken")
    return
}

// use _ = Task<Void, Never> for task initialization, so that if a part of the
// Task throws, the compiler forces us to handle the exception
// More info here: https://rev.cat/catching-exceptions-from-tasks
_ = Task<Void, Never> { // Note: this implicitly captures `self`, so have to think about retain cycles.
    try await self.myMethodThatThrows()
}
// Alternatively, if possible, store a reference to the task to call `cancel()`
// on `deinit`.
self.taskHandle = Task { [weak self] in
    try await self?.myMethod()
}
