import tensorflow as tf

# --- Configuration ---
# Use the directory created by onnx-tf
SAVED_MODEL_DIR = 'yolo11n_saved_model' 
# This is the name your app's build process expects
TFLITE_OUTPUT_PATH = 'assets/yolov8_custom.tflite' 
# ---------------------

print(f"Starting TFLite conversion from: {SAVED_MODEL_DIR}")

try:
    converter = tf.lite.TFLiteConverter.from_saved_model(SAVED_MODEL_DIR)
    tflite_model = converter.convert()

    with open(TFLITE_OUTPUT_PATH, 'wb') as f:
        f.write(tflite_model)

    print(f"✅ Conversion complete. TFLite model saved to: {TFLITE_OUTPUT_PATH}")

except Exception as e:
    print(f"❌ TFLite Conversion Failed: {e}")
    print(f"Please ensure '{SAVED_MODEL_DIR}' is a valid TensorFlow SavedModel directory.")