from flask import Flask, request, jsonify
import numpy as np
import face_recognition
import firebase_admin
import cv2
from firebase_admin import credentials, firestore, auth
import dlib
from scipy.spatial import distance as dist
import os

app = Flask(__name__)

# 🔹 Firebase init
cred = credentials.Certificate(
    "D:/T1.2308.A0/CSW/multi-auth-system/flask-faceid/aspire-edge-app-firebase-adminsdk-fbsvc-9c21de49e2.json"
)
firebase_admin.initialize_app(cred)
db = firestore.client()

# 🔹 Load dlib models once
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

# =============================
# Utility functions
# =============================
def eye_aspect_ratio(eye):
    A = dist.euclidean(eye[1], eye[5])
    B = dist.euclidean(eye[2], eye[4])
    C = dist.euclidean(eye[0], eye[3])
    ear = (A + B) / (2.0 * C)
    return ear

def check_blink(frame):
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    rects = detector(gray, 0)
    for rect in rects:
        shape = predictor(gray, rect)
        coords = np.zeros((68, 2), dtype=int)
        for i in range(0, 68):
            coords[i] = (shape.part(i).x, shape.part(i).y)

        leftEye = coords[42:48]
        rightEye = coords[36:42]
        ear = (eye_aspect_ratio(leftEye) + eye_aspect_ratio(rightEye)) / 2.0
        return ear < 0.2   # blink detected
    return False

# =============================
# Routes
# =============================

@app.route("/generate_embedding", methods=["POST"])
def generate_embedding():
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

    db.collection("user_face_embeddings").document(email).set({
        "email": email,
        "embedding": embedding
    })

    return jsonify({"email": email, "embedding": embedding})

@app.route("/verify_face", methods=["POST"])
def verify_face():
    if "image1" not in request.files or "image2" not in request.files or "email" not in request.form:
        return jsonify({"error": "Need 2 images and email"}), 400

    email = request.form["email"]

    # Ảnh 1
    nparr1 = np.frombuffer(request.files["image1"].read(), np.uint8)
    img1 = cv2.imdecode(nparr1, cv2.IMREAD_COLOR)

    # Ảnh 2
    nparr2 = np.frombuffer(request.files["image2"].read(), np.uint8)
    img2 = cv2.imdecode(nparr2, cv2.IMREAD_COLOR)

    # --- Kiểm tra blink (ảnh 1 mở mắt, ảnh 2 nhắm mắt)
    blink1 = check_blink(img1)  # False (mắt mở)
    blink2 = check_blink(img2)  # True (mắt nhắm)

    if not (not blink1 and blink2):
        return jsonify({
            "success": False,
            "error": "Liveness check failed (no blink detected)"
        }), 401

    # --- Tiếp tục nhận diện (dùng ảnh 1)
    face_locations = face_recognition.face_locations(img1)
    if not face_locations:
        return jsonify({"error": "No face detected"}), 400

    embedding = face_recognition.face_encodings(img1, face_locations)[0]

    doc_ref = db.collection("user_face_embeddings").document(email).get()
    if not doc_ref.exists:
        return jsonify({"error": "User not found"}), 404

    db_embedding = np.array(doc_ref.to_dict()["embedding"], dtype=np.float32)
    distance = np.linalg.norm(db_embedding - embedding)

    if distance < 0.45:
        account_doc = db.collection("account").where("email", "==", email).get()
        user_info = account_doc[0].to_dict() if account_doc else {}

        uid = user_info.get("uid")
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

@app.route("/verify_face_video", methods=["POST"])
def verify_face_video():
    if "video" not in request.files or "email" not in request.form:
        return jsonify({"error": "Need video and email"}), 400

    email = request.form["email"]
    video_bytes = request.files["video"].read()

    # Lưu tạm video
    temp_path = "temp_video.mp4"
    with open(temp_path, "wb") as f:
        f.write(video_bytes)

    cap = cv2.VideoCapture(temp_path)

    blink_detected = False
    embeddings = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # resize nhỏ cho nhanh
        small_frame = cv2.resize(frame, (0, 0), fx=0.5, fy=0.5)

        # kiểm tra blink
        if check_blink(small_frame):
            blink_detected = True

        # lấy embedding (chỉ lấy vài frame)
        face_locations = face_recognition.face_locations(small_frame)
        if face_locations:
            emb = face_recognition.face_encodings(small_frame, face_locations)[0]
            embeddings.append(emb)

    cap.release()
    os.remove(temp_path)

    print(f"👉 Blink detected: {blink_detected}, embeddings collected: {len(embeddings)}")

    if not blink_detected:
        return jsonify({"success": False, "error": "Liveness check failed"}), 401

    if not embeddings:
        return jsonify({"error": "No face detected"}), 400

    # lấy embedding trung bình
    avg_embedding = np.mean(embeddings, axis=0)

    # so sánh với db
    doc_ref = db.collection("user_face_embeddings").document(email).get()
    if not doc_ref.exists:
        return jsonify({"error": "User not found"}), 404

    db_embedding = np.array(doc_ref.to_dict()["embedding"], dtype=np.float32)
    distance = np.linalg.norm(db_embedding - avg_embedding)

    print(f"👉 DB distance: {distance:.4f}")

    if distance < 0.45:
        account_doc = db.collection("account").where("email", "==", email).get()
        user_info = account_doc[0].to_dict() if account_doc else {}
        uid = user_info.get("uid")

        token = auth.create_custom_token(uid).decode("utf-8")
        return jsonify({
            "success": True,
            "email": email,
            "distance": float(distance),
            "user_info": user_info,
            "customToken": token
        })

    return jsonify({
        "success": False,
        "error": "Face not match",
        "distance": float(distance)
    }), 401


# =============================
# Entry point
# =============================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
