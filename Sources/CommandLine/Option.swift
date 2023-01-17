//
//  File.swift
//  
//
//  Created by 宋璞 on 2023/1/16.
//

import Foundation

///  A CommandLine Option
open class Option {
    public let shortFlag: String?
    public let longFlag: String?
    public let required: Bool
    public let helpMessage: String
    
    public var wasSet: Bool {
        return false
    }
    
    public var claimedValues: Int { return 0 }
    
    public var flagDescription: String {
        switch (shortFlag, longFlag) {
        case let (sf?, lf?):
            return "\(shortOptionPrefix)\(sf), \(longOptionPrefix)\(lf)"
        case let (nil, lf?):
            return "\(longOptionPrefix)\(lf)"
        case let (sf?, nil):
            return "\(shortOptionPrefix)\(sf)"
        default:
            return ""
        }
    }
    
    internal init(_ shortFlag: String?, _ longFlag: String?, _ required: Bool, _ helpMessage: String) {
        if let sf = shortFlag {
            assert(sf.count == 1, " Short flag must a single character")
            assert(Int(sf) == nil && sf.toDouble() == nil, "Short flag cannot be numberic value")
        }
        if let lf = longFlag {
            assert(Int(lf) == nil && lf.toDouble() == nil, "Long flag cannot be numberic value")
        }
        
        self.shortFlag = shortFlag
        self.longFlag = longFlag
        self.required = required
        self.helpMessage = helpMessage
    }
    
    // MARK: - 初始化选择器
    
    public convenience init(shortFlag: String, longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, longFlag, required, helpMessage)
    }
    
    public convenience init(shortFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, nil, required, helpMessage)
    }
    
    public convenience init(longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(nil, longFlag, required, helpMessage)
    }
    
    
    func flagMatch(_ flag: String) -> Bool {
        return flag == shortFlag || flag == longFlag
    }
    
    func setValue(_ values: [String]) -> Bool {
        return false
    }
}

// MARK: - BoolOption
open class BoolOption: Option {
    private var _value: Bool = false
    
    public var value: Bool {
        return _value
    }
    
    public override var wasSet: Bool {
        return _value
    }
    
    override func setValue(_ values: [String]) -> Bool {
        _value = true
        return true
    }
}

// MARK: - Int Option
open class IntOption: Option {
    private var _value: Int?
    
    public var value: Int? {
        return _value
    }
    
    public override var wasSet: Bool {
        return _value != nil
    }
    
    public override var claimedValues: Int {
        return _value != nil ? 1 : 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        if let val = Int(values[0]) {
            _value = val
            return true
        }
        return false
    }
}

// MARK: - Counter Option
open class CounterOption: Option {
    private var _value: Int = 0
    
    public var value: Int {
        return _value
    }
    
    public override var wasSet: Bool {
        return _value > 0
    }
    
    public func reset() {
        _value = 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        _value += 1
        return true
    }
}

// MARK: - Double Option
open class DoubleOption: Option {
    private var _value: Double?
    
    public var value: Double? {
        return _value
    }
    
    public override var wasSet: Bool {
        return _value != nil
    }
    
    public override var claimedValues: Int {
        return _value != nil ? 1 : 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        if let val = values[0].toDouble() {
            _value = val
            return true
        }
        
        return false
    }
}

// MARK: - String Option
open class StringOption: Option {
    private var _value: String? = nil
    
    public var value: String? {
        return _value
    }
    
    public override var wasSet: Bool {
        return _value != nil
    }
    
    public override var claimedValues: Int {
        return _value != nil ? 1 : 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        _value = values[0]
        return true
    }
}

// MARK: - Multi String Option
open class MultiStringOption: Option {
    private var _value: [String]?
    
    public var value: [String]? {
        return _value
    }
    
    public override var wasSet: Bool {
        return _value != nil
    }
    
    public override var claimedValues: Int {
        if let v = _value {
            return v.count
        }
        return 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        _value = values
        return true
    }
}

// MARK: - enum Option
open class EnumOption<T: RawRepresentable>: Option where T.RawValue == String {
    private var _value: T?
    
    public var value: T? {
        return _value
    }
    
    public override var wasSet: Bool {
        return _value != nil
    }
    
    public override var claimedValues: Int {
        return _value != nil ? 1 : 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        if let val = T(rawValue: values[0]) {
            _value = val
            return true
        }
        return false
    }
}
