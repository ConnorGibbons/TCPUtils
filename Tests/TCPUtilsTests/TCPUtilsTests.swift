import XCTest
import Foundation
import Network
@testable import TCPUtils


let ONE_SECOND_IN_NANOSECONDS: UInt64 = 1_000_000_000

class BoolWrapper: @unchecked Sendable{
    
    var value: Bool = false
    
    init(value: Bool) {
        self.value = value
    }
    
    func toggle() {
        value.toggle()
    }
    
    func getValue() -> Bool {
        return value
    }
}


final class TCPUtilsTests: XCTestCase {
    
    func testEstablishTCPConnection() {
        let sem = DispatchSemaphore(value: 0)
        let connectionEstablished = BoolWrapper(value: false)
        let connection = try! TCPConnection(hostname:"tcpbin.com", port: 4242, stateUpdateHandler: { newState in
            if(newState == .ready) {
                connectionEstablished.toggle()
                sem.signal()
            }
        })
        connection.startConnection()
        Task.init {
            try! await Task.sleep(nanoseconds: ONE_SECOND_IN_NANOSECONDS)
            XCTAssertTrue(connectionEstablished.getValue())
        }
        sem.wait()
    }
    
    func testTCPConnectionSend() {
        let sem = DispatchSemaphore(value: 0)
        let connectionEstablished = BoolWrapper(value: false)
        
        let stateUpdateHandler: @Sendable (NWConnection.State) -> Void = { newState in
            if(newState == .ready) {
                connectionEstablished.toggle()
                sem.signal()
            }
        }
        
        let sendHandler: @Sendable (NWError?) -> Void = { error in
            XCTAssertNil(error)
            sem.signal()
        }
        
        let connection = try! TCPConnection(hostname: "tcpbin.com", port: 4242, sendHandler: sendHandler, stateUpdateHandler: stateUpdateHandler)
        Task.init {
            try! await Task.sleep(nanoseconds: ONE_SECOND_IN_NANOSECONDS)
            XCTAssertTrue(connectionEstablished.getValue())
        }
        connection.startConnection()
        sem.wait()
        try! connection.sendData("Meow meow...")
        try! connection.sendData("Freak Pay!!!!")
        sem.wait()
        sem.wait()
    }
    
    func testTCPConnectionReceive() {
        let sem = DispatchSemaphore(value: 0)
        
        let stateUpdateHandler: @Sendable (NWConnection.State) -> Void = { newState in
            if newState == .ready {
                print("Connection is ready.")
                sem.signal()
            }
            else {
                print("State updated to: \(newState)")
            }
        }
        
        let sendHandler: @Sendable (NWError?) -> Void = { error in
            XCTAssertNil(error, "Send failed with error: \(error!)")
            print("Send complete.")
            sem.signal()
        }
        
        let receiveHandler: @Sendable (Data) -> Void = { data in
            print("Received data: \(String(data: data, encoding: .utf8) ?? "Non-string data")")
            sem.signal()
        }
        
        let connection = try! TCPConnection(
            hostname: "tcpbin.com",
            port: 4242,
            sendHandler: sendHandler,
            receiveHandler: receiveHandler,
            stateUpdateHandler: stateUpdateHandler
        )
        
        
        connection.startConnection()
        let semResult = sem.wait(timeout: .now() + 5)
        XCTAssertEqual(semResult, .success)
        
        try! connection.sendData("Meow meow...\n")
        let semResult_send1 = sem.wait(timeout: .now() + 2)
        XCTAssertEqual(semResult_send1, .success)
        
        let semResult_receive1 = sem.wait(timeout: .now() + 5)
        XCTAssertEqual(semResult_receive1, .success)
        
        connection.closeConnection()
    }
    
    func testTCPServerAcceptsConnections() {
        let sem = DispatchSemaphore(value: 0)
        
        let receiveHandler: @Sendable (String, Data) -> Void = {
            print("\($0): \(String(data: $1, encoding: .utf8) ?? "Unreadable data")")
            sem.signal()
        }
        
        let newConnectionHandler: @Sendable (TCPConnection) -> Void = { newConnection in
            print("New connection: \(newConnection.connectionName)")
            sem.signal()
        }
        
        let server = try! TCPServer(port: 62965, actionOnReceive: receiveHandler, actionOnNewConnection: newConnectionHandler)
        server.startServer()
        
        let clientStateHandler: @Sendable (NWConnection.State) -> Void = { newState in
            print("New TCP Client State: \(newState)")
            if(newState == .ready) {
                sem.signal()
            }
            if(newState == .cancelled) {
                sem.signal()
            }
        }
        
        let client = try! TCPConnection(hostname: "localhost", port: 62965, stateUpdateHandler: clientStateHandler)
        client.startConnection()
        let connectionResult = sem.wait(timeout: DispatchTime.now() + 0.5)
        XCTAssertEqual(connectionResult, .success)
        
        let serverAcceptConnectionResult = sem.wait(timeout: DispatchTime.now() + 0.5)
        XCTAssertEqual(serverAcceptConnectionResult, .success)
        XCTAssertEqual(server.connectionCount, 1)
        
        try! client.sendData("Hello server :)\n")
        let messageReceivedResult = sem.wait(timeout: DispatchTime.now() + 0.5)
        XCTAssertEqual(messageReceivedResult, .success)
        
        client.closeConnection()
        server.stopServer()
    }
}
