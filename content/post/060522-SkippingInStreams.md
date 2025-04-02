---
title: Skipping in non-positionable streams
date: 2006-05-22
tags:
  - smalltalk
---

(Republished from [Cincom Smalltalk Tech Tips](https://csttechtips.wordpress.com/))

The latest version of the ComputingStreams in the public repository adds two new stream classes, CachedReadStream and CachedWriteStream. I'm not proud of the well worn, "cached", name and welcome any suggestions, but that's what it is for now. These streams are the first step in my (hopefully) final battle with stream positioning. If you've ever used streams in anger, you'll probably agree that many problems require yanking the stream position back and forth frantically. That of course clashes quite badly with the fact that some streams are inherently non-positionable.


## Streams and Positioning

The canonical example of non-positionable stream in my world is socket stream. Once you write something into it, you can forget about  going back and rewriting that length prefix on that message that you have just finished marshaling, because by that time the prefix may well already be at the receiving side. That's an obvious one, but as years of working with various kinds of streams go by you'll find out that even though most streams in VisualWorks subclass from PositionableStream, many are not or, what's worse, are only partially ... sometimes. For example even the socket streams, as all buffered external streams, do support positioning API and if you try, you'll find out that you are able to skip and peek ahead if you don't try to go too far back. So you're all happy that your little algorithm works with all kinds of streams until the point when your deployed algorithm happens to peek over the buffer boundary and blows up unable to skip back. Or how about this bonus question, is write stream on a file positionable or not ? And how about read-write stream on a file ? OK, you might think, external streams are just messy, but internal streams should be clean, right. Hm, so what is the result of this one ?

```
(ByteArray new withEncoding: #utf8) readWriteStream
	lineEndCRLF;
	nextPutAll: 'abc';
	cr;
	nextPutAll: 'def';
	position: 5;
	next
```

I guess the #lineEndCRLF gives it away, but often with a multi-byte encoding like UTF-8 where individual characters may take anywhere from 1 to 6 bytes, your chances to nail the position you want to hit aren't that great. Now, to be fair it seems that historically the stream library just wasn't designed with "stacking" streams on top of each other in mind, so positioning a character stream in terms of the encoded bytes in the specific case of EncodedStream isn't that big a deal in that context. However that just doesn't scale if you are dealing with streams potentially several levels of element translation deep. Imagine for example that you want to take your text, encode it in UTF-8, compress it, encrypt it and append a signature. You really need to position in terms of the elements at the top, not the bottom. Or more precisely, the positioning argument to a message sent to a stream must be expressed in terms of the elements that are written into or read from that particular stream. Otherwise you're forced to make assumptions about the overall composition of streams and completely break the abstraction layers. Just imagine that you are deploying your text processing application somewhere in China and you need to substitute UTF-8 for some Chinese encoding, because UTF-8 is just too in-efficient for that particular language.

Moreover, I'll argue that absolute positions themselves are a wrong abstraction. Streams in the most general sense are infinite, they don't end, they don't start, they just have their current position. Messages like #position, #atEnd, #reset, #contents don't even make sense there. If you rely on these messages in your stream processing you're placing severe restrictions on the kind of streams that you can deal with. And don't think this is just "too abstract". Socket streams, media streams, etc, are very much like that. The algorithm encoding particular frame in the video stream shouldn't need any of those messages above. Similarly asking a socket stream if it's #atEnd is a nonsense as well. It cannot reliably answer false until the connection was properly closed and we can be sure that we've received everything that was sent by the other party. Until that point in time the correct answer to #atEnd is definitely not boolean.

So I hope I've convinced you now that absolute positioning and related messages like #atEnd should be avoided whenever possible. But since we still need to yank the current position of a stream around we obviously need to use at least some sort of relative positioning. That's what the #skip: message is for, as it allows positioning relative to the current position of the stream. Again, with element translation in mind it is important that even the relative positions are expressed in terms of the elements at the stream level to keep proper separation of abstractions. But #skip: definitely doesn't prevent (theoretically) infinite streams on either end.

This is where the CachedStreams come in. They sit on top of an arbitrary stream and support skipping regardless of the capabilities of the stream. The stream will never be asked to move back, only forward. Skipping is performed in terms of the elements that the stream deals with, so if you feed characters into the stream you skip in terms of characters, regardless of the characters being converted into bytes using UTF-8 by some stream below.

As you've probably guessed it's achieved by caching. The stream maintains a fixed size buffer that it uses to cache elements. Originally I've started implementing it as a single read-write stream, but it turned out that cached reads and writes have some conflicting requirements, so I ended up splitting it into a read and write streams. The reasons will hopefully become clearer after a more detailed description of each.


## Skipping in read streams.

Let's take the CachedReadStream first. The cache is implemented as a circular buffer used as a FIFO queue for the elements. It has a pointer to the current "top", i.e. pointing at the latest element read in from the underlying stream, and a "position" pointer to the current position within the buffer. Consequently the position can back off from the top one full length of the buffer, but not more. Initially the buffer is empty and only fills up as elements are read from the stream. Once it fills up the "oldest" elements will start "falling through" the bottom of the buffer as new elements are added at the top. Skipping forward is unlimited but the cache has to follow along to the target position leaving necessary number of previous elements behind.

The API is identical to other read streams with the crucial difference of #skip: (and consequently #peek) behavior being predictable and consistent regardless of the type of the underlying stream. This also motivated addition of message #previous, a counterpart of #next, but it's not clear to me how useful it is to read the elements in reverse order. I guess the time will tell how useful will this capability be in practice.

Another important (deliberate) difference is that this stream explicitly translates the EndOfStreamNotification into a hard IncompleteNextCountError. I believe that the whole deal with the notification and returning a nil as the result of #next at the end of the stream is a bad mistake, so this is an attempt to start moving away from this behavior. We'll see if I have to back down on this one. The name EndOfStream for the error would probably be better, however the IncompleteNextCountError has been used for a very similar purpose for a long time so I have doubts about introducing a new exception class for almost the same thing. We'll see.

This would be a good time to show an example but since the API is the same traditional stuff, the best I can offer is this snippet of test code.

```
| stream |
stream := (ByteArray new withEncoding: #utf8) readWriteStream.
stream nextPutAll: 'abcdefghijklmnopqrstuvw'.
stream reset.
stream := stream readCache: 5.
stream skip: 10.
stream next: 4.		" => 'klmn' "
stream skip: -5.	" that wouldn't work with bare encoded stream! "
stream next: 10.	" => 'jklmnopqrs' "
stream nextAvailable: 100.	" =>  'tuvw' "
stream next.		"raises and IncompleteNextCountError"
```

The implementation also pays special attention to the block based APIs based on #next:into:startingAt:, translating that to as few block based operation on the buffer and on the underlying stream as possible. This allows taking advantage of block based copying primitives and can push through larger quantities of data more efficiently. This is clearly an optimization, but the difference is significant enough in most non-trivial applications.


## Skipping in write streams.

The CachedWriteStream is similar in many respects but there are significant differences. Written elements are cached in the buffer and only written down into the underlying stream when they fall through the bottom. This is to allow skipping back and rewriting the contents of the buffer arbitrarily until it gets flushed, which is useful for generating things like length prefixed message formats and such. This is the primary difference between the write and read streams. With read streams the position of the underlying stream is attached to the top of the buffer, but with write streams it is attached to the bottom. Another difference is that skipping forward in a write stream is also limited by the top of the buffer, because that represents the absolute end of the write stream, there are no more elements beyond it.
The write stream also provides reading capability within the confines of the buffer, because it is safe and easy to do and can be useful with some types of algorithms. Note however, that the reading and writing operations share the same position pointer. So a #next moves the position the same way as #nextPut:. So, for example

```
(String new writeStream writeCache: 5)
	nextPutAll: 'abcdef';
	skip: -4;
	next: 2;
	nextPutAll: 'EF';
	contents 
```

yields 'abcdEF'. Otherwise the API is identical to other write streams. However it is important to note that when you're done with the write stream you have to #flush or #close the stream in order to get the buffered elements written into the underlying stream. That applies equally to both internal and external streams. Sending #close to all streams when you're finished with them is a good habit to grow anyway, that's the only way to have your algorithms work properly with both internal and external streams. Also some kinds of encodings (like base-64 for example) also need to be informed to flush at the end to terminate the encoding properly even when working in memory.

The write stream also pays special attention to the block based APIs based on #next:putAll:startingAt:, translating that to as few block calls as possible.


# Conclusions

From the 300ft view the cached streams look very much like the buffered streams in the library, the only difference being that the buffer is circular with the cached stream. That however is the crucial difference catering to different purpose. The buffered streams are meant to accumulate small reads and writes to minimize the expense of the system read-write calls. A circular buffer wouldn't work at all for this purpose. Conversely the discontinuous operation of these buffers is the cause of the socket stream blowing up on simple peek when it happens to cross the buffer boundary. You really need a continuous (circular) buffer to support reliable skipping. Different purpose needs different buffering strategy.

The cached streams should work well for any algorithm where you can predict maximum size of the step back that you're going to need. However that is not always a practical assumption. My favorite example for this is BER/DER encoding in ASN.1 where you have deeply nested trees of length prefixed encodings of pretty much arbitrary size. There's an idea I'd like to pursue in this regard inspired by the "marking" capability I noticed in the java.nio.Buffer class when I was looking at the stream hierarchy in J2SE. I envision being able to #mark the current position in the stream to inform it that it needs to start caching, and be able to #reset back to that position. However to be able to handle nested structures like BER encoding conveniently I think I'll need to maintain a stack of markers. Also since the buffer will need to to grow arbitrarily, I plan to use a paged buffer so that I can grow and shrink it efficiently. Anyway I'll see how that's going to pan out. It might make a nice topic for another post.

Any comments, suggestions, etc are appreciated.
