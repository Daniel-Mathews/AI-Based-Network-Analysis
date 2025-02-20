from flask import Flask, jsonify, render_template, request
from flask_cors import CORS  # Import CORS
import mysql.connector
import subprocess
import platform
import socket
import logging

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configure logging for debugging
logging.basicConfig(level=logging.DEBUG)

# Database configuration
DB_CONFIG = {
    'host': '192.168.1.59',      # Replace with the actual server IP
    'user': 'root',      # Replace with the database username
    'password': 'Cottons@1327',  # Replace with the database password
    'database': 'IP_INFORMATION',  # Replace with the database name
    'table': 'IP_INFO'      # Table name
}

def get_ip_addresses():
    """Fetch IP addresses from the predefined table in the database."""
    try:
        logging.debug("Connecting to the database...")
        conn = mysql.connector.connect(
            host=DB_CONFIG['host'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database=DB_CONFIG['database']
        )
        cursor = conn.cursor()

        # Use the correct column name 'IP_ADDRESS'
        table_name = DB_CONFIG['table']
        query = f"SELECT IP_ADDRESS FROM {table_name}"
        logging.debug(f"Executing query: {query}")
        cursor.execute(query)
        ip_addresses = [row[0] for row in cursor.fetchall()]

        if not ip_addresses:
            raise ValueError("No IP addresses found in the database.")
        
        logging.debug(f"Fetched IP addresses: {ip_addresses}")
        return ip_addresses

    except mysql.connector.Error as err:
        logging.error(f"Database connection failed: {err}")
        raise RuntimeError(f"Database connection failed: {err}")
    
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
        raise RuntimeError(f"Unexpected error: {e}")

    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

def ping_ip(ip):
    """Ping an IP address and return whether it's up or down."""
    try:
        if platform.system().lower() == "windows":
            cmd = ["ping", "-n", "1", "-w", "1000", ip]
        else:
            cmd = ["ping", "-c", "1", "-W", "1", ip]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return result.returncode == 0  # Return True if ping was successful
    except Exception as e:
        logging.error(f"Error pinging {ip}: {e}")
        return False

def scan_ports(ip):
    """Scan ports 1 to 5000 for the given IP address."""
    open_ports = []
    for port in range(1, 100):  # Scan ports from 1 to 5000
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)  # Reduced timeout for faster scanning
        result = sock.connect_ex((ip, port))
        if result == 0:
            open_ports.append(port)
        sock.close()
    return open_ports

@app.after_request
def after_request(response):
    """Handle CORS preflight requests."""
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
    return response

@app.route('/')
def home():
    """Serve the main HTML page."""
    return render_template('index.html')

@app.route('/get_ip_addresses', methods=['GET'])
def fetch_ip_addresses():
    """Endpoint to fetch IP addresses."""
    try:
        ip_addresses = get_ip_addresses()
        return jsonify({'success': True, 'ip_addresses': ip_addresses})
    except RuntimeError as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/ping', methods=['POST'])
def ping():
    """Endpoint to ping an IP address."""
    data = request.get_json()
    ip = data.get('ip')
    if not ip:
        return jsonify({'success': False, 'error': 'IP address not provided'}), 400
    try:
        is_up = ping_ip(ip)
        return jsonify({'success': True, 'ip': ip, 'status': 'up' if is_up else 'down'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/scan', methods=['POST'])
def scan():
    """Endpoint to scan open ports on the given IP."""
    data = request.get_json()
    ip = data.get('ip')
    if not ip:
        return jsonify({'success': False, 'error': 'IP address not provided'}), 400
    try:
        open_ports = scan_ports(ip)
        return jsonify({'success': True, 'ip': ip, 'open_ports': open_ports})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0")  # Allow access from any IP
