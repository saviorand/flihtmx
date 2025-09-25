mod UserInput {
    pub def handleWithHttp(method: String, path: String, formData: Map[String, String], 
                          f: Unit -> a \ ef): a \ (ef - UserInput) =
        run {
            f()
        } with handler UserInput {
            def getCommand(_, k) = {
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
}
