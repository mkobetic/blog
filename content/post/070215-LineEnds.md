---
title: No End of Line End Confusion
date: 2007-02-15
tags:
  - smalltalk
---

(Republished from [Cincom Smalltalk Tech Tips](https://csttechtips.wordpress.com/2007/02/))

It's quite interesting that even though it's now decades old we're still running into this fundamentally rather trivial problem. It is especially pronounced in heavilly cross-platform environments like VisualWorks. As soon as you have multiple environments, e.g. Windows and Linux and you move text files between the two, you're pretty much guaranteed to run into files with doubled or trippled line-ends in them sooner or later. Often you can see both line-end conventions mixed up in the same file. Even seasoned smalltalkers sometimes miss some part of the whole picture, making it often difficult to deal with the consequences. So the purpose of this article is to provide a complete picture of what's going on and how are we supposed to deal with that.


## What's going on ?

Here's a quick recapitulation. There are 3 line end conventions in common use: CR (MacOS), LF (Unix) and CRLF (Windows). CR and LF here refer to characters with ASCII code 13 and 10 respectively. This historical fact can have a profound effect on an environment with the ambition to have fully binary-portable images across platforms. Let's say we try to emulate the platform specific line end convetion, i.e. use characters CR and LF in String instances on Windows, and just LF on Unix, etc. This would make binary-portability pretty difficult. Whenever we would move an image from Windows to Unix and start it up we would need to convert all the existing String instances from the CRLF convention to LF convention, effectively changing character size of many Strings. While that might be somewhat manageable (we already do something like that for swiches between platforms with different endianness), but there are further implications. If Strings get shortened, the positions of Streams set up on top of them will suddenly be off as well. In fact any kind of "pointer" into the String will be potentially broken. That will be much harder to fix and if it's not, things will start breaking. Binary portability wouldn't really work. 

So the only other choice is to pick one convention and stick with it everywhere. Historically the choice has been CR. I don't know why, I assume that it might be because of certain affinity of the original Smalltalk-80 developers towards Macintosh platform back then. Ironically, we may eventually end up being the only environment keeping the CR convention as MacOS/X is moving Macs away from the CR convention to the LF convention of it's Unix based core. Nevertheless, the important point is that in Smalltalk line ends in String instances should *always* be marked with character CR only, no matter what platform it's running on. While character LF is a perfectly valid character and it's pretty easy to construct a String with that character in it, a String with LFs in it is usually a sign of some kind of anomally and you can be sure that some components of the vast Smalltalk library won't be able to cope with it. This is very important, so once again, remember, only CRs in your Strings ! This simplification has other advantages too, things like reading a line of text from a stream becomes simply "upTo: Character cr" anywhere.


## Tools of the trade.

OK, now that's settled, what about Strings that come from outside ? It's not a Smalltalk only world out there (not yet anyway) and the text files on your harddrive will usually use whatever is the native convention for a given platform. What to do with that ? The key point here is that these Strings are coming from "outside". They should to be converted to the Smalltalk convention (CR) as they are brought in. That's why Strings with LF characters in them are often a sign of failure to convert.

The most common method to bring a String in from outside is to use an ExternalStream. And indeed if you take a closer look at those, you'll see that they have a configurable 'lineEndConvention'. Setting an ExternalStream to #lineEndCRLF means that if you are using it to read e.g. a file, it will automatically convert byte sequence #[13 10] into a single character CR. When writing into such stream, it will automatically produce byte sequence #[13 10] whenever it is given character CR. Note that it will write #[10] if you give it character LF instead and similarly it will give you an LF when reading if it encounters a standalone byte 10, i.e. one that is not preceded by 13. This is all assuming the stream is in text mode which is the default mode. If the stream is set to binary mode, it will pass the byte Integers through as they are, without any conversions. But you'll be getting ByteArrays out of the stream, not Strings in that case. The last thing that the streams will do for you automatically is set a default line end convention based on the platform that the image is running on at the moment when the stream is created. So if you create an external stream on Linux, it will be set to lineEndCR. On Windows it will be set to lineEndCRLF, etc.

There's another kind of streams that provide these capabilities, the EncodedStreams. Primary function of these is to convert bytes to characters according to a specified 'character encoding'. Character encoding is an even bigger can of worms, but for the purpose of this discussion let's just focus on the fact that EncodedStreams provide line end conversion the same way as external streams. In fact you can set an external stream to binary mode, wrap an EncodedStream around it and you should get the same results as with the external stream in text mode. This kind of setup will be handy in cases where you need to deal with character encodings that aren't supported by the external streams. There are in fact only very few of those that are supported by external streams: ISO8859_1, MSCP1252 for older Windows versions, and few more obscure encodings. For anything else (e.g. UTF-8) you will need to use an EncodedStream. So it is actually quite important that the EncodedStream is polymorphic with ExternalStreams.


## When Tools need a hands.
	
So far so good. We now know the tools that are available in the Base image for dealing with line-end conversions. The automatic configuration for native platform convention usually works out just fine when you're dealing with a single platform. But what if you're accessing an NFS mounted Linux file system from Windows ? These are the cases where you may need to intervene and set the line end convention appropriately yourself. There's also a "pseudo" convention #lineEndAuto which makes the stream do a quick scan of an initial portion of the file to determine which lineEndConvention to use based on the actual contents. This however may not be feasible on some types of external streams, e.g. socket streams.

Yet another alternative is instead of insisting on a specific convention for entire stream, we could simply convert any convention to CRs as they come in. This is especially nice when you want to cleanup a text with multiple conventions mixed in it. And this is actually doable without any pre-scanning and therefore could work on any kind of stream, even ones that cannot be peeked and positioned, like socket streams. This functionality isn't available in the Base image though, so I can plug here my little AutoLineEndStream which does exactly that. It can be found in the ComputingStreams package in the public repository. With it the following expression will answer true:

```
(AutoLineEndStream wrap: #[10 13 10 10 13 13] asString readStream
) contents = '\\\\\' withCRs
```

Note that this stream wraps a character stream, i.e. a stream that provides characters, e.g. an internal character stream or an external or encoded stream in text mode. The reason for this is complexity of character encodings. Even characters CR and LF need to be encoded when they are converted to/from bytes, and the encoding isn't always just 13 or 10. A CR can be #[13 00] or #[00 13] in UTF-16 encoding depending on the endianness and it can be even worse with other encoding. In general case it is basically impossible to pick out CR and LF out of an encoded text without decoding the other characters as well. So making AutoLineEndStream work with bytes would force it deep into the character encoding problems. It makes it much simpler to leave this domain to EncodedStreams and operate on characters instead, suddenly its task becomes trivial. So if you need to read an external file simply keep the stream (external or encoded) in text mode, set it to #lineEndTransparent which means don't do any conversion, i.e. each byte 13 will yield a CR and each byte 10 will yield an LF. Then you can wrap that in AutoLineEndStream and you should be set. Here's the corresponding code:

```
stream := 'messed up file.txt' asFilename readStream
stream lineEndTransparent.
stream := AutoLineEndStream wrap: stream.
```

Note that #lineEndTransparent is actually equivalent to #lineEndCR, just named differently to emphasize the effective transparency of this mode, and in this case definitely expresses the intent better.

I should also mention that the stream will perform the same conversion on writing, so if you write CR and then LF into the stream, it will forward only CR into the underlying stream. So if you happen to have a String with mixed up line ends in memory, simply writing it through an AutoLineEndStream should straighten that ou as well. So the following expression will be true as well:

```
((AutoLineEndStream wrap: String new writeStream)
	nextPutAll: #[10 13 10 10 13 13] asString;
	contents) = '\\\\\' withCRs
```

That's about all I can think of that is relevant to this topic. I believe that the problem isn't particularly difficult to deal with once you have a good understanding what is going on and what should be happening. I hope this article will help with that. Thanks for reading this far and if you have any corrections, suggestions, ideas, I'll be watching the comments eagerly.