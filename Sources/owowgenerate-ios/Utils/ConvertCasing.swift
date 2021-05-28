extension StringProtocol {
    func camelCase(delimiter: Character, upper: Bool) -> String {
        if self.contains(delimiter) {
            return self.split(separator: delimiter).enumerated().map { element -> String in
                if element.offset == 0 && !upper {
                    return element.element.lowercased()
                }
                
                return element.element.capitalized
            }.reduce("", +)
        } else {
            return String(self)
        }
    }
}
