# Effect-Oriented Todo App

A web-based todo application built with Flix and HTMX that demonstrates effect-oriented programming principles.

## Overview

This project showcases how to build a web application using Flix's algebraic effects and handlers to cleanly separate pure business logic from side effects. The architecture demonstrates effect-oriented programming where:

- Pure business logic resides in the functional core
- Side effects are captured by algebraic effects
- Effect handlers manage the imperative shell
- All mutable state is scoped using regions

## Architecture

The application follows effect-oriented design principles:

**Effects:**
- `TodoStorage` - Data persistence operations
- `TodoView` - UI rendering operations  
- `TodoConfig` - Configuration access

**Handlers:**
- `TodoStorageHandler` - Manages in-memory state using regions
- `TodoViewHandler` - Renders HTML components
- `TodoConfigHandler` - Provides initial configuration

**Pure Core:**
- `TodoService` - Business logic (validation, CRUD operations)
- `Todo` - Domain types and operations
- View components - Pure HTML generation functions

## Features

- Create, read, update, and delete todos
- Filter todos by status (all, active, completed)
- Clear completed todos
- Persistent state during session
- Responsive web interface with HTMX

## Technical Stack

- **Backend:** Flix with built-in HTTP server
- **Frontend:** HTMX for dynamic updates
- **Styling:** CSS for responsive design
- **Memory Management:** Region-based scoped memory

## Running the Application

1. Ensure you have Flix installed (requires Java 21+)
2. Clone this repository
3. Run: `flix run`
4. Open `http://localhost:8080` in your browser

## Key Concepts Demonstrated

- **Effect-Oriented Programming:** Separation of pure and effectful code
- **Algebraic Effects:** User-defined effects with handlers
- **Region-Based Memory:** Safe mutable memory management
- **Functional Core, Imperative Shell:** Clean architecture pattern
- **Type and Effect Safety:** Compile-time guarantees about side effects

This example illustrates how effect-oriented programming enables building maintainable web applications with clear separation of concerns and strong safety guarantees.