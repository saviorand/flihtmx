def main(): Unit \ {IO, Net} = 
    let config = AppConfig.webApp(8080);
    
    match AppConfig.getMode(config) {
        case AppMode.WebApp(port) => runWebApp(port, config)
        case AppMode.TestMode => 
            println("Test mode not implemented")
    }

def runWebApp(port: Int32, config: AppConfig): Unit \ {IO, Net} = region rc {
    let initialTodos = AppConfig.getInitialTodos(config);
    let stateRef = Ref.fresh(rc, initialTodos);
    
    let handleRequest = (method: String, path: String, formData: Map[String, String]) -> {
        let cmd = HttpAdapter.parseCommand(method, path, formData);
        run {
            TodoApplication.handleCommand(cmd)
        } with TodoStorageHandler.runWithState(stateRef)
          with TodoViewHandler.runWithString
    };
    
    WebServer.start(handleRequest, port)
}