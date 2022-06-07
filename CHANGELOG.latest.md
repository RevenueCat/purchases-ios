_This version supports Xcode 14 beta 1_

* `PurchasesOrchestrator.handleDeferredTransaction`: check `NSError.domain` too (#1665) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: replaced manual `Lock` with `Atomic` (#1664) via NachoSoto (@NachoSoto)
* `CodableStrings.decoding_error`: added underlying error information (#1668) via NachoSoto (@NachoSoto)
* Fixed Xcode 14 compilation: avoid `@available` properties (#1661) via NachoSoto (@NachoSoto)