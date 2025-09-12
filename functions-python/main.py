from flask import Flask, request, jsonify
import numpy as np
import cv2
import face_recognition
import firebase_admin
from firebase_admin import credentials, firestore, auth
import functions_framework

# ⚡ Khởi tạo Firebase Admin
cred = credentials.Certificate("aspire-edge-app-firebase-adminsdk-fbsvc-9c21de49e2.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# ⚡ Tạo Flask app để route 2 endpoint
app = Flask(__name__)

@app.route("/generate_embedding", methods=["POST"])
def generate_embedding_route():
    return generate_embedding(request)

@app.route("/verify_face", methods=["POST"])
def verify_face_route():
    return verify_face(request)

# -----------------------------
# Giữ nguyên function gốc
# -----------------------------
@functions_framework.http
def generate_embedding(request):
    if request.method != "POST":
        return "Method not allowed", 405

    if "image" not in request.files or "email" not in request.form:
        return jsonify({"error": "Need image and email"}), 400

    file = request.files["image"].read()
    email = request.form["email"]

    nparr = np.frombuffer(file, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    face_locations = face_recognition.face_locations(img)
    if not face_locations:
        return jsonify({"error": "No face detected"}), 400

    embedding = face_recognition.face_encodings(img, face_locations)[0].tolist()

    # Lưu embedding vào Firestore
    db.collection("user_face_embeddings").document(email).set({
        "email": email,
        "embedding": embedding
    })

    return jsonify({
        "email": email,
        "embedding": embedding
    })

@functions_framework.http
def verify_face(request):
    if request.method != "POST":
        return "Method not allowed", 405

    if "image" not in request.files or "email" not in request.form:
        return jsonify({"error": "Need image and email"}), 400

    file = request.files["image"].read()
    email = request.form["email"]

    nparr = np.frombuffer(file, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    face_locations = face_recognition.face_locations(img)
    if not face_locations:
        return jsonify({"error": "No face detected"}), 400

    embedding = face_recognition.face_encodings(img, face_locations)[0]

    # Lấy embedding từ Firestore
    doc_ref = db.collection("user_face_embeddings").document(email).get()
    if not doc_ref.exists:
        return jsonify({"error": "User not found"}), 404

    db_embedding = np.array(doc_ref.to_dict()["embedding"], dtype=np.float32)
    distance = np.linalg.norm(db_embedding - embedding)

    if distance < 0.45:
        account_doc = db.collection("account").where("email", "==", email).get()
        user_info = account_doc[0].to_dict() if account_doc else {}

        uid = email
        custom_token = auth.create_custom_token(uid).decode("utf-8")

        return jsonify({
            "success": True,
            "email": email,
            "distance": float(distance),
            "user_info": user_info,
            "customToken": custom_token
        })
    else:
        return jsonify({
            "success": False,
            "error": "Face not match",
            "distance": float(distance)
        }), 401
