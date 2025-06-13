// main.rs

// Import necessary modules from axum and tokio
use axum::{
    routing::get, // For defining GET routes
    Router,       // For building the application router
};
use tokio::net::TcpListener; // For listening for incoming TCP connections

#[tokio::main] // Marks the main function as an asynchronous entry point
async fn main() {
    // Build our application with a single route.
    // The `get("/")` defines a GET request handler for the root path "/".
    // `handler` is the asynchronous function that will be called when this route is hit.
    let app = Router::new().route("/", get(handler));

    // Get the port from the environment variable provided by Render (or default to 3000 locally).
    // Render typically exposes your application on the PORT environment variable.
    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string()) // Default to 3000 if PORT is not set
        .parse::<u16>()                         // Parse the string to a u16 integer
        .expect("PORT must be a valid u16 number"); // Panic if parsing fails

    // Construct the address to bind to. "0.0.0.0" makes the server accessible from outside
    // the container, which is necessary for Render.
    let addr = format!("0.0.0.0:{}", port);
    let listener = TcpListener::bind(&addr)
        .await // Await the binding operation
        .expect(&format!("Failed to bind to {}", addr)); // Panic if binding fails

    println!("listening on {}", listener.local_addr().unwrap()); // Print the address the server is listening on

    // Start the axum server with the defined application and listener.
    // The `serve` method takes the listener and the application, and starts handling requests.
    axum::serve(listener, app)
        .await // Await the server to run
        .expect("Server failed to start"); // Panic if the server encounters an error
}

// Asynchronous handler function for the root route.
// This function returns a simple string response.
async fn handler() -> &'static str {
    "Hello, Render API from Rust!" // The response string
}