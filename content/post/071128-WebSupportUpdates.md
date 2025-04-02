---
title: WebSupport updates
date: 2007-11-28
tags:
  - smalltalk
---

(Republished from [Cincom Smalltalk Tech Tips](https://csttechtips.wordpress.com/2007/11/))

Our Seaside effort yields some useful byproducts including improvements to the, so far rather Spartan, WebSupport package. This package now provides HttpClient and HttpRequest extensions simplifying submission of HTML form data through HTTP POST method.

In general, form data can be submitted in a “url encoded” format in a simple, single-part HTTP request (content-type: application/x-www-form-urlencoded), or each data entry can be submitted as an individual part in a multipart HTTP request (content-type: multipart/form-data). Multipart messages are used when form data contains entries with relatively large values, for example when a form has external files attached to it for upload to the server. More information about HTML forms can be found at http://www.w3.org/TR/html401/interact/forms.html#h-17.13.

The default behavior of WebSupport extensions is to submit forms as simple requests. Form entries can be added individually using #addFormKey:value: message, or set at once using #formData: message which takes a collection of Associations. Note that #formData: replaces any previous form content. The following example

```
	stream := String new writeStream.
 	(HttpRequest post: 'http://localhost/xx/ValueOfFoo')
		addFormKey: 'foo' value: 'bar';
		addFormKey: 'file'  value: 'myFile';
		writeOn: stream.
	stream contents
```

yields this result:

```
POST /xx/ValueOfFoo HTTP/1.1
Host: localhost
Content-type: application/x-www-form-urlencoded
Content-length: 19

foo=bar&file=myFile'
```

An alternative way to post a form is through HttpClient, in this case the request gets automatically executed and the result is the response from the server.

```
	HttpClient new
		post: 'http://localhost/xx/ValueOfFoo' 
		formData: (
			Array
				with: 'foo' -> 'bar';
				with:'file' -> 'myFile').
```

To force the form to submit as a multipart message, send #beMultipart to the request at any point. Any previously added entries will be automatically converted to message parts. Note however that conversion of multipart messages back to simple messages is not supported, as it is not always possible without potentially losing information.

```
	stream := String new writeStream.
 	(HttpRequest post: 'http://localhost/xx/ValueOfFoo')
		beMultipart;
		addFormKey: 'foo' value: 'bar';
		addFormKey: 'file'  value: 'myFile';
		writeOn: stream.
	stream contents
```

and the result is

```
POST /xx/ValueOfFoo HTTP/1.1
Host: localhost
Content-type: multipart/form-data;boundary="=_vw0.98992842109405d_="
Content-length: 183

--=_vw0.98992842109405d_=
Content-disposition: form-data;name=foo

bar
--=_vw0.98992842109405d_=
Content-disposition: form-data;name=file

myFile
--=_vw0.98992842109405d_=--
```

File entries can be added using message #addFormKey:filename:source:. Adding a file entry automatically forces the message to become multipart to be able to capture both the entry key and the filename.

```
	stream := String new writeStream.
	(HttpRequest post: 'http://localhost/xx/ValueOfFoo')
		addFormKey: 'foo' value: 'bar';
		addFormKey: 'text'  filename: 'text.txt' source: 'some text' readStream;
		writeOn: stream.
	stream contents
```

```
POST /xx/ValueOfFoo HTTP/1.1
Host: localhost
Content-type: multipart/form-data;boundary="=_vw0.015112462460581d_="
Content-length: 247

--=_vw0.015112462460581d_=
Content-disposition: form-data;name=foo

bar
--=_vw0.015112462460581d_=
Content-type: text/plain;charset=utf_8
Content-disposition: form-data;name=text;filename=text.txt

some text
--=_vw0.015112462460581d_=--
```

Adding a file entry attempts to guess the appropriate Content-Type for that part from the filename extension. If it doesn’t succeed the content type is set to default, i.e application/octet-stream. File names with non ASCII character will be automatically encoded using UTF8 encoding. UTF8 will also be used for the file contents if the source is a character stream (as opposed to byte stream).

Adding an entry to a multipart message returns the newly created part. That allows to modify any of the default settings or to add new ones. Here’s an example changing the filename and file contents encoding to ISO8859-2:

```
	stream := String new writeStream.
	request := HttpRequest post: 'http://localhost/xx/ValueOfFoo'.
	part := request addFormKey: 'czech'
				filename: 'kůň.txt'
				source: 'Příli¨ ¸luťoučký kůň úpěl ďábelské ódy.' withCRs readStream.
	part headerCharset: #'iso-8859-2';
		charset: #'iso-8859-2'.
	request writeOn: stream.
	stream contents
```

```
POST /xx/ValueOfFoo HTTP/1.1
Host: localhost
Content-type: multipart/form-data;boundary="=_vw0.74617905623567d_="
Content-length: 228

--=_vw0.74617905623567d_=
Content-type: text/plain;charset=iso-8859-2
Content-disposition: form-data;name=czech;filename="=?iso-8859-2?B?a/nyLnR4dA==?="

Pøíli¹ ¾lu»ouèký kùò úpìl ïábelské ódy.
--=_vw0.74617905623567d_=--
```

There’s also an API to parse messages containing forms in any of the supported forms. Just send #formData to the HTTP message. The result is a collection of associations, the same form as the input to the #formData: message.

```
 	(HttpRequest post: 'http://localhost/xx/ValueOfFoo')
		addFormKey: 'foo' value: 'bar';
		addFormKey: 'file'  value: 'myFile';
		formData
```

```
OrderedCollection ('foo'->'bar' 'file'->'myFile')
```

File entry values will be entire message parts so that all the associated information can be accessed.

```
	request := (HttpRequest post: 'http://localhost/xx/ValueOfFoo')
		addFormKey: 'foo' value: 'bar';
		addFormKey: 'text'  filename: 'text.txt' source: 'some text' readStream;
		yourself.
	part := request formData last value.
	part contents
```

```
some text
```

If you’d like to give the new code a try just load it up from the public repository.