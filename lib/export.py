# lib/export.py content
from ultralytics import YOLO

# CHANGE THIS LINE to the actual path of your 'last.pt' file (e.g., train9 or train10)
WEIGHTS_PATH = 'runs/detect/train9/weights/last.pt' 

print(f"Loading trained model from checkpoint: {WEIGHTS_PATH}")
model = YOLO(WEIGHTS_PATH)

print("Exporting model to TFLite (float32)...")
model.export(format='tflite', int8=False)