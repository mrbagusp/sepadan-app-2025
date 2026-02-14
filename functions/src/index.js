const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

exports.detectMatch = onDocumentCreated(
  {
    document: "likes/{userId}/liked/{targetId}",
    region: "asia-southeast2",
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (event) => {
    const { userId, targetId } = event.params;

    if (!userId || !targetId || userId === targetId) {
      return;
    }

    logger.info(`Checking match: ${userId} -> ${targetId}`);

    try {
      const reciprocalRef = db
        .collection("likes")
        .doc(targetId)
        .collection("liked")
        .doc(userId);

      const reciprocalSnap = await reciprocalRef.get();

      if (!reciprocalSnap.exists) {
        logger.info("No reciprocal like found.");
        return;
      }

      // Sort UID supaya konsisten
      const uids = [userId, targetId].sort();
      const matchId = `${uids[0]}_${uids[1]}`;
      const matchRef = db.collection("matches").doc(matchId);

      await db.runTransaction(async (transaction) => {
        const existingMatch = await transaction.get(matchRef);
        if (existingMatch.exists) {
          logger.info("Match already exists.");
          return;
        }

        // Ambil profile
        const [profileA, profileB] = await Promise.all([
          db.collection("profiles").doc(uids[0]).get(),
          db.collection("profiles").doc(uids[1]).get(),
        ]);

        const nameA = profileA.data()?.displayName || "User";
        const nameB = profileB.data()?.displayName || "User";
        const photoA = profileA.data()?.photoUrl || "";
        const photoB = profileB.data()?.photoUrl || "";

        transaction.set(matchRef, {
          users: uids,
          user1Id: uids[0],
          user2Id: uids[1],
          user1Name: nameA,
          user2Name: nameB,
          user1PhotoUrl: photoA,
          user2PhotoUrl: photoB,
          createdAt: FieldValue.serverTimestamp(),
          lastActivityAt: FieldValue.serverTimestamp(),
          lastMessage: null,
          lastMessageTimestamp: null,
          status: "active",
        });
      });

      logger.info(`Match Created: ${matchId}`);

      // Ambil FCM token setelah transaction
      const [userSnapA, userSnapB] = await Promise.all([
        db.collection("users").doc(uids[0]).get(),
        db.collection("users").doc(uids[1]).get(),
      ]);

      const tokenA = userSnapA.data()?.fcmToken;
      const tokenB = userSnapB.data()?.fcmToken;

      const sendNotification = async (token, title, body) => {
        if (!token) return;
        try {
          await messaging.send({
            token,
            notification: { title, body },
            data: { type: "new_match", matchId },
          });
        } catch (e) {
          logger.error("FCM error", e);
        }
      };

      await Promise.all([
        sendNotification(tokenA, "🎉 Kamu Match!", `Kamu match dengan ${userSnapB.data()?.displayName || "User"}!`),
        sendNotification(tokenB, "🎉 Kamu Match!", `Kamu match dengan ${userSnapA.data()?.displayName || "User"}!`),
      ]);

    } catch (error) {
      logger.error("Match Detection Fail", error);
    }
  }
);
