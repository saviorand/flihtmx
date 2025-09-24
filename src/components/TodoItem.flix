mod Components {
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
}