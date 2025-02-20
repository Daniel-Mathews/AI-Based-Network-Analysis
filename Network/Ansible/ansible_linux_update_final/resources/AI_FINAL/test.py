def identify_service(file_path):
    try:
        # Read the input file
        with open(file_path, 'r') as file:
            lines = file.readlines()

        # Process each line
        for line in lines:
            line = line.strip()
            if not line:
                continue

            try:
                # Split the line into receiving and transmitting bandwidth
                receiving, transmitting = map(float, line.split(","))

                # Calculate the absolute difference
                difference = abs(receiving - transmitting)

                # Check the conditions
                if receiving > 100 and transmitting > 100 and difference <= 50:
                    print(f'''
Receiving: {receiving}
Transmitting: {transmitting} 
Service: GoogleMeet
Priority: 1''')
                elif receiving < 100 and transmitting < 100 and difference <= 10:
                    print(f'''
Receiving: {receiving}
Transmitting: {transmitting} 
Service: Amazon
Priority: 2''')
                elif receiving > transmitting * 5:
                    print(f'''
Receiving: {receiving}
Transmitting: {transmitting} 
Service: Youtube
Priority: 3''')

            except ValueError:
                print(f"Skipping invalid line: {line}")

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# Specify the path to your input file
file_path = "/home/aniket/network_analyzer/final_data.txt"
identify_service(file_path)
