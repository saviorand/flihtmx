def main(): Unit \ {IO, Net} = 
    region rc {
        let (config, initialTodos) = run {
            let config = TodoConfig.init();
            let initialTodos = AppConfig.getInitialTodos(config);
            (config, initialTodos)
        } with TodoConfigHandler.runWithHardCoded;
        
        let stateRef = Ref.fresh(rc, initialTodos);
        
        run {
            match AppConfig.getMode(config) {
                case AppMode.WebApp(port) => runWebApp(port)
                case AppMode.TestMode => 
                    println("Test mode not implemented")
            }
        } with TodoStorageHandler.runWithState(stateRef)
          with TodoViewHandler.runWithString
    }

def runWebApp(port: Int32): Unit \ {IO, Net} = 
    let handleRequest = (method: String, path: String, formData: Map[String, String]) -> {
        let cmd = HttpAdapter.parseCommand(method, path, formData);
        TodoApplication.handleCommand(cmd)
    };
    WebServer.start(handleRequest, port)