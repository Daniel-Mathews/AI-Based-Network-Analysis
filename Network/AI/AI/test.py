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
model.load_state_dict(torch.load("model_state_dict.pth"))
model.eval()

# Load the label encoder
label_encoder = joblib.load("label_encoder.joblib")

# Test input for prediction
example_input = torch.tensor([[2.5, 3.5]], dtype=torch.float32)
output = model(example_input)
predicted_class = torch.argmax(output, axis=1).item()
predicted_label = label_encoder.inverse_transform([predicted_class])

print(f"Input: [2.5, 3.5], Predicted Class: {predicted_label[0]}")
