mod WebServer {
    import com.sun.net.httpserver.{HttpServer => JavaHttpServer, HttpHandler, HttpExchange}
    import java.net.InetSocketAddress
    import java.lang.InterruptedException
    import java.lang.Thread

    pub def start(handleRequest: (String, String, Map[String, String]) -> String \ ef, port: Int32): Unit \ {IO, Net} = {
        let addr = new InetSocketAddress(port);
        let server = JavaHttpServer.create(addr, 0);
        server.createContext("/", createHandler(handleRequest));
        server.start();
        println("Todo web server running on http://localhost:${port}");
        
        try {
            Thread.currentThread().join()
        } catch {
            case _: InterruptedException => 
                println("Server interrupted")
        }
    }
    
    def createHandler(handleRequest: (String, String, Map[String, String]) -> String \ ef): HttpHandler \ {IO} = 
        new HttpHandler {
            def $handle(_this: HttpHandler, exchange: HttpExchange): Unit \ {IO, Net, ef} = {
                let request = HttpRequest.fromExchange(exchange);
                let method = HttpRequest.getMethod(request);
                let path = HttpRequest.getPath(request);
                let formData = HttpRequest.getFormData(request);
                
                let response = handleRequest(method, path, formData);
                
                if (String.startsWith(prefix="/", path) and path != "/") {
                    HttpHelper.writeHtmxResponse(exchange, response)
                } else {
                    HttpHelper.writeHtmlResponse(exchange, response)
                }
            }
        }
}