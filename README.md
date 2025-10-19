**TCPUtils**

*Description*
TCPUtils contains tools for establishing & utilizing a TCP connection or creating a TCP server.

*Use*
Importing TCPUtils allows you to utilize the TCPConnection and TCPServer classes.

TCPConnection allows you to define a hostname and port to connect to. In addition, you can define handler functions for various events such as connection state changes, or data reception.
Beginning the connection is as simple as calling TCPConnection.startConnection().

TCPServer allows for defining a port number, and a maximum number of connections. You can define handler functions for events such as recieving data, or a new connection being opened.
TCPServer maintains an array of open TCPConnections internally, and a dictionary mapping string identifiers to active connections. You can utilize these identifiers to send data via TCPServer.sendMessage to a specific client.
Otherwise, you can broadcast data to all active clients using TCPServer.broadcastMessage.

*Notes*
TCPServer/TCPConnection provides raw TCP-based connections with minimal overhead. It's particularly useful if you're working with a simple protocol or making your own.
If you're looking to use a widely adopted protocol like HTTP, you should probably look into using existing libraries which will abstract away this layer, like Apple's URLSession.
