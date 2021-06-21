extension StringProtocol {
    func camelCase(from inputStyle: CaseStyle, upper: Bool) -> String {
        if let delimiter = inputStyle.delimiter {
            return self.split(separator: delimiter).enumerated().map { element -> String in
                if element.offset == 0 && !upper {
                    return String(element.element.lowercased())
                }
                
                return element.element.capitalized
            }.reduce("", +)
        } else { // Assume camel case
            if upper {
                return self.capitalized
            } else {
                return String(self)
            }
        }
    }
}
