import Foundation

let shortOptionPrefix = "-"
let longOptionPrefix = "--"

let argumentStoper = "--"
let argumentAttacter: Character = "="

private struct StderrOutputStream: TextOutputStream {
    static let stream = StderrOutputStream()
    func write(_ s: String) {
        fputs(s, stderr)
    }
}

/// 命令行
public class CommandLine {
    
    private var  _arguments: [String]
    private var _options: [Option] = [Option]()
    private var _maxFlagDescriptionWidth: Int = 0
    private var _usedFlags: Set<String> {
        var usedFlags = Set<String>(minimumCapacity: _options.count * 2)
        for option in _options {
            for case let flag? in [option.shortFlag, option.longFlag] {
                usedFlags.insert(flag)
            }
        }
        return usedFlags
    }
    
    /// 使用子命令
    public var usesSubCommands = false
    /// 未解析参数
    public private(set) var unparsedArguments: [String] = [String]()
    /// 输出格式
    public var formatOutput:((String, OutputType) -> String)?
    /// 最大描述宽度
    public var maxFlagDescriptionWidth: Int {
        if _maxFlagDescriptionWidth == 0 {
            _maxFlagDescriptionWidth = _options.map { $0.flagDescription.count }.sorted().first ?? 0
        }
        return _maxFlagDescriptionWidth
    }
    
    
    
    /// 输出类型
    public enum OutputType {
        case about
        case error
        case optionFlag
        case optionHelp
    }
    
    
    /// 解析错误
    public enum ParseError: Error, CustomStringConvertible {
        case invalidArgument(String)
        case invalidValueForOption(Option, [String])
        case missingRequiredOptions([Option])
        
        public var description: String {
            switch self {
            case let .invalidArgument(arg):
                return "Invalid argument: \(arg)"
            case let .invalidValueForOption(opt, vals):
                let vs = vals.joined(separator: ", ")
                return "Invalid value(s) for option \(opt.flagDescription): \(vs)"
            case let .missingRequiredOptions(opts):
                return "Miss required Options: \(opts.map { $0.flagDescription })"
            }
        }
    }
    
    
    /// Init Object
    public init(_arguments: [String] = Swift.CommandLine.arguments) {
        self._arguments = _arguments
        
        setlocale(LC_ALL, "")
    }
    
    private func _getFlagValues(_ flagIndex: Int, _ attachedArg: String? = nil) -> [String] {
        var args: [String] = [String]()
        var skipFlagChecks = false
        
        if let a = attachedArg {
            args.append(a)
        }
        
        for i in flagIndex + 1 ..< _arguments.count {
            
            if !skipFlagChecks {
                if _arguments[i] == argumentStoper {
                    skipFlagChecks = true
                    continue
                }
                
                if _arguments[i].hasPrefix(shortOptionPrefix) && Int(_arguments[i]) == nil && _arguments[i].toDouble() == nil {
                    break
                }
                
                args.append(_arguments[i])
            }
        }
        return args
    }
    
    /// 添加 Option
    public func addOption(_ option: Option) {
        let uf = _usedFlags
        for case let flag? in [option.shortFlag, option.longFlag] {
            assert(!uf.contains(flag), "Flag '\(flag)' alread in use")
        }
        _options.append(option)
        _maxFlagDescriptionWidth = 0
    }
    
    public func addOptions(_ options: [Option]) {
        for o in options {
            addOption(o)
        }
    }
    
    public func addOptions(_ options: Option...) {
        for o in options {
            addOption(o)
        }
    }
    
    public func setOptions(_ options: [Option]) {
        _options = options
        addOptions(options)
    }
    
    public func setOptions(_ options: Option...) {
        _options = options
        addOptions(options)
    }
    
