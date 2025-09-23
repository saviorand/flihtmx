import com.sun.net.httpserver.{HttpServer => JavaHttpServer, HttpHandler, HttpExchange}
import java.net.InetSocketAddress
import java.lang.Thread
import java.util.Scanner

eff UserCommands {
    def getCurrentCommand(): UserCommand
}

enum UserCommand {
    case ViewHomePage
    case ViewTodoList  
    case AddTodo(String)
    case ToggleTodo(String)
    case DeleteTodo(String)
    case UnknownCommand
}

enum Todo with Eq, ToString {
    case Todo(String, String, Bool) // id, text, completed
}

mod Todo {
    pub def getId(todo: Todo): String = match todo {
        case Todo(id, _, _) => id
    }

    pub def getText(todo: Todo): String = match todo {
        case Todo(_, text, _) => text
    }

    pub def isCompleted(todo: Todo): Bool = match todo {
        case Todo(_, _, completed) => completed
    }

    pub def toggle(todo: Todo): Todo = match todo {
        case Todo(id, text, completed) => Todo(id, text, not completed)
    }
}

eff TodoState {
    def getAllTodos(): List[Todo]
    def addTodo(text: String): Todo  
    def toggleTodo(id: String): Option[Todo]
    def deleteTodo(id: String): Bool
    def findTodo(id: String): Option[Todo]
}

enum AppState with ToString {
    case AppState(List[Todo])
}

eff View {
    def showMainPage(): Unit
    def showTodoList(todos: List[Todo]): Unit
    def showTodoItem(todo: Todo): Unit
    def showAddForm(): Unit
    def showError(message: String): Unit
    def showEmptyState(): Unit
}

eff HttpServer {
    def sendResponse(exchange: HttpExchange, response: HttpResponse): Unit
    def getRequestInfo(exchange: HttpExchange): (String, String, String)
}

enum HttpResponse {
    case Ok(String, Map[String, String])
    case Error(Int32, String)
}

eff Form {
    def getFormData(key: String): Option[String]
}

eff Navigation {
    def getCurrentRoute(): (String, String) // method, path
}

eff HtmxRenderer {
    def renderAsHtml(content: String): Unit
    def renderPartialHtml(content: String): Unit
}

def handleUserCommand(): Unit \ {TodoState, View, UserCommands} = {
    let command = UserCommands.getCurrentCommand();
    match command {
        case UserCommand.ViewHomePage => 
            View.showMainPage()
        
        case UserCommand.ViewTodoList => {
            let todos = TodoState.getAllTodos();
            View.showTodoList(todos)
        }
        
        case UserCommand.AddTodo(text) => {
            if (not String.isEmpty(String.trim(text))) {
                let todo = TodoState.addTodo(String.trim(text));
                View.showTodoItem(todo)
            } else {
                View.showError("Todo text cannot be empty")
            }
        }
        
        case UserCommand.ToggleTodo(todoId) => {
            let maybeTodo = TodoState.toggleTodo(todoId);
            match maybeTodo {
                case Some(todo) => View.showTodoItem(todo)
                case None => View.showError("Todo not found")
            }
        }
        
        case UserCommand.DeleteTodo(todoId) => {
            let _ = TodoState.deleteTodo(todoId);
            ()
        }
        
        case UserCommand.UnknownCommand => 
            View.showError("Unknown command")
    }
}

mod UserCommands {
    pub def handleWithHttp(method: String, path: String, formData: Map[String, String], 
                          f: Unit -> a \ ef): a \ (ef - UserCommands) =
        run {
            f()
        } with handler UserCommands {
            def getCurrentCommand(_, k) = {
                let command = parseHttpToCommand(method, path, formData);
                k(command)
            }
        }

    def parseHttpToCommand(method: String, path: String, formData: Map[String, String]): UserCommand = {
        match (method, path) {
            case ("GET", "/") => UserCommand.ViewHomePage
            case ("GET", "/todos") => UserCommand.ViewTodoList
            case ("POST", "/todos") => 
                match Map.get("text", formData) {
                    case Some(text) => UserCommand.AddTodo(text)
                    case None => UserCommand.UnknownCommand
                }
            case ("PUT", p) if String.startsWith(prefix="/todos/", p) => {
                let todoId = String.drop(7, p);
                UserCommand.ToggleTodo(todoId)
            }
            case ("DELETE", p) if String.startsWith(prefix="/todos/", p) => {
                let todoId = String.drop(7, p);
                UserCommand.DeleteTodo(todoId)
            }
            case _ => UserCommand.UnknownCommand
        }
    }

