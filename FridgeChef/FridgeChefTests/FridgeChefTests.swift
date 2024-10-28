//
//  FridgeChefTests.swift
//  FridgeChefTests
//
//  Created by Vickyhereiam on 2024/10/23.
//
import XCTest
import UserNotifications
@testable import FridgeChef

class NotificationTests: XCTestCase {

    func testScheduleExpirationNotification() {
        
        let mockNotificationCenter = MockNotificationCenter()
        let item = FoodItem(id: "1", name: "Milk", quantity: 1, unit: "瓶", status: .fridge, daysRemaining: 2, expirationDate: Date(), imageURL: nil)
       
        let fridgeView = FridgeView()
        fridgeView.scheduleExpirationNotification(for: item, notificationCenter: mockNotificationCenter)
        
        XCTAssertEqual(mockNotificationCenter.addCallCount, 1, "add() should be called once")
        XCTAssertNotNil(mockNotificationCenter.lastAddedRequest, "The notification request should be created")
        
        let request = mockNotificationCenter.lastAddedRequest
        XCTAssertEqual(request?.content.title, "Expiration Alert‼️")
        XCTAssertEqual(request?.content.body, "Milk is about to expire in 2 days!")
        XCTAssertEqual(request?.identifier, "1")
        
        if let trigger = request?.trigger as? UNTimeIntervalNotificationTrigger {
            XCTAssertEqual(trigger.timeInterval, 2 * 24 * 60 * 60, accuracy: 1.0)
        } else {
            XCTFail("Trigger is nil or not of expected type")
        }
    }
    
    func testScheduleNotificationWithInvalidTimeInterval() {
   
        let mockNotificationCenter = MockNotificationCenter()
        let item = FoodItem(id: "1", name: "Expired Milk", quantity: 1, unit: "瓶", status: .fridge, daysRemaining: 0, expirationDate: Date(), imageURL: nil)
        
        let fridgeView = FridgeView() 
        fridgeView.scheduleExpirationNotification(for: item, notificationCenter: mockNotificationCenter)
        
        XCTAssertEqual(mockNotificationCenter.addCallCount, 0, "add() should not be called for an expired item")
    }
}
