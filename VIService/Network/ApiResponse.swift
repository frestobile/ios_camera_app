//
//  ApiResponse.swift
//  VIService
//
//  Created by HONGYUN on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import Foundation

protocol BaseResponse: Codable {
    var error: Bool { get set }
    var state: Int { get set }
    var msg: String { get set }
}

protocol DeviceResponse: Codable {
    var error: Bool { get set }
    var state: Int { get set }
    var msg: String { get set }
    var url: String { get set }
}

struct DeviceLoginResponse: DeviceResponse {
    var error: Bool
    var state: Int
    var msg: String
    var url: String
}
typealias DeviceLoginHandler = (Result<DeviceLoginResponse>) -> ()

struct VideoCheckResponse: BaseResponse {
    var error: Bool
    var state: Int
    var msg: String
}
typealias VideoCheckHandler = (Result<VideoCheckResponse>) -> ()

struct VideoUploadResponse: Codable {
    var error: Bool
    var msg: String
}
typealias VideoUploadHandler = (Result<VideoUploadResponse>) -> ()

struct VideoCreateResponse : Codable {
    let error: Bool
    let message : String
    let token : String
    let key : String
}
typealias VideoCreateHandler = (Result<VideoCreateResponse>) -> ()

struct VideoSuccessResponse : Codable {
    let error : Bool
}
typealias VideoSuccessHandler = (Result<VideoSuccessResponse>) -> ()


