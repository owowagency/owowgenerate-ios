import Foundation

extension String {
    func writeIfNeeded(to url: URL) throws {
        if let existingData = try? Data(contentsOf: url), let existingString = String(data: existingData, encoding: .utf8), existingString == self {
            /// Don't overwrite the file if not changed.
            return
        }
        
        try write(to: url, atomically: true, encoding: .utf8)
    }
}
