def main(): Unit \ {IO, Net} = 
    let config = AppConfig.webApp(8080);
    runApp(config)

def runApp(config: AppConfig): Unit \ {IO, Net} = region rc {
    let initialTodos = AppConfig.getInitialTodos(config);
    let stateRef = Ref.fresh(rc, initialTodos);
    
    match AppConfig.getMode(config) {
        case AppMode.WebApp(port) => 
            RuntimeHandlers.runWithWebServer(stateRef, port, _ ->
                AppBootstrap.createApp(config)
            )
        case AppMode.TestMode => 
            println("Test mode not implemented")
    }
}