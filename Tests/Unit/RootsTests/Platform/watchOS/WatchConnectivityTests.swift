import XCTest
import WatchConnectivity
@testable import Roots

#if os(watchOS)
class WatchConnectivityTests: XCTestCase {
    
    func testWatchConnectivitySupported() {
        XCTAssertTrue(WCSession.isSupported(), "Watch connectivity should be supported on watchOS")
    }
    
    func testWatchSessionActivation() {
        guard WCSession.isSupported() else {
            XCTFail("WCSession not supported")
            return
        }
        
        let session = WCSession.default
        XCTAssertNotNil(session, "Default session should exist")
    }
}
#endif
