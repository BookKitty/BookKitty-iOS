public enum LogKit {
    public static func debug(
        _ message: String,
        subSystem: LogSubSystem = .app,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line _: Int = #line
    ) {
        LogEngineWrapper.shared.log(
            .debug,
            message: message,
            subSystem: subSystem,
            category: category,
            file: file,
            function: function
        )
    }
    
    public static func log(
        _ message: String,
        subSystem: LogSubSystem = .app,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line _: Int = #line
    ) {
        LogEngineWrapper.shared.log(
            .log,
            message: message,
            subSystem: subSystem,
            category: category,
            file: file,
            function: function
        )
    }
    
    public static func error(
        _ message: String,
        subSystem: LogSubSystem = .app,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line _: Int = #line
    ) {
        LogEngineWrapper.shared.log(
            .error,
            message: message,
            subSystem: subSystem,
            category: category,
            file: file,
            function: function
        )
    }
    
    public static func info(
        _ message: String,
        subSystem: LogSubSystem = .app,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line _: Int = #line
    ) {
        LogEngineWrapper.shared.log(
            .info,
            message: message,
            subSystem: subSystem,
            category: category,
            file: file,
            function: function
        )
    }
}
