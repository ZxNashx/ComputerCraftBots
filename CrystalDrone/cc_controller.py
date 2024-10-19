import tkinter as tk
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import threading

# Configuration
HOST_NAME = '10.0.0.228'  # Listen on all interfaces
PORT_NUMBER = 8080  # Ensure this matches the port the turtle sends requests to

# Tkinter application to display turtle info and send commands
# yes
class TurtleControlApp:
    def __init__(self, master):
        self.master = master
        master.title("Turtle Control Panel")

        # Display Labels
        self.info_label = tk.Label(master, text="Turtle Information", font=("Arial", 16))
        self.info_label.pack()

        self.info_text = tk.Text(master, width=50, height=20, state='disabled')
        self.info_text.pack()

        self.command_label = tk.Label(master, text="Send Command:", font=("Arial", 14))
        self.command_label.pack()

        # Input field for commands
        self.command_entry = tk.Entry(master, width=30)
        self.command_entry.pack()

        # Send button
        self.send_button = tk.Button(master, text="Send", command=self.send_command)
        self.send_button.pack()

        self.last_command = None  # Store the last command for the HTTP response

    def update_info(self, info):
        self.info_text.config(state='normal')
        self.info_text.delete('1.0', tk.END)
        self.info_text.insert(tk.END, json.dumps(info, indent=4))
        self.info_text.config(state='disabled')

    def send_command(self):
        self.last_command = self.command_entry.get()
        self.command_entry.delete(0, tk.END)

    def get_last_command(self):
        return self.last_command

# HTTP Server to handle requests from the turtle
class TurtleRequestHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        turtle_info = json.loads(post_data)

        # Update the Tkinter GUI with the received turtle info
        app.update_info(turtle_info)

        # Respond with the last command
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

        # Send the last command to the turtle
        command = app.get_last_command()
        if command:
            response = json.dumps(command)
        else:
            response = json.dumps("idle")  # Default idle command if none sent
        self.wfile.write(response.encode('utf-8'))

    def log_message(self, format, *args):
        return  # Override to suppress console logging

# Run the HTTP server in a separate thread
def run_server():
    server_address = (HOST_NAME, PORT_NUMBER)
    httpd = HTTPServer(server_address, TurtleRequestHandler)
    print(f'Server running on {HOST_NAME}:{PORT_NUMBER}')
    httpd.serve_forever()

# Start the Tkinter GUI and the server thread
root = tk.Tk()
app = TurtleControlApp(root)

server_thread = threading.Thread(target=run_server)
server_thread.daemon = True  # Allow the program to exit even if thread is running
server_thread.start()

root.mainloop()
