from ultralytics import YOLO
import os

# Set the path to your trained weights
# If you are starting fresh, use a pre-trained model like 'yolov8n.pt'
WEIGHTS_PATH = 'yolov8n.pt'  # Change this if your weights file is different

# --- Your Custom Configuration ---
DATA_CONFIG_PATH = '/Users/dineshkokare/Documents/Project/object_tracker_app/data.yaml'
EPOCHS = 50
IMG_SIZE = 640
# ---------------------------------

print(f"Loading model from: {WEIGHTS_PATH}")
model = YOLO(WEIGHTS_PATH)

print(f"Starting training on {DATA_CONFIG_PATH} for {EPOCHS} epochs...")
# Train the model on your custom dataset
# The results will be saved in the 'runs/detect' directory by default
model.train(data=DATA_CONFIG_PATH, epochs=EPOCHS, imgsz=IMG_SIZE)

print("Training finished. New weights should be saved in runs/detect/...")