mod TodoStorageHandler {
    pub def runWithState(stateRef: Ref[List[Todo], r], f: Unit -> a \ ef): a \ ef - {TodoStorage} + r =
        run {
            f()
        } with handler TodoStorage {
            def getAllTodos(_, resume) = 
                let todos = Ref.get(stateRef);
                resume(todos)
            
            def saveTodos(todos, resume) = {
                Ref.put(todos, stateRef);
                resume()
            }
        }
}

mod TodoViewHandler {
    import com.sun.net.httpserver.HttpExchange
    
    pub def runWithString(f: Unit -> a \ ef): a \ ef - {TodoView} = {
        run {
            f()
        } with handler TodoView {
            def showHomePage(_, resume) = {
                let content = ViewComponents.homePage();
                resume(content)
            }
            
            def showTodoList(todos, resume) = {
                let content = ViewComponents.todoList(todos);
                resume(content)
            }
            
            def showError(error, resume) = {
                let content = ViewComponents.errorMessage(error);
                resume(content)
            }
            
            def showSuccess(message, resume) = {
                let content = ViewComponents.successMessage(message);
                resume(content)
            }
        }
    }
}

mod TodoConfigHandler {
    pub def runWithHardCoded(f: Unit -> a \ ef): a \ ef - {TodoConfig} + {} =
        run {
            f()
        } with handler TodoConfig {
            def init(_, resume) = resume(AppConfig.webApp(8080))
            def getInitialTodos(config, resume) = 
                resume(AppConfig.getInitialTodos(config))
        }
}