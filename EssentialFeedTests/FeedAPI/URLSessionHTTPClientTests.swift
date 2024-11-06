//
//  URLSessionHTTPClient.swift
//  EssentialFeedTests
//
//  Created by soujanya Balusu on 17/10/24.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()

        URLProtocalStub.startInterceptingRequests()
    }

    override func tearDown() {
        super.tearDown()

        URLProtocalStub.stopInterceptingRequests()
    }

    func test_getFromURL_performGETRequestWithURL() {

        let url = anyURL()
        let exp = expectation(description: "Wait for expectation")

        URLProtocalStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: anyURL()) { _ in  }
        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as NSError?

        XCTAssertEqual(receivedError?.domain, requestError.domain, "Error domains should be equal")
        XCTAssertEqual(receivedError?.code, requestError.code, "Error codes should be equal")
    }

    func test_getFromURL_failsOnAllInvalidRespresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }

    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)

        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        //Given
        let data = anyData()
        let response = anyHTTPURLResponse()

        //when
        let receivedValues = resultValuesFor(data: data, response: response, error: nil)

        //Then
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    // MARK: - Helpers 10

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut,file: file,line: line)
        return URLSessionHTTPClient()
    }

    private func resultFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #file, line: UInt = #line) -> HTTPClient.Result {
        URLProtocalStub.stub(data: data, response: response, error: error)

        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var receivedResult: HTTPClient.Result!

        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #file, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error)

        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("Expected failure got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?,file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        URLProtocalStub.stub(data: data, response: response, error: error)
        let result = resultFor(data: data, response: response, error: error)

        switch result {
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("Expected failure got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func anyData() -> Data {
        return Data("any Data".utf8)
    }

    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private class URLProtocalStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        //24 tupple
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        //15 stubbing for session task resume
        static func stub( data: Data?,
                          response: URLResponse?,
                          error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func observeRequests(observer: @escaping(URLRequest) -> Void) {
            requestObserver = observer
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocalStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocalStub.self)
            //also remove the stubs
            stub = nil
            requestObserver = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let requestObserver = URLProtocalStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }

            if let data = URLProtocalStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let reponse = URLProtocalStub.stub?.response {
                client?.urlProtocol(self, didReceive: reponse,cacheStoragePolicy: .notAllowed)
            }

            if let  error = URLProtocalStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }
        override func stopLoading() {}
    }
}
