import Testing
@testable import MRTracker

struct MRURLParserTests {
    @Test func parsesSimpleMR() {
        let p = MRURLParser.parse("https://gitlab.host/group/project/-/merge_requests/42")
        #expect(p?.projectPath == "group/project")
        #expect(p?.encodedProjectPath == "group%2Fproject")
        #expect(p?.iid == 42)
        #expect(p?.baseURL == "https://gitlab.host")
    }

    @Test func parsesSubgroups() {
        let p = MRURLParser.parse("https://gitlab.host/group/sub/deep/project/-/merge_requests/7")
        #expect(p?.projectPath == "group/sub/deep/project")
        #expect(p?.encodedProjectPath == "group%2Fsub%2Fdeep%2Fproject")
        #expect(p?.iid == 7)
    }

    @Test func parsesTrailingPath() {
        let p = MRURLParser.parse("https://gitlab.host/g/p/-/merge_requests/15/diffs")
        #expect(p?.iid == 15)
        #expect(p?.projectPath == "g/p")
    }

    @Test func preservesSpecialChars() {
        let p = MRURLParser.parse("https://gitlab.host/my-group/my.project_x/-/merge_requests/1")
        #expect(p?.encodedProjectPath == "my-group%2Fmy.project_x")
    }

    @Test func handlesPort() {
        let p = MRURLParser.parse("http://localhost:8080/g/p/-/merge_requests/3")
        #expect(p?.baseURL == "http://localhost:8080")
        #expect(p?.iid == 3)
    }

    @Test func rejectsNonMR() {
        #expect(MRURLParser.parse("https://gitlab.host/group/project/-/issues/42") == nil)
        #expect(MRURLParser.parse("not a url at all") == nil)
        #expect(MRURLParser.parse("https://gitlab.host/group/project") == nil)
    }
}
