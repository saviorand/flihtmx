enum TodoId with Eq, Order, ToString {
    case TodoId(String)
}

enum TodoText with Eq, ToString {
    case TodoText(String)
}

enum TodoStatus with Eq, ToString {
    case Active,
    case Completed
}

enum Todo with Eq, ToString {
    case Todo(TodoId, TodoText, TodoStatus)
}

mod Todo {
    pub def create(id: TodoId, text: TodoText): Todo = 
        Todo(id, text, TodoStatus.Active)
    
    pub def getId(todo: Todo): TodoId = 
        let Todo(id, _, _) = todo;
        id
    
    pub def getText(todo: Todo): TodoText = 
        let Todo(_, text, _) = todo;
        text
    
    pub def getStatus(todo: Todo): TodoStatus = 
        let Todo(_, _, status) = todo;
        status
    
    pub def isCompleted(todo: Todo): Bool = 
        getStatus(todo) == TodoStatus.Completed
    
    pub def toggle(todo: Todo): Todo = 
        let Todo(id, text, status) = todo;
        let newStatus = match status {
            case TodoStatus.Active => TodoStatus.Completed
            case TodoStatus.Completed => TodoStatus.Active
        };
        Todo(id, text, newStatus)
    
    pub def complete(todo: Todo): Todo = 
        let Todo(id, text, _) = todo;
        Todo(id, text, TodoStatus.Completed)
    
    pub def activate(todo: Todo): Todo = 
        let Todo(id, text, _) = todo;
        Todo(id, text, TodoStatus.Active)
}

mod TodoService {
    import java.util.UUID;
    
    pub def addTodo(text: String, todos: List[Todo]): Result[TodoError, (Todo, List[Todo])] \ IO =
        forM(
            validText <- TodoValidation.validateText(text) |> Result.mapErr(TodoError.ValidationError);
            newId <- generateUniqueId(todos)
        ) yield {
            let newTodo = Todo.create(newId, validText);
            (newTodo, newTodo :: todos)
        }
    
    pub def updateTodo(idStr: String, updateFn: Todo -> Todo, todos: List[Todo]): Result[TodoError, (Option[Todo], List[Todo])] =
        match TodoValidation.validateId(idStr) {
            case Ok(validId) => Ok(updateTodoInList(validId, updateFn, todos))
            case Err(e) => Err(TodoError.ValidationError(e))
        }

    pub def deleteTodo(idStr: String, todos: List[Todo]): Result[TodoError, List[Todo]] =
        match TodoValidation.validateId(idStr) {
            case Ok(validId) => 
                let filtered = List.filter(todo -> Todo.getId(todo) != validId, todos);
                if (List.length(filtered) == List.length(todos))
                    Err(TodoError.TodoNotFound(validId))
                else
                    Ok(filtered)
            case Err(e) => Err(TodoError.ValidationError(e))
        }

    pub def findTodo(idStr: String, todos: List[Todo]): Result[TodoError, Todo] =
        match TodoValidation.validateId(idStr) {
            case Ok(validId) => 
                match List.find(todo -> Todo.getId(todo) == validId, todos) {
                    case Some(todo) => Ok(todo)
                    case None => Err(TodoError.TodoNotFound(validId))
                }
            case Err(e) => Err(TodoError.ValidationError(e))
        }
    
    pub def getActiveTodos(todos: List[Todo]): List[Todo] =
        List.filter(todo -> not Todo.isCompleted(todo), todos)
    
    pub def getCompletedTodos(todos: List[Todo]): List[Todo] =
        List.filter(Todo.isCompleted, todos)
    
    def generateUniqueId(todos: List[Todo]): Result[TodoError, TodoId] \ IO =
        let existingIds = List.map(Todo.getId, todos) |> List.toSet;
        let newId = generateId();
        if (Set.memberOf(newId, existingIds))
            generateUniqueId(todos) // Retry if collision
        else
            Ok(newId)
    
    def generateId(): TodoId \ IO =  // Add IO effect
        let uuid = UUID.randomUUID();
        TodoId.TodoId(uuid.toString())
    
    def updateTodoInList(targetId: TodoId, updateFn: Todo -> Todo, todos: List[Todo]): (Option[Todo], List[Todo]) =
        def helper(remaining, updated, acc) = match remaining {
            case Nil => (updated, List.reverse(acc))
            case todo :: rest => 
                if (Todo.getId(todo) == targetId) {
                    let updatedTodo = updateFn(todo);
                    helper(rest, Some(updatedTodo), updatedTodo :: acc)
                } else {
                    helper(rest, updated, todo :: acc)
                }
        };
        helper(todos, None, Nil)
}

mod TodoValidation {
    pub def validateText(text: String): Result[ValidationError, TodoText] =
        let trimmed = String.trim(text);
        if (String.isEmpty(trimmed))
            Err(ValidationError.EmptyText)
        else if (String.length(trimmed) > 500)
            Err(ValidationError.TextTooLong(String.length(trimmed)))
        else if (containsInvalidChars(trimmed))
            Err(ValidationError.TextContainsInvalidChars)
        else
            Ok(TodoText.TodoText(trimmed))
    
    pub def validateId(id: String): Result[ValidationError, TodoId] =
        let trimmed = String.trim(id);
        if (String.isEmpty(trimmed))
            Err(ValidationError.InvalidId(id))
        else if (not isValidIdFormat(trimmed))
            Err(ValidationError.InvalidId(id))
        else
            Ok(TodoId.TodoId(trimmed))
    
    def containsInvalidChars(text: String): Bool =
        String.contains(substr="<", text) or 
        String.contains(substr=">", text) or
        String.contains(substr="&", text)
    
    def isValidIdFormat(id: String): Bool =
        String.forAll(c -> Char.isLetterOrDigit(c) or c == '-', id)
}

enum TodoError with Eq {
    case ValidationError(ValidationError),
    case TodoNotFound(TodoId),
    case DuplicateTodo(TodoId),
    case StorageError(String)
}

enum ValidationError with Eq {
    case EmptyText,
    case TextTooLong(Int32),
    case TextContainsInvalidChars,
    case InvalidId(String)
}

instance ToString[ValidationError] {
    pub def toString(e: ValidationError): String = match e {
        case ValidationError.EmptyText => 
            "Please enter some text for your todo item."
        case ValidationError.TextTooLong(len) => 
            "Todo text is too long (${len} characters). Please keep it under 500 characters."
        case ValidationError.TextContainsInvalidChars => 
            "Todo text contains invalid characters. Please avoid using <, >, and & symbols."
        case ValidationError.InvalidId(id) => 
            "Invalid todo ID: ${id}"
    }
}

instance ToString[TodoError] {
    pub def toString(e: TodoError): String = match e {
        case TodoError.ValidationError(ve) => 
            ToString.toString(ve)
        case TodoError.TodoNotFound(TodoId.TodoId(id)) => 
            "Todo item with ID '${id}' was not found."
        case TodoError.DuplicateTodo(TodoId.TodoId(id)) => 
            "A todo item with ID '${id}' already exists."
        case TodoError.StorageError(msg) => 
            "Storage error: ${msg}"
    }
}