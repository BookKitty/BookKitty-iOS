//
//  FileWritingService.swift
//  LogKit
//
//  Created by 권승용 on 3/18/25.
//

import Foundation

/// CSV 파일로 로그를 기록하는 객체
/// 앱 실행 시마다 실행 시작 시간을 파일 이름 prefix로 가지는 CSV 파일 생성
/// 한 파일 당 60KB가 넘어갈 경우 새로운 파일 생성
final class FileWritingService {
    
    private let fileManager = FileManager.default
    
    /// 로그 엔진 시작 시간 문자열
    private let logEngineStartTime: String
    
    /// 현재 CSV 파일 ID
    private var currentCSVFileID = 1
    
    /// 현재 CSV 파일 URL
    private var currentCSVFileURL: URL?
    
    /// 현재 CSV 파일 크기
    private var currentCSVFileSize: UInt64 = 0
    
    /// 최대 CSV 파일 크기 (60KB)
    private let maxCSVFileSize: UInt64 = 60 * 1024
     
    init() {
        let startTimeFormatter = DateFormatter()
        startTimeFormatter.dateFormat = "yyyyMMdd_HHmm"
        
        logEngineStartTime = startTimeFormatter.string(from: Date())
    }
    
    func writeToCSVFile(
        timestamp: String,
        level: String,
        fileName: String,
        line: String,
        function: String,
        message: String,
        subSystem: String,
        category: String
    ) {
        let escapedMessage = message.replacingOccurrences(of: "\"", with: "\"\"")
        let escapedFunction = function.replacingOccurrences(of: "\"", with: "\"\"")
        
        // CSV 행 생성
        let csvRow =
        "\"\(timestamp)\",\"\(level)\",\"\(fileName)\",\"\(line)\",\"\(escapedFunction)\",\"\(escapedMessage)\",\"\(subSystem)\",\"\(category)\"\n"
        
        guard let csvData = csvRow.data(using: .utf8) else {
            return
        }
        let dataSize = UInt64(csvData.count)
        
        // 현재 파일이 최대 크기를 초과하는지 확인
        if currentCSVFileSize + dataSize > maxCSVFileSize {
            currentCSVFileID += 1
            createNewCSVFile()
        }
        
        // CSV 파일에 로그 추가
        guard let fileURL = currentCSVFileURL else {
            return
        }
        
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(csvData)
            try? fileHandle.close()
            
            currentCSVFileSize += dataSize
        }
    }
    
    func createNewCSVFile() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(logEngineStartTime)-\(currentCSVFileID).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)

        // CSV 헤더 생성
        let headerRow = "Timestamp,Level,FileName,Line,Function,Message,SubSystem,Category\n"

        do {
            try headerRow.write(to: fileURL, atomically: true, encoding: .utf8)
            currentCSVFileURL = fileURL
            currentCSVFileSize = UInt64(headerRow.utf8.count)
            print("새 CSV 로그 파일이 생성되었습니다: \(fileName)")
        } catch {
            print("CSV 로그 파일 생성 실패: \(error)")
        }
    }
}
