from flask import Flask, render_template, jsonify, request
import mysql.connector
from flask_cors import CORS  # Import CORS
import mysql.connector
import subprocess
import platform
import socket
import logging

 # Enable CORS for all routes

# Configure logging for debugging
logging.basicConfig(level=logging.DEBUG)
app = Flask(__name__)
CORS(app) 

# Database connection parameters
db_config = {
    'host': '192.168.1.59',
    'user': 'root',
    'password': 'Cottons@1327',
    'database': 'IP_INFORMATION'
}

def get_ram_values(ip):
    try:
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()

        # Fetch 'USED_RAM' and 'TOTAL_RAM' values for the given IP
        cursor.execute("SELECT USED_RAM, TOTAL_RAM FROM VM_LXC_IPS WHERE IP = %s;", (ip,))
        result = cursor.fetchone()

        if result:
            used_ram_value, total_ram_value = result
            ram_usage_percentage = (used_ram_value / total_ram_value) * 100 if total_ram_value != 0 else 0
            return used_ram_value, total_ram_value, ram_usage_percentage
        return 0, 0, 0
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return 0, 0, 0
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def get_cpu_values(ip):
    try:
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()

        # Fetch 'CPU_USED_PERCENT' for the given IP
        cursor.execute("SELECT CPU_USED_PERCENT FROM VM_LXC_IPS WHERE IP = %s;", (ip,))
        result = cursor.fetchone()

        return result[0] if result else 0
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return 0
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def get_disk_values(ip):
    try:
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()

        # Fetch disk space data for the given IP
        cursor.execute("SELECT PART_USED_PERCENT, TOTAL_DISK_PART, DISK_PART_USED FROM VM_LXC_IPS WHERE IP = %s;", (ip,))
        result = cursor.fetchone()

        if result:
            disk_free_percent, total_disk, disk_used = result
            return disk_free_percent, total_disk, disk_used
        return 0, 0, 0
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return 0, 0, 0
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()


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


import mysql.connector

def fetch_package_data(ip):
    """
    Function to fetch PACKAGE_NAME and PACKAGE_VERSION for a table derived from IP address.
    The table name is created by replacing '.' with '_'.
    """
    table_name = ip.replace('.', '_')  # Convert IP to table name
    
    try:
        # Establish a database connection
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()

        # Check if the table exists
        cursor.execute(f"SHOW TABLES LIKE 'IP_{table_name}';")
        if not cursor.fetchone():
            return {"success": False, "error": f"Table `{table_name}` does not exist"}

        # Query the table for PACKAGE_NAME and PACKAGE_VERSION
        query = f"SELECT `PACKAGE_NAME`, `PACKAGE_VERSION` FROM IP_{table_name};"
        cursor.execute(query)
        results = cursor.fetchall()

        # Format results into a list of dictionaries
        packages = [{"package_name": row[0], "package_version": row[1]} for row in results]

        # Return successful response with the fetched data
        return {"success": True, "packages": packages}

    except mysql.connector.Error as err:
        # Log any database error and return an error message
        return {"success": False, "error": f"Database error: {str(err)}"}

    finally:
        # Close the database connection
        if connection.is_connected():
            cursor.close()
            connection.close()


@app.route('/')
def home():
    return render_template('home.html')

@app.after_request
def after_request(response):
    """Handle CORS preflight requests."""
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
    return response

@app.route('/dashboard/<ip>')
def dashboard(ip):
    return render_template('index.html', ip=ip)

@app.route('/get-ip-list')
def get_ip_list():
    try:
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()

        # Fetch all IPs from the database
        cursor.execute("SELECT IP FROM VM_LXC_IPS;")
        results = cursor.fetchall()

        ip_list = [row[0] for row in results]
        return jsonify(ip_list=ip_list)
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return jsonify(ip_list=[])
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

@app.route('/get-ram-values')
def get_ram_values_endpoint():
    ip = request.args.get('ip')  # Retrieve the IP from the query parameter
    used_ram_value, total_ram_value, ram_usage_percentage = get_ram_values(ip)
    return jsonify(
        used_ram=used_ram_value,
        total_ram=total_ram_value,
        ram_usage_percentage=ram_usage_percentage
    )

@app.route('/get-cpu-values')
def get_cpu_values_endpoint():
    ip = request.args.get('ip')  # Retrieve the IP from the query parameter
    cpu_percent = get_cpu_values(ip)
    return jsonify(cpu_percent=cpu_percent)

@app.route('/get-disk-values')
def get_disk_values_endpoint():
    ip = request.args.get('ip')  # Retrieve the IP from the query parameter
    disk_free_percent, total_disk, disk_used = get_disk_values(ip)
    return jsonify(
        diskfreeperc=disk_free_percent,
        totaldisk=total_disk,
        diskused=disk_used
    )

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


@app.route('/get-packages', methods=['GET'])
def get_packages():
    """
    API endpoint to fetch PACKAGE_NAME and PACKAGE_VERSION for a specific table based on IP.
    """
    ip = request.args.get('ip')  # Get IP from query parameters
    if not ip:
        return jsonify({'success': False, 'error': 'IP address is required'}), 400

    table_name = ip.replace('.', '_')  # Convert IP to table name

    try:
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()

        # Check if the table exists dynamically based on IP
        cursor.execute(f"SHOW TABLES LIKE 'IP_{table_name}';")
        if not cursor.fetchone():
            return jsonify({'success': False, 'error': f'Table for IP {ip} does not exist'}), 404

        # Fetch PACKAGE_NAME and PACKAGE_VERSION from the dynamically created table
        cursor.execute(f"SELECT PACKAGE_NAME, PACKAGE_VERSION FROM IP_{table_name};")
        results = cursor.fetchall()

        # Format the results
        formatted_packages = [
            {'package_name': pkg[0].strip(), 'package_version': pkg[1].strip()} for pkg in results if pkg
        ]

        return jsonify({'success': True, 'packages': formatted_packages})

    except mysql.connector.Error as err:
        logging.error(f"Database error: {err}")
        return jsonify({'success': False, 'error': 'Database error: ' + str(err)}), 500

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

@app.route('/service-data')
def service_data():
    try:
        # List of file paths
        file_paths = ['service_data1.txt', 'service_data2.txt']
        
        # Initialize a list to store parsed data
        all_service_data = []
        
        # Process each file
        for file_path in file_paths:
            with open(file_path, 'r') as file:
                lines = file.readlines()
            
            # Extract data from the file
            data = {}
            for line in lines:
                key, value = line.strip().split(": ")
                data[key.strip()] = value.strip()
            
            # Append parsed data to the list
            all_service_data.append({
                'IP': data.get('IP'),
                'PRIORITY': data.get('Priority'),
                'SERVICE': data.get('Service'),
                'AVG_RX': data.get('Receiving'),
                'AVG_TX': data.get('Transmitting')
            })
        
        # Render the HTML with the fetched data
        return render_template('service_data.html', data=all_service_data)
    
    except Exception as e:
        return f"Error: {e}"

if __name__ == '__main__':
    app.run(debug=True)



