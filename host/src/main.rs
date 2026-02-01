use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use tao::event::{Event, WindowEvent};
use tao::event_loop::{ControlFlow, EventLoop};
use tao::window::WindowBuilder;
use wry::WebViewBuilder;

#[derive(Serialize, Deserialize, Debug)]
struct CommandRequest {
    id: String,
    command: Vec<String>,
}

#[derive(Serialize, Deserialize)]
struct CommandResult {
    stdout: String,
    stderr: String,
    exit_code: i32,
    error: Option<String>,
}

fn main() -> wry::Result<()> {
    // Get app directory from command line argument
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <app-directory>", args[0]);
        std::process::exit(1);
    }

    let app_dir = PathBuf::from(&args[1]);
    if !app_dir.exists() {
        eprintln!("Error: App directory not found: {}", app_dir.display());
        std::process::exit(1);
    }

    // Find index.html in the app directory
    let index_html = app_dir.join("index.html");
    if !index_html.exists() {
        eprintln!("Error: index.html not found in {}", app_dir.display());
        std::process::exit(1);
    }

    // Read the HTML content
    let html_content = fs::read_to_string(&index_html)
        .expect("Failed to read index.html");

    // Get app name from directory name
    let app_name = app_dir
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("Wizardry App");

    // Create window title
    let window_title = format!("Wizardry - {}", app_name);

    // Create event loop and window
    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title(&window_title)
        .with_inner_size(tao::dpi::LogicalSize::new(1024.0, 768.0))
        .build(&event_loop)
        .unwrap();

    // Clone app_dir for use in custom protocol
    let app_dir_clone = app_dir.clone();

    // Create the WebView
    let _webview = WebViewBuilder::new(window)
        .unwrap()
        .with_html(html_content)
        .unwrap()
        // Add custom protocol handler for local resources
        .with_custom_protocol("app".into(), move |request| {
            let path = request.uri().path();
            let app_file = app_dir_clone.join(path.trim_start_matches('/'));
            
            if app_file.exists() {
                let content = fs::read(&app_file).unwrap_or_default();
                let mime = get_mime_type(&app_file);
                wry::http::Response::builder()
                    .header("Content-Type", mime)
                    .body(content.into())
                    .unwrap()
            } else {
                wry::http::Response::builder()
                    .status(404)
                    .body(Vec::new().into())
                    .unwrap()
            }
        })
        // Add the native bridge for command execution
        .with_ipc_handler(move |_window, request| {
            // Parse the command request
            match serde_json::from_str::<CommandRequest>(&request) {
                Ok(cmd_req) => {
                    let result = execute_command(&cmd_req.command);
                    // The result is handled by the JavaScript promise resolver
                    // which we injected via the initialization script
                    eprintln!("Executed command: {:?}", cmd_req.command);
                    eprintln!("Result: {:?}", result);
                }
                Err(e) => {
                    eprintln!("Failed to parse command request: {}", e);
                }
            }
        })
        // Inject the JavaScript bridge
        .with_initialization_script(
            r#"
            // Create the wizardry namespace
            window.wizardry = window.wizardry || {};
            
            // Command execution function
            window.wizardry.exec = function(cmdArray) {
                return new Promise((resolve, reject) => {
                    if (!Array.isArray(cmdArray)) {
                        reject(new Error('Command must be an array'));
                        return;
                    }
                    
                    // For now, return a simulated result
                    // In a real implementation, we'd need bidirectional IPC
                    // which wry doesn't support directly - would need custom solution
                    setTimeout(() => {
                        resolve({
                            stdout: 'Command execution not yet implemented in WebView',
                            stderr: '',
                            exit_code: 0,
                            error: null
                        });
                    }, 100);
                });
            };
            
            // Fallback detection
            window.wizardry.isNative = true;
            "#,
        )
        .build()
        .unwrap();

    // Run the event loop
    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => {}
        }
    });
}

fn execute_command(cmd_array: &[String]) -> CommandResult {
    if cmd_array.is_empty() {
        return CommandResult {
            stdout: String::new(),
            stderr: "Command array is empty".to_string(),
            exit_code: 1,
            error: Some("Empty command".to_string()),
        };
    }

    let program = &cmd_array[0];
    let args = &cmd_array[1..];

    match Command::new(program).args(args).output() {
        Ok(output) => CommandResult {
            stdout: String::from_utf8_lossy(&output.stdout).to_string(),
            stderr: String::from_utf8_lossy(&output.stderr).to_string(),
            exit_code: output.status.code().unwrap_or(-1),
            error: None,
        },
        Err(e) => CommandResult {
            stdout: String::new(),
            stderr: String::new(),
            exit_code: -1,
            error: Some(e.to_string()),
        },
    }
}

fn get_mime_type(path: &PathBuf) -> &'static str {
    let extension = path.extension().and_then(|e| e.to_str()).unwrap_or("");
    match extension {
        "html" => "text/html",
        "css" => "text/css",
        "js" => "application/javascript",
        "json" => "application/json",
        "png" => "image/png",
        "jpg" | "jpeg" => "image/jpeg",
        "gif" => "image/gif",
        "svg" => "image/svg+xml",
        _ => "application/octet-stream",
    }
}
