import Testing

@testable import Metrics

@Suite
struct `Request metrics policy boundaries` {
    @Test
    func `status codes at the severity boundaries`() {
        let policy = Metrics.Request.Policy(detectStaticFiles: false)

        #expect(policy.event(for: request(statusCode: 0)).severity == .info)
        #expect(policy.event(for: request(statusCode: 303)).severity == .info)
        #expect(policy.event(for: request(statusCode: 305)).severity == .info)
        #expect(policy.event(for: request(statusCode: 399)).severity == .info)
        #expect(policy.event(for: request(statusCode: 400)).severity == .warning)
        #expect(policy.event(for: request(statusCode: 499)).severity == .warning)
        #expect(policy.event(for: request(statusCode: 500)).severity == .error)
        #expect(policy.event(for: request(statusCode: 999)).severity == .error)
    }

    @Test
    func `a static path with a failing status is not a static file`() {
        let event = Metrics.Request.Policy().event(for: request(path: "/assets/site.css", statusCode: 404))

        #expect(!event.isStaticFile)
        #expect(event.severity == .warning)
    }

    @Test
    func `static file detection can be switched off`() {
        let event = Metrics.Request.Policy(detectStaticFiles: false)
            .event(for: request(path: "/assets/logo.png", statusCode: 200))

        #expect(!event.isStaticFile)
        #expect(event.severity == .info)
    }

    @Test
    func `a static content type suffices without a file extension`() {
        let event = Metrics.Request.Policy()
            .event(for: request(path: "/avatar", statusCode: 200, contentType: "image/webp"))

        #expect(event.isStaticFile)
        #expect(event.severity == .trace)
    }

    @Test
    func `an empty path with no content type is not a static file`() {
        let event = Metrics.Request.Policy().event(for: request(path: "", statusCode: 200))

        #expect(!event.isStaticFile)
        #expect(event.path == "")
        #expect(event.requestID == nil)
    }

    private func request(
        path: String = "/",
        statusCode: Int,
        contentType: String? = nil
    ) -> Metrics.Request {
        Metrics.Request(
            method: "GET",
            path: path,
            statusCode: statusCode,
            duration: .zero,
            contentType: contentType
        )
    }
}
