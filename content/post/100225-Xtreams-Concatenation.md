---
title: Concatenating Streams
date: 2010-02-25
tags:
  - smalltalk
  - xtreams
---

(Republished from [Cincom Smalltalk Tech Tips](https://csttechtips.wordpress.com/2010/02/))

Did you ever run into a situation where you had a stream and some previously written chunk of code that could process the stream almost as is, if only the stream included few additional bytes in the beginning? Usually, I ended up just biting my lip and fetching the full content of the stream, prepending the missing bits and then setting up an internal stream on top of the collection. That's assuming it was feasible to load the entire stream into memory. Wouldn't it be lovely if I could simply prepend a stream in front of another stream and make the two look like one ? Let's give it a try.

One of the things I think we did get right with Xtreams is that it's xtremely easy to create full featured subclasses of ReadStream and WriteStream. In case of ReadStream the only required methods to implement are *contentsSpecies* and *read:into:at:*. That will give you a complete (non-positionable) stream. So let's make a *CompositeReadStream* that adds following inst vars:

```
source2 <ReadStream> second source
active <ReadStream> the currently active source
```

This stream should not be created with just *on:*, so let's declare that #shouldNotImplement and add *on:and:* instead:

```
on: aSource and: aSource2

	active := source := aSource.
	source2 := aSource2
```

With that in place it would be a mortal sin to not add ReadStream>>,

```
, aReadStream

	"Return a read stream that combines self and @aReadStream into a single stream.
	""
		((1 to: 5) reading, (6 to: 10) reading) rest
	"
	^CompositeReadStream on: self and: aReadStream
```

The sample in the comment above shows how it's intended to be used. Obviously we want the composite to produce the combined sequence of the elements from both sources. To get that we just need to implement *read:into:at:*

```
read: anInteger into: aSequenceableCollection at: startIndex

	| count |
	count := 0.
	[	^active read: anInteger into: aSequenceableCollection at: startIndex
	] on: Incomplete do: [ :ex |
		count := ex count.
		active == source ifFalse: [ ex pass ].

		active := source2 ].
	"avoid making the recursive call in the handler"
	^[	self read: anInteger - count into: aSequenceableCollection at: startIndex + count
	] on: Incomplete do: [ :ex |
		(Incomplete on: aSequenceableCollection count: count + ex count at: startIndex) raise ]
```

The idea is simple, we start reading from source, when we run out of source we switch to source2.

To satisfy all implementation requirements we also need *contentsSpecies*, we'll follow the species of the underlying source stream:

```
contentsSpecies
	^source contentsSpecies
```

And that's it. We can do something very similar for WriteStreams, although note that it only makes sense to concatenate streams of limited growth, e.g.:

```
| stream |
stream := (String new writing limiting: 1), (String new writing limiting: 6).
stream := (String new writing limiting: 5), stream.
stream write: 'Hello World!'; close; terminal
```

yielding #('Hello' (' ' 'World!')). If the first write stream grows without restrictions, then you'll keep writing into that one and never into the second one.

Now this was too easy, let's try something more xtreme. If we could make the composite stream add additional sub-streams on demand, we could use it for example to cut up arbitrary sentence into words. One way to achieve that is the having the second stream in the composite be something that can turn itself into another composite with itself in the second position again. As soon as the first stream fills up we need to trigger the transformation of this stream *prototype* in the second position into the same kind of composite as the one we started with. This kind of setup can accommodate arbitrarily long input on demand.

Let's call this prototype stream a *ProtoWriteStream*. Obviously the prescription how to turn it into a real stream is a block. For transparency let's trigger the transformation with any write related message send. Here's the corresponding code for ProtoWriteStream as a direct subclass of WriteStream.

```
write: anInteger from: aSequenceableCollection at: startIndex

	self become: destination value.
	^self write: anInteger from: aSequenceableCollection at: startIndex
```


```
contentsSpecies

	self become: destination value.
	^self contentsSpecies
```

We're re-using the destination slot to hold the transformation block, that way the on: creation method can be reused 
as well. To make it easier to create stream prototypes, let's add BlockClosure>>*writingPrototype* as well.

```
writingPrototype

	^Xtreams.ProtoWriteStream on: self
```

Additionally we need to override *close* and *flush* to be noops and we can accomplish the stated task as follows.

```
| prototype stream words |
words := OrderedCollection new.
prototype :=

	[	((words add: String new) writing ending: Character space)
		, prototype writingPrototype ].
stream := prototype value.
stream write: 'the quick brown fox jumps over the lazy dog'; close.
words
```

Similarly we can play the same game with read streams. Let's try to re-compose the words into a single stream.

```
| prototype stream  words |	
words := ('the quick brown fox jumps over the lazy dog' tokensBasedOn: Character space) reading.
prototype := [ words get reading, prototype readingPrototype ].
stream := prototype value.
stream rest
```


Obviously we could simply create all streams and concatenate them at once

```
(('the quick brown fox jumps over the lazy dog' tokensBasedOn: Character space)
	inject: '' reading into: [ :all :word | all, word reading ]
) rest
```

However the prototype based solution has the advantage of creating the sub-streams lazily, so if you don't need to consume the whole input, you don't waste the extra effort on the part that you'll just throw away.

If you want to play with these concepts, the concatenation support is now part of Xtreams-Xtras. The *CompositeReadStream* is even positionable if all its components are positionable as well. But I'm less confident about that part and haven't even implemented it for write streams yet. The *proto streams* are available in a new package Xtreams-Xperiments we've started. You'll get it automatically if you load the whole XtreamsDevelopment bundle.
