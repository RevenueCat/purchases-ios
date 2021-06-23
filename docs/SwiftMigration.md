# Swift Migration 🐦
---

## Yeah, but like, why?
* Easier to implement in hybrid sdks.
* 🦶 Lowers our overall footprint for modules.
* 🗣️ Unifies the language used for the entire SDK.
* 🚤 Faster feature development, bug fixes on old logic, and integration through simplified SDK, CI, and testing infrastructure.
* 🧑‍🏫 Easier onboarding for new members (internal and external).

## ❌ Not in The Plan
### Code improvements
Aside from bugs, or challenges encountered (nullability, completion blocks, etc), we will not be rewriting components, this is *only* a migration. The current SDK contains years of institutional knowledge, bug fixes, and tried-and-tested paths. We will not be rewriting these things at this time. In the future, we can spin up various projects to address anything we find. That is to say, we should take notes on what should be improved and prioritized at a later date once this critical work is done. There ***might*** be cases that require rewrite for lack of API, but I currently do not anticipate this.

### 🔩 Internal API changes
In order to cut down on changing surfaces as well as keeping things as stable/knowable as possible for StoreKit 2 work, we won’t be changing any internal API. This won’t be strictly enforced, as some flexibility is needed, but overall, ensuring StoreKit 2 design work can continue with as few unknowns as possible is one of the goals. 

## Soooo what’s ***The Plan***?
### 🛩️ High-level
The plan will continue to be refined through input from the team along with discoveries throughout the process. The high-level stuff shouldn’t change very much. StoreKit 2 investigation, testing, and implementation design will happen in parallel. We’re not changing the internal API of RC, so SK2 planning should continue with the expectation that the new design will continue to need to work around any shortcomings. The planning phase for SK2 shouldn’t be largely impacted unless a refactor is needed to support the proposed changes .

**Steps:**

* New development branch swift_migration.
	* Continue to port over any bug fixes from main into swift_migration.
* Ignore SDK release things for this branch.
	* Focus on code migration, then focus on delivering the final SDK again.
* One eng to take initial project setup steps
	* Merging components, ensuring cross-Swift/ObjC visibility.
	* Eng to complete a single component migration of a high-complexity component in order to demonstrate feasibility and explore further challenges.
* Split migration work file-by-file.
	* Stub anything that is shared outside of the file to enable the build.
		* Keep a list of each eng’s current stubs.
		* Keep a list of stubs that is being migrated
	* Once the file is migrated, and the stubs need to be fleshed out, check the list of stubs being migrated, if they aren’t in it, add the stub and let the group know. 
* Testing modifications through more unit tests.
	* Ensure our current tests are sufficient.
		* Many hard-coded strings, particularly HTTP headers, URL paths, etc are not fully tested. We should update all tests to account for any changes. 
		* Modify any hard-coded data (one-by-one) and run tests. If they pass, write a breaking test. 
* MigrationTester Project fleshed out and linked into testing steps
	* If project builds, that means our current public API hasn’t been modified
		* Doesn’t account for accidental additions in API.
* Once SK2 investigation/testing/prototyping completes, we’ll need to understand our options for integration.

**Things that can be done in parallel**

* Testing updates (right after initial component merge happens).
* MigrationTester Project.
* SK2 investigation and planning.
* Maybe parts of SK2 integration.

## 🤔 Migration Risks
### Break backwards compatibility
* API
* Cocoapods
* Carthage
* SPM
* All cross-platform (Flutter, React Native, Cordova, Ionic, Unity, etc)

### Buggy release

We complete the migration, all tests pass, and our general testing doesn’t find any issues but customers start to report issues.

### Failure to deliver on time
Migration takes more time than planned, potentially delaying parts of the SK2 integration

## 🌌🧠 Derisking
* Define things we will not be doing to limit scope. ✅
* Continuously build the SDKMigrationAPITester project (currently private on GitHub, but will migrate into the SDK repo soon) that calls all public API to ensure API surface remains unchanged.
* Customer testing
	* We need testing across all our platforms 🙏
	* Open up beta as soon as possible
* Run project in GitHub- in the open for the migration
	* Use project kanban board and issues.
	* More eyes on changes.
	* Maybe people want to help?
	* More potential testers.
* Backup planning
	* One SK2 plan could encompass copying our entire sdk into a new swift module, renaming the copied ObjC files (fake namespacing since objc doesn’t have that), then making the SK2 changes in the copied files. A terrible idea, but we won't need it anyway 😄
		* Continue migration after release. 
