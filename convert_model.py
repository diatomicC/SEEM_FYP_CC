import torch
import torch.nn as nn
import torchvision.models as models
import os

class FoodClassifier(nn.Module):
    def __init__(self, num_classes):
        super(FoodClassifier, self).__init__()
        # Load a pre-trained ResNet model
        self.model = models.resnet50(pretrained=False)
        # Modify the final layer to match your number of food classes
        self.model.fc = nn.Linear(self.model.fc.in_features, num_classes)
    
    def forward(self, x):
        return self.model(x)

def convert_model():
    try:
        # Get absolute paths
        current_dir = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.join(current_dir, 'lib', 'features', 'chat', 'models', 'best_food_model.pth')
        output_path = os.path.join(current_dir, 'assets', 'models', 'food_model.pt')
        
        print(f"Loading model from: {model_path}")
        print(f"Will save to: {output_path}")

        # Ensure the output directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Create model instance (adjust num_classes to match your model)
        model = FoodClassifier(num_classes=101)  # Adjust this number to match your model
        print("Model architecture created")
        
        # Load the state dict
        print("Loading state dict...")
        state_dict = torch.load(model_path, map_location=torch.device('cpu'))
        
        # Check if the state dict needs to be unwrapped from DataParallel
        if 'module.' in list(state_dict.keys())[0]:
            new_state_dict = {k.replace('module.', ''): v for k, v in state_dict.items()}
            state_dict = new_state_dict
        
        model.load_state_dict(state_dict)
        print("State dict loaded successfully")
        
        # Set to evaluation mode
        model.eval()
        print("Model set to eval mode")
        
        # Create example input
        example_input = torch.rand(1, 3, 224, 224)
        print("Created example input")
        
        # Trace the model
        print("Tracing model...")
        traced_model = torch.jit.trace(model, example_input)
        
        # Save the traced model
        print(f"Saving model to {output_path}")
        traced_model.save(output_path)
        print("Model converted and saved successfully!")
        
        # Verify the file exists
        if os.path.exists(output_path):
            print(f"Verified: File exists at {output_path}")
            print(f"File size: {os.path.getsize(output_path)} bytes")
        else:
            print("Warning: Output file was not created!")

    except Exception as e:
        print(f"Error during model conversion: {str(e)}")
        raise

if __name__ == '__main__':
    convert_model() 