    pub def handleWithCli(args: List[String], f: Unit -> a \ ef): a \ (ef - UserCommands) =
        run {
            f()
        } with handler UserCommands {
            def getCurrentCommand(_, k) = {
                let command = parseCliToCommand(args);
                k(command)
            }
        }

    def parseCliToCommand(args: List[String]): UserCommand = match args {
        case "home" :: _ => UserCommand.ViewHomePage
        case "list" :: _ => UserCommand.ViewTodoList  
        case "add" :: text :: _ => UserCommand.AddTodo(text)
        case "toggle" :: id :: _ => UserCommand.ToggleTodo(id)
        case "delete" :: id :: _ => UserCommand.DeleteTodo(id)
        case _ => UserCommand.UnknownCommand
    }
}


mod Components {
    pub def mainPageHtml(): String = String.unlines(List#{
        "<!DOCTYPE html>",
        "<html lang='en'>",
        "<head>",
        "  <meta charset='UTF-8'>",
        "  <meta name='viewport' content='width=device-width, initial-scale=1.0'>",
        "  <title>Effect-Oriented Todo App</title>",
        "  <script src='https://unpkg.com/htmx.org@1.9.10'></script>",
        styles(),
        "</head>",
        "<body>",
        "  <div class='container'>",
        "    <h1>Effect-Oriented Todo App</h1>",
        "    <p class='subtitle'>UI as an Effect</p>",
        addFormHtml(),
        "    <div id='todo-list' hx-get='/todos' hx-trigger='load'>",
        "      Loading todos...",
        "    </div>",
        "  </div>",
        "</body>",
        "</html>"
    })

    pub def addFormHtml(): String = String.unlines(List#{
        "    <div class='add-form'>",
        "      <form class='input-group'",
        "            hx-post='/todos'",
        "            hx-target='#todo-list'",
        "            hx-swap='afterbegin'",
        "            hx-on::after-request='this.reset()'>",
        "        <input type='text' name='text' placeholder='What needs to be done?' required>",
        "        <button type='submit' class='btn'>Add Todo</button>",
        "      </form>",
        "    </div>"
    })

    pub def todoItemHtml(todo: Todo): String = {
        let id = Todo.getId(todo);
        let text = Todo.getText(todo);
        let completed = Todo.isCompleted(todo);
        let checkedAttr = if (completed) "checked" else "";
        let completedClass = if (completed) "completed" else "";

        String.unlines(List#{
            "<div class='todo-item ${completedClass}' id='todo-${id}'>",
            "  <input type='checkbox' ${checkedAttr}",
            "         hx-put='/todos/${id}'",
            "         hx-target='#todo-${id}'",
            "         hx-swap='outerHTML'>",
            "  <span class='todo-text ${completedClass}'>${text}</span>",
            "  <button class='delete-btn'",
            "          hx-delete='/todos/${id}'",
            "          hx-target='#todo-${id}'",
            "          hx-swap='outerHTML'",
            "          title='Delete todo'>",
            "    ✗",
            "  </button>",
            "</div>"
        })
    }

    pub def todoListHtml(todos: List[Todo]): String = {
        if (List.isEmpty(todos)) {
            emptyStateHtml()
        } else {
            let todoItems = List.map(todoItemHtml, List.reverse(todos));
            String.intercalate("\\", todoItems)
        }
    }

    pub def emptyStateHtml(): String = 
        "<div class='empty-state'>No todos yet. Add one above to get started!</div>"

    pub def errorHtml(message: String): String = 
        "<div class='error'>${message}</div>"

    def styles(): String = String.unlines(List#{
        "  <style>",
        "    body { font-family: 'Segoe UI', system-ui, sans-serif; margin: 0; padding: 0; background: #f8f9fa; }",
        "    .container { max-width: 600px; margin: 0 auto; padding: 2rem; }",
        "    h1 { color: #212529; margin-bottom: 0.5rem; text-align: center; }",
        "    .subtitle { text-align: center; color: #6c757d; margin-bottom: 2rem; }",
        "    .add-form { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 2rem; }",
        "    .input-group { display: flex; gap: 0.75rem; }",
        "    .input-group input { flex: 1; padding: 0.75rem; border: 2px solid #dee2e6; border-radius: 6px; font-size: 1rem; }",
        "    .input-group input:focus { outline: none; border-color: #0d6efd; }",
        "    .btn { padding: 0.75rem 1.5rem; background: #0d6efd; color: white; border: none; border-radius: 6px; font-size: 1rem; cursor: pointer; }",
        "    .btn:hover { background: #0b5ed7; }",
        "    .todo-item { background: white; border-radius: 8px; padding: 1rem; margin-bottom: 0.75rem; box-shadow: 0 2px 4px rgba(0,0,0,0.1); display: flex; align-items: center; gap: 0.75rem; }",
        "    .todo-item.completed { opacity: 0.7; }",
        "    .todo-text { flex: 1; font-size: 1rem; }",
        "    .todo-text.completed { text-decoration: line-through; color: #6c757d; }",
        "    .delete-btn { background: #dc3545; color: white; border: none; border-radius: 50%; width: 30px; height: 30px; cursor: pointer; display: flex; align-items: center; justify-content: center; }",
        "    .delete-btn:hover { background: #bb2d3b; }",
        "    .empty-state { text-align: center; color: #6c757d; padding: 3rem; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }",
        "    .error { color: #dc3545; padding: 1rem; background: #f8d7da; border: 1px solid #f5c2c7; border-radius: 6px; margin: 1rem 0; }",
        "  </style>"
    })
}


