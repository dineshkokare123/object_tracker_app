import onnx

# Load the problematic model
input_onnx_path = 'yolo11n.onnx'
output_onnx_path = 'yolo11n_repaired.onnx'

try:
    print(f"Attempting to load: {input_onnx_path}")
    model = onnx.load(input_onnx_path)
    
    print(f"Successfully loaded. Saving to: {output_onnx_path}")
    # Save the model back immediately (this re-serializes the protobuf)
    onnx.save(model, output_onnx_path)
    
    print("✅ ONNX model successfully repaired and saved.")
except Exception as e:
    print(f"❌ Failed to load/save ONNX model: {e}")