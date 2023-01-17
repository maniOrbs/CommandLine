//
//  File.swift
//  
//
//  Created by 宋璞 on 2023/1/16.
//


/* Required for localeconv(3) */
#if os(OSX)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

internal extension String {
    
    /// 本地十进制点
    private func _localDecimalPoint() -> Character {

        guard let local = localeconv(), let decimalPoint = local.pointee.decimal_point else {
            return "."
        }
        return Character(UnicodeScalar(UInt8(bitPattern: decimalPoint.pointee)))
    }
    
    /// 字符串解析为Double
    func toDouble() -> Double? {
        let decimalPoint = String(self._localDecimalPoint())
        guard decimalPoint == "." || self.range(of: ".") == nil else { return nil }
        let localSelf = self.replacingOccurrences(of: decimalPoint, with: ".")
        return Double(localSelf)
    }
    
    /// 拆分
    func split(by: Character, maxSplits: Int = 0) -> [String] {
        var s = [String]()
        var numSplits = 0
        
        var curIdx = self.startIndex
        for i in self.indices {
            let c = self[i]
            if c == by && (maxSplits == 0 || numSplits < maxSplits) {
                s.append(String(self[curIdx..<i]))
                curIdx = self.index(after: i)
                numSplits += 1
            }
        }
        
        if curIdx != self.endIndex {
            s.append(String(self[curIdx..<self.endIndex]))
        }
        return s
    }
    
    
    /// 补齐宽度
    func padded(toWidth width: Int, with padChar: Character = " ") -> String {
        var s = self
        var currentLength = self.count
        
        while currentLength < width {
            s.append(padChar)
            currentLength += 1
        }
        return s
    }
    
    func wrapped(atWidth width: Int, wrapBy: Character = "\n", splityBy: Character = " ") -> String {
        var s = ""
        var currentLineWidth = 0
        
        for word in self.split(by: splityBy) {
            let wordLength = word.count
            
            if currentLineWidth + wordLength + 1 > width {
                if wordLength > width {
                    s += word
                }
                
                s.append(wrapBy)
                currentLineWidth = 0
            }
            currentLineWidth += wordLength + 1
            s += word
        }
        return s
    }
}