// =============================================================================
// EFFECT HANDLERS
// =============================================================================

mod TodoState {
    pub def handle(stateRef: Ref[AppState, r], f: Unit -> a \ ef): a \ (ef - TodoState + r) =
        run {
            f()
        } with handler TodoState {
            def getAllTodos(_, k) = {
                let AppState(todos) = Ref.get(stateRef);
                k(todos)
            }
            def addTodo(text, k) = {
                let AppState(todos) = Ref.get(stateRef);
                let id = Int64.toString(Random.randomInt64());
                let todo = Todo.Todo(id, text, false);
                let newState = AppState(todo :: todos);
                Ref.put(newState, stateRef);
                k(todo)
            }
            def toggleTodo(todoId, k) = {
                let AppState(todos) = Ref.get(stateRef);
                let (updatedTodo, newTodos) = toggleTodoInList(todoId, todos);
                Ref.put(AppState(newTodos), stateRef);
                k(updatedTodo)
            }
            def deleteTodo(todoId, k) = {
                let AppState(todos) = Ref.get(stateRef);
                let originalLen = List.length(todos);
                let newTodos = List.filter(todo -> Todo.getId(todo) != todoId, todos);
                let deleted = List.length(newTodos) < originalLen;
                Ref.put(AppState(newTodos), stateRef);
                k(deleted)
            }
            def findTodo(todoId, k) = {
                let AppState(todos) = Ref.get(stateRef);
                let found = List.find(todo -> Todo.getId(todo) == todoId, todos);
                k(found)
            }
        }

    def toggleTodoInList(todoId: String, todos: List[Todo]): (Option[Todo], List[Todo]) = {
        def helper(remaining, found, acc) = match remaining {
            case Nil => (found, List.reverse(acc))
            case todo :: rest => 
                if (Todo.getId(todo) == todoId) {
                    let toggled = Todo.toggle(todo);
                    helper(rest, Some(toggled), toggled :: acc)
                } else {
                    helper(rest, found, todo :: acc)
                }
        };
        helper(todos, None, Nil)
    }
}

/// Handler that interprets View effects as HTMX/HTML responses
mod View {
    pub def handleWithHtmx(f: Unit -> a \ ef): a \ (ef - View + HtmxRenderer) =
        run {
            f()
        } with handler View {
            def showMainPage(_, k) = {
                HtmxRenderer.renderAsHtml(Components.mainPageHtml());
                k()
            }
            def showTodoList(todos, k) = {
                HtmxRenderer.renderPartialHtml(Components.todoListHtml(todos));
                k()
            }
            def showTodoItem(todo, k) = {
                HtmxRenderer.renderPartialHtml(Components.todoItemHtml(todo));
                k()
            }
            def showAddForm(_, k) = {
                HtmxRenderer.renderPartialHtml(Components.addFormHtml());
                k()
            }
            def showError(message, k) = {
                HtmxRenderer.renderPartialHtml(Components.errorHtml(message));
                k()
            }
            def showEmptyState(_, k) = {
                HtmxRenderer.renderPartialHtml(Components.emptyStateHtml());
                k()
            }
        }
}

mod Form {
    pub def handleWithHttp(requestBody: String, f: Unit -> a \ ef): a \ (ef - Form) =
        run {
            f()
        } with handler Form {
            def getFormData(key, k) = {
                let result = parseFormData(requestBody, key);
                k(result)
            }
        }

    def parseFormData(body: String, key: String): Option[String] = {
        let pairs = String.split(regex="&", body);
        let keyValue = List.findLeft(pair -> String.startsWith(prefix="${key}=", pair), pairs);
        match keyValue {
            case Some(kv) =>
                let value = String.drop(String.length(key) + 1, kv);
                Some(String.replace(src="+", dst=" ", value))
            case None => None
        }
    }
}

