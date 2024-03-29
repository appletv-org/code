//
//  Data+Gzip.swift
//
//  Version 3.0.0

/*
 The MIT License (MIT)
 
 © 2014-2016 1024jp <wolfrosch.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation
import Swiftzlib

/**
 Compression level with constants based on the zlib's constants.
 */
public typealias CompressionLevel = Int32
public extension CompressionLevel {
    
    public static let noCompression = Z_NO_COMPRESSION
    public static let bestSpeed = Z_BEST_SPEED
    public static let bestCompression = Z_BEST_COMPRESSION
    
    public static let defaultCompression = Z_DEFAULT_COMPRESSION
}


/**
 Errors on gzipping/gunzipping based on the zlib error codes.
 */
public enum GzipError: Error {
    // cf. http://www.zlib.net/manual.html
    
    /**
    The stream structure was inconsistent.
    
    - underlying zlib error: `Z_STREAM_ERROR` (-2)
    - parameter message: returned message by zlib
    */
    case stream(message: String)
    
    /**
    The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
    
    - underlying zlib error: `Z_DATA_ERROR` (-3)
    - parameter message: returned message by zlib
    */
    case data(message: String)
    
    /**
    There was not enough memory.
    
    - underlying zlib error: `Z_MEM_ERROR` (-4)
    - parameter message: returned message by zlib
    */
    case memory(message: String)
    
    /**
    No progress is possible or there was not enough room in the output buffer.
    
    - underlying zlib error: `Z_BUF_ERROR` (-5)
    - parameter message: returned message by zlib
    */
    case buffer(message: String)
    
    /**
    The zlib library version is incompatible with the version assumed by the caller.
    
    - underlying zlib error: `Z_VERSION_ERROR` (-6)
    - parameter message: returned message by zlib
    */
    case version(message: String)
    
    /**
    An unknown error occurred.
    
    - parameter message: returned message by zlib
    - parameter code: return error by zlib
    */
    case unknown(message: String, code: Int)
    
    
    internal init(code: Int32, msg: UnsafePointer<CChar>?) {
        
        let message: String = {
            guard let msg = msg, let message = String(validatingUTF8: msg) else {
                return "Unknown gzip error"
            }
            return message
        }()
        
        self = {
            switch code {
            case Z_STREAM_ERROR:
                return .stream(message: message)
                
            case Z_DATA_ERROR:
                return .data(message: message)
                
            case Z_MEM_ERROR:
                return .memory(message: message)
                
            case Z_BUF_ERROR:
                return .buffer(message: message)
                
            case Z_VERSION_ERROR:
                return .version(message: message)
                
            default:
                return .unknown(message: message, code: Int(code))
            }
        }()
    }
    
    
    public var localizedDescription: String {
        
        let description: String = {
            switch self {
            case .stream(let message):
                return message
            case .data(let message):
                return message
            case .memory(let message):
                return message
            case .buffer(let message):
                return message
            case .version(let message):
                return message
            case .unknown(let message, _):
                return message
            }
        }()
        
        return NSLocalizedString(description, comment: "error message")
    }
    
}


public extension Data {
    
    /**
     Check if the reciever is already gzipped.
     
     - returns: Whether the data is compressed.
     */
    public var isGzipped: Bool {
        
        return self.starts(with: [0x1f, 0x8b])  // check magic number
    }
    
    
    /**
    Create a new `Data` object by compressing the receiver using zlib.
    Throws an error if compression failed.
     
    - parameters:
        - level: Compression level in the range of `0` (no compression) to `9` (maximum compression).
    
    - throws: `GzipError`
    - returns: Gzip-compressed `Data` object.
    */
    public func gzipped(level: CompressionLevel = .defaultCompression) throws -> Data {
        
        guard self.count > 0 else {
            return Data()
        }
        
        var stream = self.createZStream()
        var status: Int32
        
        status = deflateInit2_(&stream, level, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, STREAM_SIZE)

        guard status == Z_OK else {
            // deflateInit2 returns:
            // Z_VERSION_ERROR  The zlib library version is incompatible with the version assumed by the caller.
            // Z_MEM_ERROR      There was not enough memory.
            // Z_STREAM_ERROR   A parameter is invalid.
            
            throw GzipError(code: status, msg: stream.msg)
        }
        
        var data = Data(capacity: CHUNK_SIZE)
        while stream.avail_out == 0 {
            if Int(stream.total_out) >= data.count {
                data.count += CHUNK_SIZE
            }
            
            data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<Bytef>) in
                stream.next_out = bytes.advanced(by: Int(stream.total_out))
            }
            stream.avail_out = uInt(data.count) - uInt(stream.total_out)
            
            deflate(&stream, Z_FINISH)
        }
        
        deflateEnd(&stream)
        data.count = Int(stream.total_out)
        
        return data
    }
    
    
    /**
    Create a new `Data` object by decompressing the receiver using zlib.
    Throws an error if decompression failed.
    
    - throws: `GzipError`
    - returns: Gzip-decompressed `Data` object.
    */
    public func gunzipped() throws -> Data {
        
        guard self.count > 0 else {
            return Data()
        }
        
        var stream = self.createZStream()
        var status: Int32
        
        status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, STREAM_SIZE)
        
        guard status == Z_OK else {
            // inflateInit2 returns:
            // Z_VERSION_ERROR   The zlib library version is incompatible with the version assumed by the caller.
            // Z_MEM_ERROR       There was not enough memory.
            // Z_STREAM_ERROR    A parameters are invalid.
            
            throw GzipError(code: status, msg: stream.msg)
        }
        
        var data = Data(capacity: self.count * 2)
        
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += self.count / 2;
            }
            
            data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<Bytef>) in
                stream.next_out = bytes.advanced(by: Int(stream.total_out))
            }
            stream.avail_out = uInt(data.count) - uInt(stream.total_out)
            
            status = inflate(&stream, Z_SYNC_FLUSH)
            
        } while status == Z_OK
        
        guard inflateEnd(&stream) == Z_OK && status == Z_STREAM_END else {
            // inflate returns:
            // Z_DATA_ERROR   The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
            // Z_STREAM_ERROR The stream structure was inconsistent (for example if next_in or next_out was NULL).
            // Z_MEM_ERROR    There was not enough memory.
            // Z_BUF_ERROR    No progress is possible or there was not enough room in the output buffer when Z_FINISH is used.
            
            throw GzipError(code: status, msg: stream.msg)
        }
        
        data.count = Int(stream.total_out)
        
        return data
    }
    
    
    private func createZStream() -> z_stream {
        
        var stream = z_stream()
        
        self.withUnsafeBytes { (bytes: UnsafePointer<Bytef>) in
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: bytes)
        }
        stream.avail_in = uint(self.count)
        
        return stream
    }
    
}


private let CHUNK_SIZE: Int = 2 ^ 14
private let STREAM_SIZE: Int32 = Int32(MemoryLayout<z_stream>.size)
