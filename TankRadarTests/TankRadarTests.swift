import Testing
@testable import TankRadar

@Test(arguments: [1, 2, 3])
func trivialMath(n: Int) {
    #expect(n + 0 == n)
}
