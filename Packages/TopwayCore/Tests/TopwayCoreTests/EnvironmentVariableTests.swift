import Testing
import TopwayCore

struct EnvironmentVariableTests {
    @Test("A plain value is written as NAME=value")
    func plainValue() {
        let variable = EnvironmentVariable(name: "PORT", value: "8080")

        #expect(variable.dotenvLine == "PORT=8080")
    }

    @Test("A value with a line break stays on one line, in double quotation marks")
    func lineBreak() {
        let variable = EnvironmentVariable(name: "KEY", value: "one\ntwo\r\nthree")

        #expect(variable.dotenvLine == #"KEY="one\ntwo\r\nthree""#)
    }

    @Test("A value with a double quotation mark is quoted, and the mark is escaped")
    func quotationMark() {
        let variable = EnvironmentVariable(name: "JSON", value: #"{"a":1}"#)

        #expect(variable.dotenvLine == #"JSON="{\"a\":1}""#)
    }

    @Test("A backslash in a quoted value is escaped, so it is not read as an escape")
    func backslashInQuotedValue() {
        let variable = EnvironmentVariable(name: "PATTERN", value: "a\\n\nb")

        #expect(variable.dotenvLine == #"PATTERN="a\\n\nb""#)
    }

    @Test("A backslash in a plain value does not change")
    func backslashInPlainValue() {
        let variable = EnvironmentVariable(name: "DIR", value: #"C:\temp"#)

        #expect(variable.dotenvLine == #"DIR=C:\temp"#)
    }
}
