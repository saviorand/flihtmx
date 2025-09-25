import com.sun.net.httpserver.{HttpServer => JavaHttpServer, HttpHandler, HttpExchange}
import java.net.InetSocketAddress
import java.lang.InterruptedException
import java.lang.Thread
import java.util.Scanner

enum HttpResponse {
    case Ok(String, Map[String, String])
    case Error(Int32, String)
}

def startServer(port: Int32): Unit \ {IO, Net} = {
    region rc {
        let stateRef = Ref.fresh(rc, initialState());
        let addr = new InetSocketAddress(port);
        let server = JavaHttpServer.create(addr, 0);
        server.createContext("/", createHandler(stateRef));
        server.start();
        println("Effect-Oriented Todo Server ready at http://localhost:${port}");
        
        let currentThread = Thread.currentThread();
        try {
            currentThread.join()
        } catch {
            case _: InterruptedException => 
                println("Server shutting down...")
        }
    }
}

def createHandler(stateRef: Ref[AppState, r]): HttpHandler \ {IO} = new HttpHandler {
    def $handle(_this: HttpHandler, exchange: HttpExchange): Unit \ {IO, Net, r} = {
        handleRequest(stateRef, exchange)
    }
}

def handleRequest(stateRef: Ref[AppState, r], exchange: HttpExchange): Unit \ {IO, Net, r} = {
    let method = exchange.getRequestMethod();
    let path = exchange.getRequestURI().getPath();
    let body = readRequestBody(exchange);
    let formData = parseFormData(body);

    TodoState.handleWithInMemory(stateRef, _ ->
        run {
            run {
                handleUserCommand()
            } with UserInput.handleWithHttp(method, path, formData)
        } with View.handleWithHtmx(exchange)
    )
}

def parseFormData(body: String): Map[String, String] = {
    if (String.isEmpty(body)) {
        Map.empty()
    } else {
        let pairs = String.split(regex="&", body);
        List.foldLeft((acc, pair) -> {
            let parts = String.split(regex="=", pair);
            match parts {
                case key :: value :: _ => {
                    let decodedKey = String.replace(src="+", dst=" ", key);
                    let decodedValue = String.replace(src="+", dst=" ", value);
                    Map.insert(decodedKey, decodedValue, acc)
                }
                case _ => acc
            }
        }, Map.empty(), pairs)
    }
}

def readRequestBody(exchange: HttpExchange): String \ IO = {
    let inputStream = exchange.getRequestBody();
    let scanner = new Scanner(inputStream);
    if (scanner.hasNext()) scanner.useDelimiter("\\A").next() else ""
}

def htmlHeaders(): Map[String, String] = 
    Map#{"Content-Type" => "text/html; charset=utf-8"}
