package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/webview/webview"
)

// CommandResult represents the result of executing a command
type CommandResult struct {
	Stdout   string `json:"stdout"`
	Stderr   string `json:"stderr"`
	ExitCode int    `json:"exitCode"`
	Error    string `json:"error"`
}

// execCommand executes a command with the captured environment
func execCommand(cmdArray []interface{}) CommandResult {
	result := CommandResult{}

	// Validate cmdArray is not empty
	if len(cmdArray) == 0 {
		result.Error = "command array is empty"
		result.ExitCode = 1
		return result
	}

	// Convert interface{} array to string array
	var args []string
	for i, v := range cmdArray {
		str, ok := v.(string)
		if !ok {
			result.Error = fmt.Sprintf("argument %d is not a string", i)
			result.ExitCode = 1
			return result
		}
		args = append(args, str)
	}

	// Create command - this uses PATH resolution like execvp()
	cmd := exec.Command(args[0], args[1:]...)
	
	// Use the current environment (which includes wizardry PATH)
	cmd.Env = os.Environ()

	// Capture output
	var stdoutBuf, stderrBuf strings.Builder
	cmd.Stdout = &stdoutBuf
	cmd.Stderr = &stderrBuf

	// Execute
	err := cmd.Run()
	
	result.Stdout = stdoutBuf.String()
	result.Stderr = stderrBuf.String()

	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			result.ExitCode = exitErr.ExitCode()
		} else {
			result.Error = err.Error()
			result.ExitCode = 1
		}
	} else {
		result.ExitCode = 0
	}

	return result
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <app-directory>\n", os.Args[0])
		os.Exit(1)
	}

	appDir := os.Args[1]
	indexPath := filepath.Join(appDir, "index.html")

	// Check if index.html exists
	if _, err := os.Stat(indexPath); err != nil {
		log.Fatalf("index.html not found in %s: %v", appDir, err)
	}

	// Read index.html
	htmlContent, err := os.ReadFile(indexPath)
	if err != nil {
		log.Fatalf("failed to read index.html: %v", err)
	}

	// Create webview
	debug := os.Getenv("WIZARDRY_DEBUG") == "1"
	w := webview.New(debug)
	defer w.Destroy()
	
	w.SetTitle("Wizardry App")
	w.SetSize(1024, 768, webview.HintNone)

	// Bind the exec function to window.wizardry.exec
	w.Bind("wizardryExec", func(cmdArray []interface{}) CommandResult {
		log.Printf("Executing command: %v", cmdArray)
		return execCommand(cmdArray)
	})

	// Initialize the wizardry object in JavaScript
	initJS := `
		window.wizardry = {
			exec: function(cmdArray) {
				return wizardryExec(cmdArray);
			}
		};
		console.log('Wizardry native bridge initialized');
	`
	w.Init(initJS)

	// Load the HTML content
	// We need to use a data URL since we're loading from a string
	dataURL := "data:text/html;charset=utf-8," + string(htmlContent)
	w.Navigate(dataURL)

	w.Run()
}
