//
//  DataReaderTests.swift
//  SoftU2F
//
//  Created by Benjamin P Toews on 9/11/16.
//

import XCTest

class DataReaderTests: XCTestCase {
    func testUInt8() throws {
        let data = Data(bytes: [0x00, 0x01, 0x02])
        let reader = DataReader(data: data, offset: 1)
        var ores: UInt8?
        var res: UInt8

        XCTAssertEqual(2, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, 0x01)
        XCTAssertEqual(2, reader.remaining)
        res = try reader.read()
        XCTAssertEqual(res, 0x01)

        XCTAssertEqual(1, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, 0x02)
        XCTAssertEqual(1, reader.remaining)
        res = try reader.read()
        XCTAssertEqual(res, 0x02)

        XCTAssertEqual(0, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, nil)
        XCTAssertEqual(0, reader.remaining)

        do {
            res = try reader.read()
            XCTAssert(false, "expected exception")
        } catch DataReaderError.End {
            // pass
        }

        XCTAssertEqual(0, reader.remaining)
    }

    func testUInt16() throws {
        let data = Data(bytes: [0x00, 0x01, 0x02, 0x03, 0x04])
        let reader = DataReader(data: data, offset: 0)
        var ores: UInt16?
        var res: UInt16

        XCTAssertEqual(5, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, 0x0001)
        XCTAssertEqual(5, reader.remaining)
        res = try reader.read()
        XCTAssertEqual(res, 0x0001)

        XCTAssertEqual(3, reader.remaining)
        ores = reader.peek(endian: .Little)
        XCTAssertEqual(ores, 0x0302)
        XCTAssertEqual(3, reader.remaining)
        res = try reader.read(endian: .Little)
        XCTAssertEqual(res, 0x0302)

        XCTAssertEqual(1, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, nil)

        do {
            res = try reader.read()
            XCTAssert(false, "expected exception")
        } catch DataReaderError.End {
            // pass
        }

        XCTAssertEqual(1, reader.remaining)
    }

    func testReadVersionCmdHdr() throws {
        let raw = Data(bytes: [0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00])
        let reader = DataReader(data: raw)
        var byte: UInt8
        let len: UInt16
        let intLen: Int

        // cla
        byte = try reader.read()
        XCTAssertEqual(byte, 0x00)

        // ins
        byte = try reader.read()
        XCTAssertEqual(byte, 0x03)

        // p1
        byte = try reader.read()
        XCTAssertEqual(byte, 0x00)

        // p2
        byte = try reader.read()
        XCTAssertEqual(byte, 0x00)

        // lc0
        byte = try reader.read()
        XCTAssertEqual(byte, 0x00)

        // data length
        len = try reader.read()
        XCTAssertEqual(len, 0x0000)

        intLen = Int(len)
        XCTAssertEqual(intLen, 0)
    }

    func testReadOptionalUInt8() {
        let data = Data(bytes: [0x00])
        let reader = DataReader(data: data)
        var ores: UInt8?

        XCTAssertEqual(1, reader.remaining)
        ores = reader.read()
        XCTAssertEqual(ores, 0x00)

        XCTAssertEqual(0, reader.remaining)
        ores = reader.read()
        XCTAssertEqual(ores, nil)

        XCTAssertEqual(0, reader.remaining)
    }

    func testReadBytes() throws {
        let data = Data(bytes: [0x00, 0x01, 0x02, 0x03, 0x04])
        let reader = DataReader(data: data, offset: 0)
        var ores: Data?
        var res: Data

        let expected = data.subdata(in: 0..<2)
        XCTAssertEqual(5, reader.remaining)
        ores = reader.peekData(2)
        XCTAssertEqual(ores, expected)
        XCTAssertEqual(5, reader.remaining)
        res = try reader.readData(2)
        XCTAssertEqual(res, expected)

        XCTAssertEqual(3, reader.remaining)
        ores = reader.peekData(4)
        XCTAssertEqual(ores, nil)
        XCTAssertEqual(3, reader.remaining)

        do {
            res = try reader.readData(4)
            XCTAssert(false, "expected exception")
        } catch DataReaderError.End {
            // pass
        }

        XCTAssertEqual(3, reader.remaining)
    }

    func testReadBytesWithUIntArgs() throws {
        let data = Data(bytes: [0x00, 0x01, 0x02, 0x03, 0x04])
        let reader = DataReader(data: data, offset: 0)
        var ores: Data?
        var res: Data

        let expected = data.subdata(in: 0..<2)
        XCTAssertEqual(5, reader.remaining)
        ores = reader.peekData(UInt8(2))
        XCTAssertEqual(ores, expected)
        XCTAssertEqual(5, reader.remaining)
        res = try reader.readData(Int16(2))
        XCTAssertEqual(res, expected)

        XCTAssertEqual(3, reader.remaining)
        ores = reader.peekData(UInt32(4))
        XCTAssertEqual(ores, nil)
        XCTAssertEqual(3, reader.remaining)

        do {
            res = try reader.readData(UInt64(4))
            XCTAssert(false, "expected exception")
        } catch DataReaderError.End {
            // pass
        }

        XCTAssertEqual(3, reader.remaining)
    }

    enum Place: UInt8, EndianEnumProtocol {
        typealias RawValue = UInt8

        case first = 0x01
        case second = 0x02
        case third = 0x03
    }

    func testReadEnum() throws {
        let reader = DataReader(data: Data(bytes: [0x01, 0x02, 0x03, 0x04]))
        var p: Place
        var op: Place?

        XCTAssertEqual(4, reader.remaining)
        op = reader.peek()
        XCTAssertEqual(Place.first, op)
        XCTAssertEqual(4, reader.remaining)
        p = try reader.read()
        XCTAssertEqual(Place.first, p)

        XCTAssertEqual(3, reader.remaining)
        p = try reader.read()
        XCTAssertEqual(Place.second, p)

        XCTAssertEqual(2, reader.remaining)
        p = try reader.read()
        XCTAssertEqual(Place.third, p)

        XCTAssertEqual(1, reader.remaining)
        op = reader.peek()
        XCTAssertEqual(nil, op)

        do {
            p = try reader.read()
            XCTFail("expected an exception")
        } catch DataReaderError.TypeError {
            // pass.
        }

        XCTAssertEqual(0, reader.remaining)
        op = reader.peek()
        XCTAssertEqual(nil, op)

        do {
            p = try reader.read()
            XCTFail("expected an exception")
        } catch DataReaderError.End {
            // pass
        }
    }

    func testReadOptionalEnum() {
        let reader = DataReader(data: Data(bytes: [0x01, 0x02, 0x03, 0x04]))
        var op: Place?

        XCTAssertEqual(4, reader.remaining)
        op = reader.peek()
        XCTAssertEqual(Place.first, op)
        XCTAssertEqual(4, reader.remaining)
        op = reader.read()
        XCTAssertEqual(Place.first, op)

        XCTAssertEqual(3, reader.remaining)
        op = reader.read()
        XCTAssertEqual(Place.second, op)

        XCTAssertEqual(2, reader.remaining)
        op = reader.read()
        XCTAssertEqual(Place.third, op)

        XCTAssertEqual(1, reader.remaining)
        op = reader.read()
        XCTAssertEqual(nil, op)

        XCTAssertEqual(0, reader.remaining)
        op = reader.read()
        XCTAssertEqual(nil, op)
    }
}
