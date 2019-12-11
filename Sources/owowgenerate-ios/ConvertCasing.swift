extension StringProtocol {
    func camelCase(delimiter: Character, upper: Bool) -> String {
        return self.split(separator: delimiter).enumerated().map { element -> String in
            if element.offset == 0 && !upper {
                return element.element.lowercased()
            }
            
            return element.element.capitalized
        }.reduce("", +)
    }
}
