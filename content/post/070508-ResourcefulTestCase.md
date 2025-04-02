---
title: ResourcefulTestCase
date: 2007-05-08
tags:
  - smalltalk
---

(Republished from [Cincom Smalltalk Tech Tips] (https://csttechtips.wordpress.com/2007/05/))

The core SUnit package provides support for shared test resources via the TestResource class. A TestCase that wants to use TestResources is expected to list all its resource classes in its class side #resources method. Individual test case methods then access the resources via the resource classes, usually as default, singleton instances. That provides potentially interesting levels of flexibility, however the access to the resources themselves is not exactly convenient. In my experience vast majority of cases involving TestResources either keep repeating the ‘self resources first default blah’ incantation over and over again, where blah is the name of the real resource the case cares about which is being managed in a blah instance variable of the corresponding TestResource subclass. A more palatable way is adding the same instance variables to the TestCase subclass as well and copying the resource pieces there in the TestCase>>setUp method. Then you can access the resources directly as instance variables in your test case methods. This way the test methods are clean again, but when you want to employ test resources you still have to go through the following sequence of steps:

1. create a TestResource subclass
2. add it to the TestCase class>>resources method
3. add the same set of instance variables to the TestCase subclass
4. copy the contents of the TestResource default instance to the TestCase instance variables in TestCase>>setUp method

Naturally as you realize you’re doing this over and over again, you start thinking, wouldn’t it be nice if you didn’t have to. My first thought was, what if the TestSuite that gets built out of a given TestCase subclass didn’t simply create empty TestCase instances, but instead first created a prototype instance, invoke something like #suiteSetUp on it, which would allow to initialize the shared resources and put them directly into the instance variables of the case prototype. Then all the test cases would be built by simply copying the prototype instance and therefore would have the resource inst vars automagically initialized the same way as the prototype. Tear down could be performed by invoking #suiteTearDown on either the prototype or any of the cases. It doesn’t really matter which one, you just have to make sure it is executed exactly once.

Of course while I was enjoying myself following this thread of thought, I forgot one important detail. TestCase instances are not created just before the suite runs. They are often created much much earlier. That of course directly conflicts with the desire to initialize the resources just before they are needed and shutting them down right after the run is complete. I was just about to descend into yet another desperate attempt to rewrite most of SUnit when Alan Knight, who happened to be traveling with me at that moment, responded to my loud complaints with simple: “Just put them into class variables.”

And so the ResourcefulTestCase was born. It is an abstract TestCase subclass with simplified support for shared test resources. Instead of separate classes of test resources, it makes sure that if there are class side #setUp and #tearDown methods defined on the class, they run before and after the test suite that gets built out of this test class. This allows one to initialize and store shared resources in class side variables in the #setUp method. It’s probably easiest to use shared class variables for easy access from the instance side test case methods. I also like that the capitalized first letter nicely highlights in the test code the difference between the shared resources and the private stuff in case instance variables. Obviously the resources need to be torn down in the class side #tearDown method. It is usually also desirable to nil out the variables as well so that the class doesn’t hand on to garbage. The nilling out could be done automatically with a bit of meta-programming, but since it’s often also important to finalize/close/release the resources properly as well, I figured it’s better to force the user to deal with that, rather than facilitate potentially serious leaks with more automated magic. It’s probably also a good idea to call super implementations of the setUp/tearDown methods so that case hierarchies work well.

Here’s a quick summary of how to create a test case with resources:

1. Make the test class a subclass of ResourcefulTestCase:

```
XProgramming.SUnit defineClass: #MyTest
	superclass: #{XProgramming.SUnit.ResourcefulTestCase}
	indexedType: #none
	private: false
	instanceVariableNames: ''
	classInstanceVariableNames: ''
	imports: ''
	category: 'My Tests'
```

2. Add class variables for the shared resources.

3. Add class side setUp method and initialize the test resources there

```
MyTest class>>setUp

	A := Object new.
	Client := HttpClient new connect: 'testserver'
```

4. Add class side tearDown method releasing the resources

```
MyTest class>>setUp

	A := nil.
	Client close.
	Client := nil.
```

And that’s it. All nicely and intuitively packaged in a single class. Now you can simply use the resources in your test methods:

```
MyTest>>testResources

	self assert: A class == Object.
	self assert: (Client get: 'index.html') isSuccess
```

The supporting code is published in the public repository in a package called SUnit-SimpleResources