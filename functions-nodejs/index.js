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