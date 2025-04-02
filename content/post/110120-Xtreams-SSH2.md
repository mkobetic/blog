---
title: Xtreams-SSH2
date: 2011-01-20
tags:
  - smalltalk
  - xtreams
  - ssh
---

(Republished from [Cincom Smalltalk Tech Tips](https://csttechtips.wordpress.com/2010/12/17/xtreams-ssh2/))

We are receiving some very encouraging feedback on Xtreams . There’s a fairly complete port to Squeak/Pharo, people are blogging about it, and discussing it on various forums. All that is very welcome and certainly helps reassuring [Willow](https://www.linkedin.com/in/willow-lucas-smith-5aa19121/) and myself that we might be onto something that’s worthwhile and keeps us motivated to continue.

At this stage of the game we feel that the core library is reasonably complete, we’re reasonably happy with the API and we’re venturing into experiments where we’d like to prove that the concepts and implementation are good and that the performance goals are achievable as well. Willow created a neat, very light-weight, yet rather complete IRC client over a weekend. My fascination with security protocols led me to attempt an implementation of SSH2 .

I chose SSH because I wanted to learn more about the protocol, and wanted to compare it with my previous experience implementing SSL (outside of the context of Xtreams). I also see it as a good target for validation of our performance goals. Secure protocols are naturally layered and that seems to be a rather good fit for an attempt to map that structure onto a stream stack with the socket connection at the bottom, various packet splitting/combining, encryption and hashing layers on top of it, all hopefully coming together into a very simple and transparent binary stream facade. If the abstractions and implementation is right, the stack must behave the same as a simple binary stream and it must not cost much in terms of performance.

So, I’ve been working on this in my spare time for about 2 months now. It was a bit more work than I expected, not because I’ve hit some particularly difficult obstacles, in fact I was making fairly steady progress throughout, I just didn’t really know what I was getting into. SSH is really quite a bit more than just a protocol. It’s a suite of protocols (some documented better than others) with an architectural framework that puts them together for a particular purpose: running a remote shell, executing remote commands, uploading/downloading files, etc. You can’t reasonably compare SSH to SSL as a whole, that would be comparing apples to oranges, or rather comparing apple to an apple pie. The part of SSH that is roughly comparable to SSL would be the bottom-level transport layer combined with the authentication layer running on top of it. That’s all nice and dandy and I was done with that part in a few weeks, but the problem is, you can’t really use it for anything practical. You could use it for a custom, smalltalk to smalltalk, secure communication channel, but you can’t interoperate with anything else out there.

What I wanted was to be able to upload/download a large file with Smalltalk on either the client or server end and be able to measure how long it takes compared to a native C client, like OpenSSH’s scp command. So, to get there I needed to also implement the connection layer , which provides the multiplexed multi-channel capabilities allowing independent data-flows over a single, shared, secure connection. Then I needed to figure out how the scp command uses those facilities to transport files over it, which involved a rather sparsely and incompletely documented SCP protocol and a good deal of trial and error experiments with OpenSSH.

So I’m glad to report that I’m finally seeing the light at the end of the (encrypted) tunnel. At this point I can execute an expression on a Smalltalk server via the ssh command. There isn’t any generic TCP server support built in, so the first half of the example code is just to establish a single TCP connection with a client:

```
| listener socket server |
"This is just to set up a TCP socket connection, nothing to do with SSH2"
listener := SocketAccessor
   family: SocketAccessor AF_INET
   type: SocketAccessor SOCK_STREAM.
listener soReuseaddr: true.
listener bindTo: (
   IPSocketAddress hostAddress: IPSocketAddress thisHost port: 2222).
[ socket := listener listenFor: 1; accept ] ensure: [ listener close ].

"Now we have a socket and can set up an SSH2 connection on it,
here playing the server side"
server := SSH2ServerConnection on: socket.

"This is just to have all SSH messages echoed to transcript"
server when: SSH2Announcement do: [ :m | Transcript cr; print: m ].

[  "Server normally doesn't do much beyond accepting the client handshake
   and then waiting for a disconnect. Everything is initiated by the client side
   and handled by background threads handling any established channels."
   server accept; waitForDisconnect
] ensure: [ server close. socket close ]
```

The client side interaction looks something like the following:

```sh
[mkobetic@latitude ~]$ ssh -p 2222 localhost 3 + 4
7
```

Not particularly impressive output so let me also add what this interaction logged into the Transcript (as requested in the example code). It describes the entire message exchange between the client and the server:

```
-> identification ['Xtreams_Initial_Development']
-> KEXINIT
<- identification ['OpenSSH_5.5']
<- KEXINIT
<- KEXDH_INIT
-> KEXDH_REPLY
-> NEWKEYS
<- NEWKEYS
<- SERVICE_REQUEST ssh-userauth
-> SERVICE_ACCEPT ssh-userauth
<- USERAUTH_REQUEST martin@ssh-connection none
-> USERAUTH_FAILURE #('publickey')
<- USERAUTH_REQUEST martin@ssh-connection publickey
   ssh-dss 5c:d1:c7:c8:27:48:8c:1a:fe:83:1d:7b:3c:09:49:6d no sig
-> USERAUTH_PK_OK
<- USERAUTH_REQUEST martin@ssh-connection publickey
   ssh-dss 5c:d1:c7:c8:27:48:8c:1a:fe:83:1d:7b:3c:09:49:6d with sig
-> USERAUTH_SUCCESS
<- CHANNEL_OPEN(0) session 2097152/32768
-> CHANNEL_OPEN_CONFIRMATION(0)(0) 2097152/32668
<- CHANNEL_REQUEST(0) !  env LANG -> en_US.utf8
<- CHANNEL_REQUEST(0) ?  exec 3 + 4
-> CHANNEL_SUCCESS(0)
-> CHANNEL_DATA(0)[2]
-> CHANNEL_EOF(0)
-> CHANNEL_CLOSE(0)
<- CHANNEL_CLOSE(0)
<- DISCONNECT 11 disconnected by user
-> DISCONNECT 11 BY_APPLICATION
```

And that is not all, it can also upload/download files or directories in either direction (server -> client, client -> server) or execute remote shell commands from smalltalk client on a remote OpenSSH server. Here’s an example of how to make a smalltalk client talk to an OpenSSH server. The example includes the code needed to read the default user keys from $HOME/.ssh directory and making the socket connection:

```
| home user keys socket client keys config |
"The bulk of this is loading up your personal keys from your $HOME/.ssh directory
as they are needed to successfully authenticate with the server"
home := '$(HOME)' asLogicalFileSpecification asFilename.
user := home tail.
keys := SSH2Keys new.
((home / '.ssh' filesMatching: 'id_*') reject: [ :fn |
   '*.pub' match: fn ]) do: [ :fn || pub pri |
      pri := fn asFilename readStream.
      pri := (
         [ CertificateFileReader new readFrom: pri
         ] ensure: [ pri close ]) any asKey.
      pub := (fn, '.pub') asFilename reading encoding: #ascii.
      (pub ending: $ ) -= 0.
      pub := [ Xtreams.SSH2HostKey readFrom: pub encodingBase64 ssh2Marshaling
         ] ensure: [ pub close ].
      pub := keys publicKeyFrom: pub.
      keys addPublic: pub private: pri ].

"Now we have the keys and can set up an SSH configuration to use them."
config := SSH2Configuration new keys: keys.
"Create a socket"
socket := SocketAccessor newTCPclientToHost: 'localhost' port: 22.
"Set up an SSH client connection on it.
client := SSH2ClientConnection on: socket.
client configuration: config.

"This is just so that all SSH messages are echoed into the Transcript"
client when: SSH2Announcement do: [ :m | Transcript cr; print: m ].
"client when: SSH2TransportMessage, SSH2ChannelSetupMessage, CHANNEL_CLOSE do: [ :m |
   Transcript cr; print: m ]."

[  "A client has to connect as particular user (using the preconfigured keys)
   and gets a channel service in response"
   service := client connect: user.

   "A channel service can provide an interactive session or a tunnel.
   You can ask for as many sessions, tunnels as you want, each will
   get its own channel multiplexed over the same SSH connection."
   session := service session.

   "Given a session you can execute a command, or upload/download
   a file or directory, etc..."
   "[ session exec: 'ls -l'.
   ] ensure: [ session close ].
   "[ [ session scpUploadFrom: 'ssh.im' to: '/dev/shm/' ] timeToRun
   ] ensure: [ session close ]
] ensure: [ client close. socket close ]
```
I also started playing with a “shell” session with a Smalltalk server, but rather than invoking or emulating bash, I wanted to run a simple read/eval/print loop in Smalltalk instead. Having that, one could use the ssh command to connect to a Smalltalk server securely and execute smalltalk expressions on it. It is basically working as is, except the Smalltalk side has to do at least basic level of terminal emulation. A simple CR returned from the server moves the cursor in the terminal down one line but doesn’t move it back to the left. That one would be easy, but it also seems that the default terminal setup expects the server to echo what is typed into the terminal (I couldn’t see what I was typing in my experiments). So I’ll need yet another piece, basic terminal emulation layer to make this work reasonably.

Performance is looking good as well. My primary test is uploading/downloading a reasonably large file using scp. Here’s a transcript of a terminal session uploading a file to both an OpenSSH server and a Smalltalk server:

```sh
[mkobetic@latitude 78]$ ll ssh.im
-rw-rw-r-- 1 mkobetic mkobetic 65M Dec 15 16:14 ssh.im
[mkobetic@latitude 78]$ scp ssh.im mkobetic@localhost:/dev/shm/
ssh.im                                 100%   64MB  32.1MB/s   00:02
[mkobetic@latitude 78]$ scp -P2222 ssh.im mkobetic@localhost:/dev/shm/
ssh.im                                 100%   64MB  21.4MB/s   00:03
```

And here is the same just transfering the file in the opposite direction, downloading it from the server:

```sh
[mkobetic@latitude 78]$ scp mkobetic@localhost:st/78/ssh.im /dev/shm
ssh.im                                 100%   64MB  32.1MB/s   00:02
[mkobetic@latitude 78]$ scp -P2222 mkobetic@localhost:ssh.im /dev/shm
ssh.im                                 100%   64MB  32.1MB/s   00:02
```

The commands with the -P2222 option are the ones running against Smalltalk server (2222 was the port where it listened). The upload is somewhat slower (a different data stream setup is used when sending a file and when receiving one), but the download speed is on par. There are several critical aspects that you need to keep in mind when you want an efficient implementation.

You can’t come even close to the bulk encryption and hashing speed with a pure smalltalk implementation (at least not with any of the smalltalks that are currently available as far as I know). Just the overhead of indexed variable access in ByteArrays will kill you (last time I looked accessing an indexed instance variable in VisualWorks was about four times slower than accessing a named instance variable). Moreover the other side is most likely calling optimized (possibly pure assembler) implementations from libcrypto or some such. So don’t even try. That’s why we didn’t think twice about implementing the cryptographic streams in Xtreams by calling libcrypto (from OpenSSL) to do the heavy lifting. Arguably that’s cheating, but I don’t think it’s particularly different from calling other low level primitives in the VM. A symmetric cipher (e.g. AES, RC4,…) or a secure hash (SHA, MD5,..) is a specialized bit-twiddling algorithm. Implementing it in smalltalk is educational and fun, but they really aren’t practical in many contexts. There are optimized implementations of all of them available on any OS these days, so I think it’s only reasonable to take advantage of that. Moreover, many application contexts require cryptographic algorithm implementations to be certified (e.g. FIPS 140-2), other applications may require hardware accelerated implementations, so leaving it to external facilities is the most pragmatic choice.

Even if you do decide to “outsource” bulk encryption and hashing, you need to do it the right way. Calls outside of Smalltalk are expensive, so you want to make them worth it. You cannot call out for every byte or two of data. You must send entire buffers to be processed. Xtreams employs 32K buffers by default. That seems to be sufficiently large to offset any costs of calling C (at least in VW).

You must avoid expensive garbage. However note the emphasis on expensive. You don’t need to skimp on every little object. The new space scavenging scheme can chew through megabytes of transient objects in no time. The expensive objects are the ones that make it to the old space but don’t survive too long after that. One particular type of objects that tends to fall into that category are the large ByteArrays used as buffers. It doesn’t take too many of those allocated in rapid sequence to overflow the new space, causing many of them tenuring into the old space. Since they are large they will quickly kick the incremental garbage collector into action. Suddenly you’re spending more time garbage collecting than doing the real work. So it’s critical to reuse buffer objects. If you can’t ensure that within your own code, Xtreams come with a built in RecyclingCenter, which serves as an overflow staging area for buffers, so that they can be picked up and reused, when the application is chewing through a lot of them.

And that’s it, that’s what I believe are the essential ingredients needed to make Xtreams able to measure up to plain C. And it seems that the results confirm that. So, where to go from here? I still have a few implementation issues listed in the Xtreams-SSH2 package comment . I’d like to add the necessary bit of terminal emulation to make the ssh shell session with Smalltalk server possible. I may add TCP tunneling support, just for completeness, we’ll see. I definitely want to experiment with different approaches for implementing the protocol state machine. I don’t like what I have in Xtreams-SSH2 now (and what’s in the SSL implementation either). I’m still searching for an approach that I’ll like and once I figure it out I’ll might do Xtreams-TLS as well.

Regarding the future of Xtreams-SSH2 package, I’m not sure how useful it can be in practice (assuming all is done and polished). Do you think you’d use it for scp upload/download directly to/from Smalltalk? Would you use a secure login into a smalltalk server ? I don’t think there’s much point in building yet another general purpose SSH server/client, OpenSSH already does that job rather well. Where I think it might be interesting are smalltalk specific projects and applications. For example SSH has this notion of “subsystems” and you can define your own. The only one I know of currently is the sftp subsystem. But the sky is the limit in terms of coming up with new ones. Anyway, if you have ideas for useful applications of a native smalltalk SSH implementation, let me know.

I might write a few more posts on particular implementation details, either from the point of view of how to solve particular problem using Xtreams, or just as an educational bit about SSH in general. If there’s something about this project that interests you, let me know. I should add, that should you feel particularly bored and want to try this out, the package is available in Cincom Public Repository . It should work immediately in any sufficiently recent release of VisualWorks. The code should be fairly well portable to Squeak/Pharo, but it depends on Xtreams-Xtras that weren’t ported yet. I tried to contain the VisualWorks specific bits in the SSH2Keys class which encapsulates the use of RSA/DSA keys and algorithms and currently relies on the VisualWorks Security library. I hope to get around to retargeting it onto the EVP primitives in libcrypto, which would make it the same sort of deal as Xtreams-Xtras (possibly eventually merged into it as well).
