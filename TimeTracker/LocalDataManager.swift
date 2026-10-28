//
//  LocalDataManager.swift
//  TimeTracker
//
//  Created by 李中正 on 2025/12/10.
//
// MARK: - LocalDataManager.swift - 本地文件管理核心 (无iCloud版)
// 逻辑：将数据直接存入 App 的文档目录，并对用户可见
//

import Foundation

class LocalDataManager {
    static let shared = LocalDataManager()
    private init() {}
    
    // 获取 App 的本地文档目录
    // 路径类似：On My iPhone / TimeTracker /
    var localDocumentsURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // 1. 保存通用 JSON (用于 App 读取恢复数据)
    func saveJSON<T: Encodable>(_ object: T, filename: String) {
        let url = localDocumentsURL.appendingPathComponent(filename)
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(object)
                try data.write(to: url, options: .atomic)
            } catch {
                print("❌ Save JSON Error: \(error)")
            }
        }
    }
    
    // 2. 读取通用 JSON
    func loadJSON<T: Decodable>(filename: String, type: T.Type) -> T? {
        let url = localDocumentsURL.appendingPathComponent(filename)
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }
    
    // 3. 导出 CSV (Excel) 到指定文件夹
    // 逻辑：自动创建子文件夹，写入带 BOM 头的 CSV (防止乱码)
    func saveCSV(content: String, folderName: String, filename: String) {
        let root = localDocumentsURL
        let folderURL = root.appendingPathComponent(folderName)
        
        // 创建文件夹 (如果不存在)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        let fileURL = folderURL.appendingPathComponent(filename)
        
        DispatchQueue.global(qos: .background).async {
            do {
                // \u{FEFF} 是 BOM 头，让 Excel 能正确识别中文
                let bomContent = "\u{FEFF}" + content
                try bomContent.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("❌ Export CSV Error: \(error)")
            }
        }
    }
    
    // 4. 获取文件路径 (用于分享)
    func getExportURL(folderName: String, filename: String) -> URL {
        return localDocumentsURL.appendingPathComponent(folderName).appendingPathComponent(filename)
    }
}
