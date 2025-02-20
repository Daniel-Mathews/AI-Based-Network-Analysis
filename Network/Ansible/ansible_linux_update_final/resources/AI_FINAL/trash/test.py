import torch
from torch import nn
from sklearn.preprocessing import LabelEncoder
import joblib

# Define the model architecture (same as training)
class Classifier(nn.Module):
    def __init__(self, input_size, hidden_size, output_size):
        super(Classifier, self).__init__()
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size, output_size)

    def forward(self, x):
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x

# Load the model
input_size = 2  # Same as training
hidden_size = 16
output_size = 5  # Same as training
model = Classifier(input_size, hidden_size, output_size)
model.load_state_dict(torch.load("model_state_dict.pth", weights_only=True))
model.eval()

# Load the label encoder
label_encoder = joblib.load("label_encoder.joblib")


# Function to process the bandwidth data
# Function to process the bandwidth data
def process_bandwidth_data_from_txt(file_path):
    total_rx = 0
    total_tx = 0

    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()  # Remove leading/trailing whitespace
            if not line:  # Skip empty lines
                continue
            parts = line.split(',')
            try:
                rx = float(parts[0])  # Receiving bandwidth
                tx = float(parts[1])  # Transmitting bandwidth
                total_rx += rx
                total_tx += tx
            except ValueError:
                print(f"Skipping invalid line: {line.strip()}")

    return total_rx, total_tx

file_path = "/home/aniket/network_analyzer/final_data.txt"  # Path to the text file

# Process the data without calculating averages
total_rx, total_tx = process_bandwidth_data_from_txt(file_path)

print(f"Total Receiving Bandwidth: {total_rx}")
print(f"Total Transmitting Bandwidth: {total_tx}")


# Convert to tensor and pass to the model
tensor_data = torch.tensor([total_rx, total_tx], dtype=torch.float32).unsqueeze(0)  # Add batch dimension

# Make predictions
try:
    output = model(tensor_data)  # Make a single prediction
    predicted_class = torch.argmax(output, axis=1).item()
    print("Predicted Class Index:", predicted_class)
    predicted_label = label_encoder.inverse_transform([predicted_class])
    print(f"Predicted Service Name: {predicted_label[0]}")
except Exception as e:
    print("Error during prediction:", e)
