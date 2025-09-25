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
        "    <p class='subtitle'>Clean Architecture with Flix</p>",
        "    <div id='error-container'></div>", // Error container for HTMX targeting
        addFormHtml(),
        "    <div id='todo-list' hx-get='/todos' hx-trigger='load'>",
        "      Loading todos...",
        "    </div>",
        "  </div>",
        "</body>",
        "</html>"
    })
}

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

