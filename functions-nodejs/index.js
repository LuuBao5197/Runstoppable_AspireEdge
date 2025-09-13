// index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
const cloudinary = require("cloudinary").v2;

// Khởi tạo Firebase Admin SDK (chỉ một lần)
admin.initializeApp();
const db = admin.firestore();

// Cấu hình Cloudinary (chỉ một lần)
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});


// =======================================================
// FUNCTION 1: Xóa ảnh trên Cloudinary (Giữ nguyên)
// =======================================================
exports.deleteCloudinaryImage = functions.https.onCall(async (data, context) => {
    // ... code của bạn giữ nguyên ...
});


// =======================================================
// FUNCTION 2: Lấy câu hỏi Quiz (PHIÊN BẢN CUỐI CÙNG)
// =======================================================
exports.get_next_question = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    try {
      // --- CÁC HẰNG SỐ CẤU HÌNH ---
      const CONFIDENCE_THRESHOLD = 8;
      const MAX_QUESTIONS_LIMIT = 30;
      const MINIMUM_QUESTIONS_FOR_CONFIDENCE_CHECK = 5; // Số câu hỏi tối thiểu
      // -----------------------------

      const quizId = req.body.quiz_id || "career_interest_quiz_v1";
      const currentScores = req.body.current_scores || {};
      const answeredIds = req.body.answered_question_ids || [];

      const quizDoc = await db.collection("quizzes").doc(quizId).get();
      if (!quizDoc.exists) {
        return res.status(404).send(`Quiz with ID '${quizId}' not found`);
      }
      const quizData = quizDoc.data();
      let nextQuestionId = null;

      // Logic 1: Câu hỏi đầu tiên
      if (answeredIds.length === 0) {
        const openingIds = quizData.openingQuestionIds || [];
        if (openingIds.length > 0) {
          nextQuestionId = openingIds[Math.floor(Math.random() * openingIds.length)];
        }
      }
      // Logic 2: Luồng mặc định
      else if (Object.values(currentScores).every((score) => score <= 0)) {
        const defaultIds = quizData.defaultFlowQuestionIds || [];
        for (const qid of defaultIds) {
          if (!answeredIds.includes(qid)) {
            nextQuestionId = qid;
            break;
          }
        }
        if (!nextQuestionId) {
          return res.status(200).json({ status: "completed", message: "Cannot determine result." });
        }
      }
      // Logic 3: AI chọn
      else {
        // === LOGIC DỪNG ĐÃ SỬA LẠI CHÍNH XÁC ===
        if (answeredIds.length >= MAX_QUESTIONS_LIMIT) {
          console.log("Quiz ended: Reached max questions limit.");
          return res.status(200).json({ status: "completed", final_scores: currentScores });
        }

        const sortedScores = Object.entries(currentScores).sort((a, b) => b[1] - a[1]);

        // KIỂM TRA ĐIỀU KIỆN TỐI THIỂU Ở ĐÂY
        if (answeredIds.length > MINIMUM_QUESTIONS_FOR_CONFIDENCE_CHECK && sortedScores.length >= 2) {
          const score1 = sortedScores[0][1];
          const score2 = sortedScores[1][1];
          if ((score1 - score2) >= CONFIDENCE_THRESHOLD) {
            console.log("Quiz ended: Result is confident.");
            return res.status(200).json({ status: "completed", final_scores: currentScores });
          }
        }
        // ==========================================

        const mainBankIds = quizData.mainBankQuestionIds || [];
        const availableIds = mainBankIds.filter((qid) => !answeredIds.includes(qid));

        if (availableIds.length === 0) {
          return res.status(200).json({ status: "completed", final_scores: currentScores });
        }

        const topCategory1 = sortedScores[0][0];
        const topCategory2 = sortedScores.length > 1 ? sortedScores[1][0] : null;

        let bestQuestionId = null;
        let maxDivergence = -1;

        const questionRefs = availableIds.map((qid) => db.collection("questions").doc(qid));
        const questionDocs = await db.getAll(...questionRefs);

        for (const doc of questionDocs) {
          if (!doc.exists) continue;
          const questionData = doc.data();
          if (questionData.questionType !== "multiple-choice") continue;

          for (const answer of questionData.answers || []) {
            const scores = answer.scores || {};
            const score1 = scores[topCategory1] || 0;
            const score2 = topCategory2 ? (scores[topCategory2] || 0) : 0;
            const divergence = Math.abs(score1 - score2);

            if (divergence > maxDivergence) {
              maxDivergence = divergence;
              bestQuestionId = doc.id;
            }
          }
        }
        nextQuestionId = bestQuestionId || availableIds[Math.floor(Math.random() * availableIds.length)];
      }

      // Trả về câu hỏi đã chọn
      if (nextQuestionId) {
        const questionToServeDoc = await db.collection("questions").doc(nextQuestionId).get();
        if (questionToServeDoc.exists) {
          const responseData = questionToServeDoc.data();
          responseData.questionId = nextQuestionId;
          return res.status(200).json(responseData);
        } else {
          return res.status(404).send(`Question ${nextQuestionId} not found.`);
        }
      } else {
        return res.status(200).json({ status: "completed", final_scores: currentScores });
      }
    } catch (error) {
      console.error("Error in get_next_question:", error);
      return res.status(500).send("An internal error occurred.");
    }
  });
});
// ... import và khởi tạo ...

