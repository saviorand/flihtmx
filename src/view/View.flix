mod View {
    import com.sun.net.httpserver.HttpExchange
    
    pub def handleWithHtmx(exchange: HttpExchange, f: Unit -> a \ ef): a \ (ef - View + IO) =
        run {
            f()
        } with handler View {
            def renderMainPage(_, k) = {
                writeHtmxResponse(exchange, Components.mainPageHtml(), htmlHeaders());
                k()
            }
            def renderTodoList(todos, k) = {
                let content = Components.todoListHtml(todos);
                let headers = if (isHtmxRequest(exchange)) {
                    Map.union(htmlHeaders(), Map#{
                        "HX-Trigger" => "todoListUpdated"
                    })
                } else {
                    htmlHeaders()
                };
                writeHtmxResponse(exchange, content, headers);
                k()
            }
            def renderTodoItem(todo, k) = {
                let content = Components.todoItemHtml(todo);
                let headers = if (isHtmxRequest(exchange)) {
                    Map.union(htmlHeaders(), Map#{
                        "HX-Trigger" => "todoItemUpdated"
                    })
                } else {
                    htmlHeaders()
                };
                writeHtmxResponse(exchange, content, headers);
                k()
            }
            def renderError(message, k) = {
                let content = Components.errorHtml(message);
                let headers = if (isHtmxRequest(exchange)) {
                    Map.union(htmlHeaders(), Map#{
                        "HX-Reswap" => "innerHTML",
                        "HX-Retarget" => "#error-container"
                    })
                } else {
                    htmlHeaders()
                };
                writeHtmxResponse(exchange, content, headers);
                k()
            }
        }

    def isHtmxRequest(exchange: HttpExchange): Bool \ IO = {
        let headers = exchange.getRequestHeaders();
        let htmxHeader = headers.getFirst("HX-Request");
        not Object.isNull(htmxHeader)
    }

    def writeHtmxResponse(exchange: HttpExchange, content: String, headers: Map[String, String]): Unit \ IO = {
        Map.forEach(key -> value -> exchange.getResponseHeaders().set(key, value), headers);
        let responseBytes = content.getBytes();
        exchange.sendResponseHeaders(200, Int32.toInt64(Array.length(responseBytes)));
        let outputStream = exchange.getResponseBody();
        outputStream.write(responseBytes);
        outputStream.close();
        exchange.close()
    }
}

