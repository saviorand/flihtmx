mod RuntimeHandlers {
    import com.sun.net.httpserver.{HttpServer => JavaHttpServer, HttpHandler, HttpExchange}
    import java.net.InetSocketAddress
    import java.lang.InterruptedException
    import java.lang.Thread
    
    pub def runWithWebServer(stateRef: Ref[List[Todo], r], port: Int32, f: Unit -> a \ ef): a \ (ef - TodoApp + r + IO + Net) =
        run {
            f()
        } with handler TodoApp {
            def runApp(_, k) = {
                startWebServer(stateRef, port);
                k()
            }
            
            def handleCommand(_cmd, k) = {
                // In web mode, commands are handled per-request
                k()
            }
        }
    
    def startWebServer(stateRef: Ref[List[Todo], r], port: Int32): Unit \ {IO, Net} = {
        let addr = new InetSocketAddress(port);
        let server = JavaHttpServer.create(addr, 0);
        server.createContext("/", createWebHandler(stateRef));
        server.start();
        println("Todo web server running on http://localhost:${port}");
        
        try {
            Thread.currentThread().join()
        } catch {
            case _: InterruptedException => 
                println("Server interrupted")
        }
    }
    
    def createWebHandler[r: Region](stateRef: Ref[List[Todo], r]): HttpHandler \ {IO} = 
        new HttpHandler {
            def $handle(_this: HttpHandler, exchange: HttpExchange): Unit \ {IO, Net, r} = {
                let request = HttpRequest.fromExchange(exchange);
                let method = HttpRequest.getMethod(request);
                let path = HttpRequest.getPath(request);
                let formData = HttpRequest.getFormData(request);
                let cmd = HttpAdapter.parseCommand(method, path, formData);
                
                AppBootstrap.runWithInMemoryStorage(stateRef, _ ->
                    HtmlView.runWithWebView(exchange, _ -> 
                        TodoApplication.handleCommand(cmd)
                    )
                )
            }
        }
}