exports.addNewQuestion = functions.https.onCall(async (data, context) => {
  // Giả sử admin đã đăng nhập và có quyền
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Permission denied.");
  }

  const { questionText, questionType, answers, options } = data;

  if (!questionText) {
    throw new functions.https.HttpsError("invalid-argument", "Question text is required.");
  }

  const questionsRef = db.collection("questions");

  // === BƯỚC KIỂM TRA TRÙNG LẶP ===
  // 1. Tạo một query để tìm kiếm các document có questionText y hệt
  const snapshot = await questionsRef.where("questionText", "==", questionText).limit(1).get();

  // 2. Nếu query trả về kết quả (snapshot không rỗng), nghĩa là đã tồn tại
  if (!snapshot.empty) {
    console.log(`Attempted to add a duplicate question: "${questionText}"`);
    throw new functions.https.HttpsError(
      "already-exists",
      "A question with this exact text already exists."
    );
  }
  // ================================

  // 3. Nếu không trùng, tiến hành thêm câu hỏi mới vào database
  try {
    const newQuestion = { questionText, questionType, answers, options }; // và các field khác
    const writeResult = await questionsRef.add(newQuestion);
    console.log(`Successfully added new question with ID: ${writeResult.id}`);
    return { success: true, questionId: writeResult.id };
  } catch (error) {
    console.error("Error adding new question:", error);
    throw new functions.https.HttpsError("internal", "Could not add new question.");
  }
});

// index.js -> thay thế function updateQuestion

exports.updateQuestion = functions.https.onCall(async (data, context) => {
  // Log dữ liệu gốc nhận được để debug
  console.log("Raw data object received by function:", data);

  // === BƯỚC KIỂM TRA MỚI: Xử lý dữ liệu bị gói ===
  // Kiểm tra xem dữ liệu thực sự có nằm trong một key tên "data" hay không.
  // Nếu có, dùng nó. Nếu không, dùng data gốc.
  const payload = data.data || data;
  // ===============================================

  // Kiểm tra quyền admin
//  if (context.auth.token.admin !== true) {
//    throw new functions.https.HttpsError("permission-denied", "You must be an admin to perform this action.");
//  }

  // Lấy ID và dữ liệu mới từ "payload" thay vì "data"
  const { questionId, questionText, ...otherData } = payload;
  if (!questionId || !questionText) {
    console.error("Validation failed. Final payload did not contain questionId or questionText:", payload);
    throw new functions.https.HttpsError("invalid-argument", "Question ID and text are required in the payload.");
  }

  const questionsRef = db.collection("questions");

  // Logic kiểm tra trùng lặp (giữ nguyên)
  const snapshot = await questionsRef
    .where("questionText", "==", questionText)
    .where(admin.firestore.FieldPath.documentId(), "!=", questionId)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    throw new functions.https.HttpsError("already-exists", "Another question with this exact text already exists.");
  }

  // Cập nhật câu hỏi (giữ nguyên)
  try {
    await questionsRef.doc(questionId).update({ questionText, ...otherData });
    return { success: true, message: "Question updated successfully." };
  } catch (error) {
    console.error("Error updating question:", error.message);
    throw new functions.https.HttpsError("internal", "Could not update question.");
  }
});