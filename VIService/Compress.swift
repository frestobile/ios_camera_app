//
//  Compress.swift
//  VIService
//
//  Created by Frestobile on 4/22/24.
//  Copyright © 2024 SKYPE: brt.star93 All rights reserved.
//

import Foundation
import mobileffmpeg
//import ffmpegkit

class Compress {
    var progressHandler: ((Float) -> Void)?
    
    func compressVideo(inputVideoUrl: URL, outputVideoUrl: URL, completion: @escaping (Bool, URL, Error?) -> Void) {

//        let command = "-i \(inputVideoUrl.path) -c:v h264 -crf 18 -preset veryslow -vf scale=1280:720 -c:a aac -b:a 128k \(outputVideoUrl.path)"
        let command = "-i \(inputVideoUrl.path) -c:v h264 -r 30 -b:v 2500k -s 1280x720 -c:a aac -b:a 64k \(outputVideoUrl.path)"

        DispatchQueue.global(qos: .background).async {
            let result = MobileFFmpeg.execute(command)
            DispatchQueue.main.async {
                if result == RETURN_CODE_SUCCESS {
                    completion(true, outputVideoUrl, nil)
                } else if result == RETURN_CODE_CANCEL {
                    completion(false, outputVideoUrl, NSError(domain: "FFmpeg", code: Int(result), userInfo: [NSLocalizedDescriptionKey: "Operation cancelled"]))
                } else {
                    completion(false, outputVideoUrl, NSError(domain: "FFmpeg", code: Int(result), userInfo: [NSLocalizedDescriptionKey: "Command failed with return code \(result) (\(MobileFFmpegConfig.getLastCommandOutput() ?? ""))"]))
                }
            }
        }
    }
    
}
