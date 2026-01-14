import os
# Force CPU and disable Metal to avoid macOS/Python 3.13 deadlocks
os.environ['CUDA_VISIBLE_DEVICES'] = '-1'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from sklearn.preprocessing import LabelEncoder

# 1. Load Data
CSV_PATH = '/Users/roccosantonastasio/Desktop/Github/Fyne/data/training_data.csv'
df = pd.read_csv(CSV_PATH)

# 2. Preprocessing
descriptions = df['description'].astype(str).tolist()
labels = df['label'].tolist()

# Parameters
vocab_size = 1000
embedding_dim = 16
max_length = 50
trunc_type='post'
padding_type='post'
oov_tok = "<OOV>"

# Tokenize text
tokenizer = Tokenizer(num_words=vocab_size, oov_token=oov_tok)
tokenizer.fit_on_texts(descriptions)
sequences = tokenizer.texts_to_sequences(descriptions)
padded = pad_sequences(sequences, maxlen=max_length, padding=padding_type, truncating=trunc_type)

# Encode labels
label_encoder = LabelEncoder()
label_indices = label_encoder.fit(labels)
training_labels = label_encoder.transform(labels)
num_classes = len(label_encoder.classes_)

print(f"Categories found: {label_encoder.classes_}")

# 3. Build Model
model = tf.keras.Sequential([
    tf.keras.layers.Embedding(vocab_size, embedding_dim, input_length=max_length),
    tf.keras.layers.GlobalAveragePooling1D(),
    tf.keras.layers.Dense(24, activation='relu'),
    tf.keras.layers.Dense(num_classes, activation='softmax')
])

model.compile(loss='sparse_categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

# 4. Train
num_epochs = 100
model.fit(padded, training_labels, epochs=num_epochs, verbose=1)

# 5. Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# 6. Save Model
OUTPUT_DIR = '/Users/roccosantonastasio/Desktop/Github/Fyne/frontend/assets/models'
os.makedirs(OUTPUT_DIR, exist_ok=True)
MODEL_PATH = os.path.join(OUTPUT_DIR, 'category_model.tflite')

with open(MODEL_PATH, 'wb') as f:
    f.write(tflite_model)

print(f"\n✅ TFLite Model saved to: {MODEL_PATH}")

# Save labels and tokenizer config for Flutter integration
print("\n--- Flutter Integration Constants ---")
print(f"Labels order (use this in Dart): {list(label_encoder.classes_)}")
print(f"Max length: {max_length}")
