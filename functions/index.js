/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// トークンを保存するエンドポイント
exports.saveToken = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const token = req.body.token;
  if (!token) {
    return res.status(400).send("Token is required");
  }

  try {
    await admin.firestore().collection("fcmTokens").doc(token).set({
      token: token,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.status(200).send("Token saved successfully");
  } catch (error) {
    console.error("Error saving token:", error);
    return res.status(500).send("Internal Server Error");
  }
});

// バージョンアップ通知を送信するエンドポイント
exports.notifyUpdate = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const version = req.body.version;
  if (!version) {
    return res.status(400).send("Version is required");
  }

  try {
    const tokensSnapshot = await admin
        .firestore()
        .collection("fcmTokens")
        .get();
    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

    if (tokens.length === 0) {
      return res.status(200).send("No tokens to send");
    }

    const message = {
      notification: {
        title: "アプリがアップデートされました",
        body: `新しいバージョン (${version}) が利用可能です。` +
              "最新の機能をお楽しみください！",
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);
    console.log(`${response.successCount} 通知が正常に送信されました`);
    return res.status(200).send("Notifications sent successfully");
  } catch (error) {
    console.error("Error sending notifications:", error);
    return res.status(500).send("Internal Server Error");
  }
});
