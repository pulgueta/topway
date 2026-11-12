import Testing
import TopwayCore

struct PKCETests {
    @Test("The challenge is the S256 value of RFC 7636, appendix B")
    func knownChallenge() {
        let pkce = PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")

        #expect(pkce.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test("A random verifier has 43 URL-safe characters, and each one is different")
    func randomVerifier() {
        let allowed = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let first = PKCE.random()
        let second = PKCE.random()

        #expect(first.verifier.count == 43)
        #expect(first.verifier.allSatisfy(allowed.contains))
        #expect(first.challenge.allSatisfy(allowed.contains))
        #expect(first.verifier != second.verifier)
    }

    @Test("A random state is URL safe, and each one is different")
    func randomState() {
        let first = AuthorizationRequest.randomState()

        #expect(first.count == 43)
        #expect(!first.contains("+") && !first.contains("/") && !first.contains("="))
        #expect(first != AuthorizationRequest.randomState())
    }
}
