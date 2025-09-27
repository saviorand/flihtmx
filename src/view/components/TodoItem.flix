mod ViewComponents {
    pub def todoItem(todo: Todo): String = {
        let Todo.Todo(id, text, status) = todo;
        let TodoId.TodoId(idStr) = id;
        let TodoText.TodoText(textStr) = text;
        let completedClass = match status {
            case TodoStatus.Completed => " completed"
            case TodoStatus.Active => ""
        };
        let statusButton = match status {
            case TodoStatus.Completed => "Mark Active"
            case TodoStatus.Active => "Mark Complete"
        };
        
        String.unlines(List#{
            "<div class='todo-item${completedClass}'>",
            "    <span class='todo-text'>${View.escapeHtml(textStr)}</span>",
            "    <div class='todo-actions'>",
            "        <button class='btn btn-secondary' hx-put='/todos/${idStr}' hx-target='#todo-container'>",
            "            ${statusButton}",
            "        </button>",
            "        <button class='btn btn-danger' hx-delete='/todos/${idStr}' hx-target='#todo-container' hx-confirm='Delete this todo?'>",
            "            Delete",
            "        </button>",
            "    </div>",
            "</div>"
        })
    }
}