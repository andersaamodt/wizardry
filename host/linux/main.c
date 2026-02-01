// Wizardry Desktop Host - Linux native WebView wrapper
// Minimal C implementation using GTK3 + WebKit2GTK
// Build: gcc -O2 main.c -o wizardry-host `pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.0`

#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

typedef struct {
    WebKitWebView *web_view;
    char *app_path;
} AppData;

// Escape string for JSON
char* escape_json(const char *str) {
    if (!str) return strdup("");
    
    size_t len = strlen(str);
    char *escaped = malloc(len * 2 + 1);  // Worst case: all chars need escaping
    char *p = escaped;
    
    for (size_t i = 0; i < len; i++) {
        switch (str[i]) {
            case '\\': *p++ = '\\'; *p++ = '\\'; break;
            case '"':  *p++ = '\\'; *p++ = '"'; break;
            case '\n': *p++ = '\\'; *p++ = 'n'; break;
            case '\r': *p++ = '\\'; *p++ = 'r'; break;
            case '\t': *p++ = '\\'; *p++ = 't'; break;
            default:   *p++ = str[i]; break;
        }
    }
    *p = '\0';
    return escaped;
}

// Execute command and capture output
void execute_command(const char **argv, char **stdout_str, char **stderr_str, int *exit_code) {
    int stdout_pipe[2], stderr_pipe[2];
    pipe(stdout_pipe);
    pipe(stderr_pipe);
    
    pid_t pid = fork();
    if (pid == 0) {
        // Child process
        close(stdout_pipe[0]);
        close(stderr_pipe[0]);
        dup2(stdout_pipe[1], STDOUT_FILENO);
        dup2(stderr_pipe[1], STDERR_FILENO);
        close(stdout_pipe[1]);
        close(stderr_pipe[1]);
        
        execvp(argv[0], (char **)argv);
        perror("execvp failed");
        exit(127);
    }
    
    // Parent process
    close(stdout_pipe[1]);
    close(stderr_pipe[1]);
    
    // Read stdout
    char stdout_buf[4096];
    ssize_t stdout_len = read(stdout_pipe[0], stdout_buf, sizeof(stdout_buf) - 1);
    if (stdout_len > 0) {
        stdout_buf[stdout_len] = '\0';
        *stdout_str = strdup(stdout_buf);
    } else {
        *stdout_str = strdup("");
    }
    close(stdout_pipe[0]);
    
    // Read stderr
    char stderr_buf[4096];
    ssize_t stderr_len = read(stderr_pipe[0], stderr_buf, sizeof(stderr_buf) - 1);
    if (stderr_len > 0) {
        stderr_buf[stderr_len] = '\0';
        *stderr_str = strdup(stderr_buf);
    } else {
        *stderr_str = strdup("");
    }
    close(stderr_pipe[0]);
    
    // Wait for child
    int status;
    waitpid(pid, &status, 0);
    *exit_code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

// Handle messages from JavaScript
static void message_received_cb(WebKitUserContentManager *manager,
                                 WebKitJavascriptResult *js_result,
                                 gpointer user_data)
{
    AppData *app_data = (AppData *)user_data;
    
    JSCValue *value = webkit_javascript_result_get_js_value(js_result);
    
    // Parse the message { id: "...", command: ["cmd", "arg1", "arg2"] }
    if (!jsc_value_is_object(value)) {
        g_warning("Message is not an object");
        return;
    }
    
    JSCValue *id_val = jsc_value_object_get_property(value, "id");
    JSCValue *cmd_val = jsc_value_object_get_property(value, "command");
    
    if (!jsc_value_is_string(id_val) || !jsc_value_is_array(cmd_val)) {
        g_warning("Invalid message format");
        g_object_unref(id_val);
        g_object_unref(cmd_val);
        return;
    }
    
    char *msg_id = jsc_value_to_string(id_val);
    
    // Convert JSArray to C array
    int cmd_len = jsc_value_to_int32(jsc_value_object_get_property(cmd_val, "length"));
    if (cmd_len == 0) {
        g_warning("Command array is empty");
        g_free(msg_id);
        g_object_unref(id_val);
        g_object_unref(cmd_val);
        return;
    }
    
    const char **argv = malloc((cmd_len + 1) * sizeof(char *));
    for (int i = 0; i < cmd_len; i++) {
        char idx_str[16];
        snprintf(idx_str, sizeof(idx_str), "%d", i);
        JSCValue *elem = jsc_value_object_get_property(cmd_val, idx_str);
        argv[i] = jsc_value_to_string(elem);
        g_object_unref(elem);
    }
    argv[cmd_len] = NULL;
    
    // Execute command
    char *stdout_str, *stderr_str;
    int exit_code;
    execute_command(argv, &stdout_str, &stderr_str, &exit_code);
    
    // Escape strings for JSON
    char *esc_stdout = escape_json(stdout_str);
    char *esc_stderr = escape_json(stderr_str);
    
    // Build JavaScript callback
    char *js_code = g_strdup_printf(
        "if (window.__wizardry_callbacks && window.__wizardry_callbacks['%s']) { "
        "  window.__wizardry_callbacks['%s']({ "
        "    stdout: \"%s\", "
        "    stderr: \"%s\", "
        "    exit_code: %d, "
        "    error: null "
        "  }); "
        "  delete window.__wizardry_callbacks['%s']; "
        "}",
        msg_id, msg_id, esc_stdout, esc_stderr, exit_code, msg_id);
    
    webkit_web_view_run_javascript(app_data->web_view, js_code, NULL, NULL, NULL);
    
    // Cleanup
    free(stdout_str);
    free(stderr_str);
    free(esc_stdout);
    free(esc_stderr);
    g_free(js_code);
    g_free(msg_id);
    for (int i = 0; i < cmd_len; i++) {
        g_free((void *)argv[i]);
    }
    free(argv);
    g_object_unref(id_val);
    g_object_unref(cmd_val);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <app-directory>\n", argv[0]);
        return 1;
    }
    
    char *app_path = argv[1];
    char index_path[1024];
    snprintf(index_path, sizeof(index_path), "%s/index.html", app_path);
    
    // Check if index.html exists
    if (access(index_path, F_OK) != 0) {
        fprintf(stderr, "Error: index.html not found at %s\n", index_path);
        return 1;
    }
    
    // Get app name from directory
    char *app_name = strrchr(app_path, '/');
    app_name = app_name ? app_name + 1 : app_path;
    
    gtk_init(&argc, &argv);
    
    // Create window
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    char title[256];
    snprintf(title, sizeof(title), "Wizardry - %s", app_name);
    gtk_window_set_title(GTK_WINDOW(window), title);
    gtk_window_set_default_size(GTK_WINDOW(window), 1024, 768);
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    
    // Create WebView with message handler
    WebKitUserContentManager *content_manager = webkit_user_content_manager_new();
    webkit_user_content_manager_register_script_message_handler(content_manager, "wizardry");
    
    AppData *app_data = malloc(sizeof(AppData));
    app_data->app_path = app_path;
    
    g_signal_connect(content_manager, "script-message-received::wizardry",
                     G_CALLBACK(message_received_cb), app_data);
    
    WebKitWebView *web_view = WEBKIT_WEB_VIEW(
        webkit_web_view_new_with_user_content_manager(content_manager));
    app_data->web_view = web_view;
    
    gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(web_view));
    
    // Load the HTML file
    char uri[1024];
    snprintf(uri, sizeof(uri), "file://%s", index_path);
    webkit_web_view_load_uri(web_view, uri);
    
    gtk_widget_show_all(window);
    gtk_main();
    
    free(app_data);
    return 0;
}
