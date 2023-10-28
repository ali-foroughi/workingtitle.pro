---
title: "What's the difference between SSL and TLS?"
date: 2020-06-23
draft: false
---

SSL/TLS is a protocol for encrypting the communications between server and client. Netscape developed the first version of SSL in 1995 never released to the public because of major security flaws.

The first version that was used by the general public was SSL 2.0 which was released in 1995 via RFC 6176. However in the following year, the protocol received a complete redesign and SSL version 3.0 was released in 1996.

TLS or Transport Layer Security is just an updated version of SSL. So you could think of TLS as SSL 4.0. Because of some convoluted reasons however, a name change for the protocol occurred. Today when we say “SSL” we’re actually refereeing to TLS because the actual SSL protocol has long been deprecated. Hopefully no servers today are using the older versions of SSL.

The latest version of TLS is 1.3. Version 1.0 and 1.1 are officially deprecated as of 2020, so it’s absolutely necessary for any servers that are using these protocols to immediately update to version 1.2 or 1.3.

## But how does it work?

For encrypting the data between the client and server, TLS uses a mechanism called “handshake”. During a TLS handshake a number of actions need to occur in order to establish a secure connection between the server and the client:

<ul>
<li>Pick the version of TLS used by the client and server ( 1.2 , 1.3 etc)</li>
<li>ecide on which ciphers to use</li>
<li>Verify the authenticity of the server via the SSL certificate and and public key (we’ll look at this later)</li>
<li>And finally, create session keys or symmetric encryption after successfully completing the handshake</li>
</ul>

During the TLS handshake, the server and client need to exchange variety of different information in order to set up a secure connection.

RSA and Elliptic Curve are two of the most notable algorithms used for the client and server to exchange keys during the handshake. In this example we’re going to take a look at the most widely used algorithm: RSA

## How a TLS connection works

<ol>
<li><b>Client hello message:</b> The client starts the process by sending a “hello” message to the server. This message usually contains the cipher suites and the TLS version which the client wants to use, and a string of random bytes.</li>

<li><b>Server hello message:</b> The server replies to this message by sending the SSL certificate to the client (the public key). Along with this message, the server sends cipher suites and it’s own string of random characters.</li>

<li><b>Authentication:</b> The client now has to verify the authenticity of the SSL certificate it received from the server by checking it against the data provided by the Certificate Authority (e.g GoDaddy, Comodo, Digicert, etc). This is done so by using the Certificate Authority root cert that’s usually embedded in most known programs and browsers. This step is essential so we can make sure we’re talking to the correct server and not some malicious server trying to lure us.</li>

<li><b>Client response:</b> After authentication is complete, the client generates another set of random characters called the “premaster key”, encrypts it via the public key it received from the server and then sends it to the server. It’s important to note only the server can decrypt this message, because only the server has the required private key.</li>

<li><b>Session key creation:</b> The client and server have 3 keys: the client random, the server random and the premaster key. Using these 3 string of bytes, both client and server create a session key. They both create a “finished” message, sign it with the new session key and send it over. Both client and server can now confirm they have the same session key.</li>

<li><b>TLS connection established:</b> We have established a secure connection. The client and server will now continue to communicate and encrypt the data via the session key.</li>
</ol>

## Conclusion

So this is roughly the process that happens when you try to connect to a server or webpage that’s using SSL/TLS. So far that the technology allows, this is the best way we can secure connections between client and server.

It would take a normal computer 3 trillion years to break a 2048-bit RSA key. So it’s safe to say it’s pretty secure as of now. But with the rise of quantum computing that we’re seeing, maybe in 10-20 years time, this will not be such a safe method of encryption. We’ll have to come up with new ways! 