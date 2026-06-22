import Testing
@testable import MRTracker

struct LinkLabelerTests {
    @Test func extractsSubdomain() {
        #expect(LinkLabeler.baseLabel(for: "https://planka.lala.ru/board/1") == "planka")
    }

    @Test func twoPartHostUsesFirst() {
        #expect(LinkLabeler.baseLabel(for: "https://lala.ru/x") == "lala")
    }

    @Test func worksWithoutScheme() {
        #expect(LinkLabeler.baseLabel(for: "planka.lala.ru/x") == "planka")
    }

    @Test func localhost() {
        #expect(LinkLabeler.baseLabel(for: "http://localhost:3000/x") == "localhost")
    }

    @Test func dedupNumbersDuplicates() {
        let labels = LinkLabeler.labels(for: [
            "https://planka.lala.ru/1",
            "https://planka.lala.ru/2",
            "https://jira.lala.ru/3",
            "https://planka.lala.ru/4"
        ])
        #expect(labels == ["planka", "planka2", "jira", "planka3"])
    }

    @Test func singleStaysUnnumbered() {
        #expect(LinkLabeler.labels(for: ["https://planka.lala.ru/1"]) == ["planka"])
    }
}
