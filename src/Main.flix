def main(): Unit \ {IO, Net} = 
    region rc {
        let (config, initialTodos) = run {
            let config = TodoConfig.init();
            let initialTodos = TodoConfig.getInitialTodos(config);
            (config, initialTodos)
        } with TodoConfigHandler.runWithHardCoded;
        
        let stateRef = Ref.fresh(rc, initialTodos);
        
        match AppConfig.getMode(config) {
            case AppMode.WebApp(port) => runWebApp(stateRef, port)
            case AppMode.TestMode => 
                println("Test mode not implemented")
        }
    }

def runWebApp(stateRef: Ref[List[Todo], r], port: Int32): Unit \ {IO, Net} = 
    let handleRequest = (method: String, path: String, formData: Map[String, String]) -> {
        run {
            let cmd = HttpAdapter.parseCommand(method, path, formData);
            TodoApplication.handleCommand(cmd)
        } with TodoStorageHandler.runWithState(stateRef)
          with TodoViewHandler.runWithString
    };
    WebServer.start(handleRequest, port)