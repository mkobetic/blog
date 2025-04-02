---
title: ResourcefulTestCaseToo
date: 2010-03-29
tags:
  - smalltalk
  - sunit
---

(Republished from [Cincom Smalltalk Tech Tips](https://csttechtips.wordpress.com/2010/03/))

Good while ago I posted [ResourcefulTestCase](https://csttechtips.wordpress.com/2007/05) talking about a simplified pattern for test resources in the context of SUnit. Basic idea was that if you tend to group your test cases around their required resource you often end up with a package where many TestCase classes are mirrored with TestResource classes one-to-one. In this situation it is more convenient to simply use the class side of the TestCase class as its resource and cut the amount of classes by half. Moreover, various resource aspects can be placed into class side variables and conveniently accessed from instance side test methods.

Recently I started using SUnitToo and wanted to try the same sort of pattern there. It turned out to be so simple, that it's not even worth adding a dedicated abstract TestClass to emulate the pattern.

To declare that a test class is its own resource simply add following (rather obvious) class method

```
resources

	^Array with: self
```

Two more methods are needed to make the resource work: #isAvailable and #reset. They can be directly used to for set-up and tear-down, although note that #isAvailable must return a Boolean. Just return true at the end of the method and you're set. You can return false to signal that resource failed to set-up but an exception will have the same effect.

Now, without repeating all the arguments, the original article recommends to use shared variables for various aspects of the resource. Here is the rest of an example of a hypothetical test resource:

```
isAvailable

	TestDirectory := '/dev/shm/testing' asFilename.
	TestDirectory ensureDirectoryExists.
	self generateTestContentIn: TestDirectory.
	^true
```

And don't forget to nil out the shared variables in tear-down.

```
reset

	UnixProcess shOne: 'rm -r ', TestDirectory asString.
	TestDirectory := nil.
```

That's it. The only boilerplate code is the rather trivial and obvious 'self' in the *resources* method.