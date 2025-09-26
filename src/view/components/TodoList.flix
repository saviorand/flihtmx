mod ViewComponents {
    pub def todoList(todos: List[Todo]): String = {
        if (List.isEmpty(todos)) {
            "<div class='empty-state'>No todos found. Add one above to get started!</div>"
        } else {
            let items = List.map(ViewComponents.todoItem, todos);
            let itemsHtml = String.unlines(items);
            itemsHtml
        }
    }
    
    pub def activeTodoList(todos: List[Todo]): String = {
        let activeTodos = List.filter(todo -> not Todo.isCompleted(todo), todos);
        if (List.isEmpty(activeTodos)) {
            "<div class='empty-state'>No active todos! 🎉</div>"
        } else {
            let items = List.map(ViewComponents.todoItem, activeTodos);
            String.unlines(items)
        }
    }

    pub def completedTodoList(todos: List[Todo]): String = {
        let completedTodos = List.filter(Todo.isCompleted, todos);
        if (List.isEmpty(completedTodos)) {
            "<div class='empty-state'>No completed todos yet.</div>"
        } else {
            let items = List.map(ViewComponents.todoItem, completedTodos);
            String.unlines(items)
        }
    }
}