enum AppMode with Eq, ToString {
    case WebApp(Int32),
    case TestMode
}

enum AppConfig with ToString {
    case AppConfig(AppMode, List[Todo])
}

mod AppConfig {
    pub def webApp(port: Int32): AppConfig = 
        AppConfig(AppMode.WebApp(port), defaultTodos())
    
    pub def testMode(todos: List[Todo]): AppConfig = 
        AppConfig(AppMode.TestMode, todos)
    
    pub def getMode(config: AppConfig): AppMode = 
        let AppConfig(mode, _) = config;
        mode
    
    pub def getInitialTodos(config: AppConfig): List[Todo] = 
        let AppConfig(_, todos) = config;
        todos
    
    def defaultTodos(): List[Todo] = List#{
        Todo.create(TodoId.TodoId("demo-1"), TodoText.TodoText("Learn effect-oriented programming")),
        Todo.create(TodoId.TodoId("demo-2"), TodoText.TodoText("Build a todo app")),  
        Todo.create(TodoId.TodoId("demo-3"), TodoText.TodoText("Master HTMX integration"))
    }
}