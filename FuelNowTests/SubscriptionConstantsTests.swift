import Foundation
import Testing
@testable import FuelNow

struct SubscriptionConstantsTests {
    @Test func plusYearlyProductIDMatchesBundleConvention() {
        #expect(SubscriptionConstants.plusYearlyProductID == "com.vibecoding.fuelnow.subscription.year")
        #expect(SubscriptionConstants.plusMonthlyProductID == "com.vibecoding.fuelnow.subscription.month")
        #expect(
            SubscriptionConstants.productIDs
                == [SubscriptionConstants.plusYearlyProductID, SubscriptionConstants.plusMonthlyProductID]
        )
    }
}