mod Navigation {
    pub def handleWithHttp(method: String, path: String, f: Unit -> a \ ef): a \ (ef - Navigation) =
        run {
            f()
        } with handler Navigation {
            def getCurrentRoute(_, k) = k((method, path))
        }
}

mod HtmxRenderer {
    // def htmlHeaders(): Map[String, String] = 
    //     Map{"Content-Type" => "text/html; charset=utf-8"}

    pub def handleWithHttp(exchange: HttpExchange, f: Unit -> a \ ef): a \ (ef - HtmxRenderer + IO) =
        run {
            f()
        } with handler HtmxRenderer {
            def renderAsHtml(content, k) = {
                writeHttpResponse(exchange, HttpResponse.Ok(content, htmlHeaders()));
                k()
            }
            def renderPartialHtml(content, k) = {
                writeHttpResponse(exchange, HttpResponse.Ok(content, htmlHeaders()));
                k()
            }
        }

    def writeHttpResponse(exchange: HttpExchange, response: HttpResponse): Unit \\ IO = {
        match response {
            case HttpResponse.Ok(content, headers) => {
                Map.forEach(key -> value -> exchange.getResponseHeaders().set(key, value), headers);
                let responseBytes = content.getBytes();
                exchange.sendResponseHeaders(200, Int32.toInt64(Array.length(responseBytes)));
                let outputStream = exchange.getResponseBody();
                outputStream.write(responseBytes);
                outputStream.close()
            }
            case HttpResponse.Error(code, message) => {
                let responseBytes = message.getBytes();
                exchange.sendResponseHeaders(code, Int32.toInt64(Array.length(responseBytes)));
                let outputStream = exchange.getResponseBody();
                outputStream.write(responseBytes);
                outputStream.close()
            }
        };
        exchange.close()
    }
}

mod HttpServer {
    pub def handle(f: Unit -> a \ ef): a \ (ef - HttpServer + IO) =
        run {
            f()
        } with handler HttpServer {
            def getRequestInfo(exchange, k) = {
                let method = exchange.getRequestMethod();
                let path = exchange.getRequestURI().getPath();
                let body = readRequestBody(exchange);
                k((method, path, body))
            }
            def sendResponse(exchange, response, k) = {
                HtmxRenderer.writeHttpResponse(exchange, response);
                k()
            }
        }

    def readRequestBody(exchange: HttpExchange): String \\ IO = {
        let inputStream = exchange.getRequestBody();
        let scanner = new Scanner(inputStream);
        if (scanner.hasNext()) scanner.useDelimiter(\"\\\\A\").next() else \"\"
    }
}

// =============================================================================
// REQUEST PROCESSING
// =============================================================================

/// Process HTTP request by composing all effect handlers
def processRequest(exchange: HttpExchange): Unit \ {Random, TodoState, IO} = {
    let (method, path, body) = (exchange.getRequestMethod(), exchange.getRequestURI().getPath(), \"\");
    
    run {
        handleRoute()
    } with Navigation.handleWithHttp(method, path)
      with Form.handleWithHttp(body)
      with View.handleWithHtmx
      with HtmxRenderer.handleWithHttp(exchange)
}

// =============================================================================
// SERVER INFRASTRUCTURE
// =============================================================================

def startServer(port: Int32): Unit \ {IO, Net} = {
    let addr = new InetSocketAddress(port);
    let server = JavaHttpServer.create(addr, 0);
    server.createContext(\"/\", createHandler());
    server.start()
}

def createHandler(): HttpHandler \ IO = new HttpHandler {
    def $handle(_this: HttpHandler, exchange: HttpExchange): Unit \\ IO = {
        processRequest(exchange)
    }
}

def initialState(): AppState = AppState(List#{
    Todo.Todo("1", "Learn UI effects", false),
    Todo.Todo("2", "Separate concerns", false),
    Todo.Todo("3", "Build with effects", false)
})

// =============================================================================
// MAIN APPLICATION
// =============================================================================

def main(): Unit \ {IO, Net, NonDet} =
    region rc {
        let stateRef = Ref.fresh(rc, initialState());
        
        run {
            Logger.info(\"Starting Effect-Oriented Todo server (UI as Effect) on port 8080...\");
            startServer(8080);
            Logger.info(\"Server ready! Visit http://localhost:8080\");
            
            let currentThread = Thread.currentThread();
            unsafe currentThread.join()
            
        } with TodoState.handle(stateRef)
          with Logger.runWithIO
          with Random.runWithIO
    }