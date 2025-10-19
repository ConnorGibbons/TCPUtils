# **TCPUtils**

### **Description**
**TCPUtils** contains tools for establishing and utilizing a TCP connection or creating a TCP server.

---

### **Use**

Importing **TCPUtils** allows you to utilize the `TCPConnection` and `TCPServer` classes.

---

#### **TCPConnection**

`TCPConnection` allows you to define a hostname and port to connect to.  
In addition, you can define handler functions for various events such as:

- Connection state changes  
- Data reception  

Beginning the connection is as simple as calling:

```swift
TCPConnection.startConnection()
```
---

#### **TCPServer**

TCPServer allows you to define a port number and a maximum number of connections.
You can define handler functions for events such as:
  - Receiving data
	-	A new connection being opened

TCPServer maintains an array of open TCPConnections internally and a dictionary mapping string identifiers to active connections.
Using a string identifier, you can send data through a particular connection using:
```swift
TCPServer.sendMessage(connection: "connection identifier", message: "message here :)")
```

---

### **Notes**

TCPUtils provides tools to make raw TCP connections with minimal overhead. This is useful if you're utilizing a simple protocol or implementing your own.
However, if you're using a widely used protocol like HTTP, I would reccomend using a library that abstracts away this layer, such as Apple's URLSession.

If you have any issues / suggestions, please email me: connor@ccgibbons.com


