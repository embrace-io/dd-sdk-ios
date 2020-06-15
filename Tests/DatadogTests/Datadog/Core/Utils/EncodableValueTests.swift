/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import Datadog

class EncodableValueTests: XCTestCase {
    func testItEncodesDifferentEncodableValues() throws {
        let encoder = JSONEncoder()

        XCTAssertEqual(
            try encoder.encode(EncodableValue("string")).utf8String,
            #""string""#
        )
        XCTAssertEqual(
            try encoder.encode(EncodableValue(123)).utf8String,
            #"123"#
        )
        XCTAssertEqual(
            try encoder.encode(EncodableValue(["a", "b", "c"])).utf8String,
            #"["a","b","c"]"#
        )
        XCTAssertEqual(
            try encoder.encode(EncodableValue(URL(string: "https://example.com/image.png")!)).utf8String,
            #""https:\/\/example.com\/image.png""#
        )
        struct Foo: Encodable {
            let bar = "bar_"
            let bizz = "bizz_"
        }
        XCTAssertEqual(
            try encoder.encode(EncodableValue(Foo())).utf8String,
            #"{"bar":"bar_","bizz":"bizz_"}"#
        )
    }
}

class JSONStringEncodableValueTests: XCTestCase {
    func testItEncodesDifferentEncodableValuesAsString() throws {
        let encoder = JSONEncoder()

        XCTAssertEqual(
            try encoder.encode(JSONStringEncodableValue("string", encodedUsing: JSONEncoder())).utf8String,
            #""string""#
        )
        XCTAssertEqual(
            try encoder.encode(JSONStringEncodableValue(123, encodedUsing: JSONEncoder())).utf8String,
            #""123""#
        )
        XCTAssertEqual(
            try encoder.encode(JSONStringEncodableValue(["a", "b", "c"], encodedUsing: JSONEncoder())).utf8String,
            #""[\"a\",\"b\",\"c\"]""#
        )
        XCTAssertEqual(
            try encoder.encode(
                JSONStringEncodableValue(URL(string: "https://example.com/image.png")!, encodedUsing: JSONEncoder())
            ).utf8String,
            #""https:\/\/example.com\/image.png""#
        )
        struct Foo: Encodable {
            let bar = "bar_"
            let bizz = "bizz_"
        }
        XCTAssertEqual(
            try encoder.encode(JSONStringEncodableValue(Foo(), encodedUsing: JSONEncoder())).utf8String,
            #""{\"bar\":\"bar_\",\"bizz\":\"bizz_\"}""#
        )
    }

    func testWhenValueCannotBeEncoded_itThrowsErrorDuringEncoderInvocation() {
        let encoder = JSONEncoder()
        let value = JSONStringEncodableValue(FailingEncodableMock(errorMessage: "ops..."), encodedUsing: JSONEncoder())

        XCTAssertThrowsError(try encoder.encode(value)) { error in
            XCTAssertEqual((error as? ErrorMock)?.description, "ops...")
        }
    }
}