    /// 解析
    /// - Parameter strict: 严格的
    public func parse(strict: Bool = false) throws {
        var strays = _arguments
        
        strays[0] = ""
        
        let argumentsEnumerator = _arguments.enumerated()
        for (idx, arg) in argumentsEnumerator {
            if arg == argumentStoper {
                break
            }
            
            if !arg.hasPrefix(shortOptionPrefix) {
                continue
            }
            
            let skipChars = arg.hasPrefix(longOptionPrefix) ? longOptionPrefix.count : shortOptionPrefix.count
            let flagWithArg = arg[arg.index(arg.startIndex, offsetBy: skipChars)..<arg.endIndex]
            
            if flagWithArg.isEmpty {
                continue
            }
            
            let splitFlag = flagWithArg.split(separator: argumentAttacter, maxSplits: 1)
            let flag = splitFlag[0]
            let attachedArg: String?
            if splitFlag.count == 2 {
                attachedArg = String(splitFlag[1])
            } else {
                attachedArg = nil
            }
            
            var flagMatched = false
            for option in _options where option.flagMatch(String(flag)) {
                let vals = self._getFlagValues(idx, attachedArg)
                guard option.setValue(vals) else {
                    throw ParseError.invalidValueForOption(option, vals)
                }
                
                var claimedIdx = idx + option.claimedValues
                if attachedArg != nil { claimedIdx -= 1 }
                for i in idx...claimedIdx {
                    strays[i] = ""
                }
                flagMatched = true
                break
            }
            
            let flagLength = flag.count
            if !flagMatched && !arg.hasPrefix(longOptionPrefix) {
                let flagCharacterEnumerator = flag.enumerated()
                for (i, c) in flagCharacterEnumerator {
                    for option in _options where option.flagMatch(String(c)) {
                        let vals = (i == flagLength - 1) ? self._getFlagValues(idx, attachedArg) : [String]()
                        guard option.setValue(vals) else {
                            throw ParseError.invalidValueForOption(option, vals)
                        }
                        
                        var claimedIdx = idx + option.claimedValues
                        if attachedArg != nil { claimedIdx -= 1 }
                        for i in idx...claimedIdx {
                            strays[i] = ""
                        }
                        
                        flagMatched = true
                        break
                    }
                }
            }
            
            guard !strict || flagMatched else {
                throw ParseError.invalidArgument(arg)
            }
            
            let missingOptions = _options.filter { $0.required && $0.wasSet }
            guard missingOptions.count == 0 else {
                throw ParseError.missingRequiredOptions(missingOptions)
            }
            
            unparsedArguments = strays.filter { $0 != "" }
            
        }
    }
    
    public func defaultFormat(s: String, type: OutputType) -> String {
        switch type {
        case .about:
            return "\(s)\n"
        case .error:
            return "\(s)\n\n"
        case .optionFlag:
            return "  \(s.padded(toWidth: maxFlagDescriptionWidth)):\n"
        case .optionHelp:
            return "    \(s)\n"
        }
    }
    
    /// 打印 用法
    public func printUsage<TargetStream: TextOutputStream>(_ to: inout TargetStream) {
        let format = formatOutput != nil ? formatOutput! : defaultFormat
        
        var name = _arguments[0]
        if usesSubCommands && _arguments.count > 1 {
            name = _arguments[0].split(by: "/").last! + " " + _arguments[1]
        } else {
            name = _arguments[0].split(by: "/").last!
        }
        print(format("Usage: \(name) [options]", .about), terminator: "", to: &to)
        
        for opt in _options {
            print(format(opt.flagDescription, .optionFlag), terminator: "", to: &to)
            print(format(opt.helpMessage, .optionHelp), terminator: "", to: &to)
        }
    }
    
    public func printUsage<TargetStream: TextOutputStream>(_ error: Error, to: inout TargetStream) {
        let format = formatOutput != nil ? formatOutput! : defaultFormat
        print(format("\(error)", .error), terminator: "", to: &to)
        printUsage(&to)
    }
    
    public func printUsage(_ error: Error) {
        var out = StderrOutputStream.stream
        printUsage(error, to: &out)
    }
    
    public func printUsage() {
        var out = StderrOutputStream.stream
        printUsage(&out)
    }
    
}
