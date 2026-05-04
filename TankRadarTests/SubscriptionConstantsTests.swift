import Foundation
import Testing

@testable import TankRadar

struct SubscriptionConstantsTests {
    @Test func plusYearlyProductIDMatchesBundleConvention() {
        #expect(SubscriptionConstants.plusYearlyProductID == "com.vibecoding.TankRadar.subscription.year")
        #expect(SubscriptionConstants.productIDs == [SubscriptionConstants.plusYearlyProductID])
    }
}
