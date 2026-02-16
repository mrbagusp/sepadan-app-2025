import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Inisialisasi Admin SDK secara global namun efisien
const app = initializeApp();
const db = getFirestore(app);
const messaging = getMessaging(app);

/**
 * 1. TRIGGER: Matchmaking Otomatis (Mutual Like)
 */
export const detectMatch = onDocumentCreated({
  document: "likes/{userId}/liked/{targetId}",
  region: "asia-southeast2",
  memory: "256MiB",
}, async (event) => {
  const { userId, targetId } = event.params;
  if (!userId || !targetId || userId === targetId) return;

  try {
    const reciprocalSnap = await db.collection("likes").doc(targetId).collection("liked").doc(userId).get();
    if (!reciprocalSnap.exists) return;

    const uids = [userId, targetId].sort();
    const matchId = uids.join("_");
    const matchRef = db.collection("matches").doc(matchId);

    const matchSnap = await matchRef.get();
    if (matchSnap.exists) return;

    const [pA, pB, uA, uB] = await Promise.all([
      db.collection("profiles").doc(userId).get(),
      db.collection("profiles").doc(targetId).get(),
      db.collection("users").doc(userId).get(),
      db.collection("users").doc(targetId).get(),
    ]);

    const nameA = pA.data()?.displayName || "User";
    const nameB = pB.data()?.displayName || "User";
    const photoA = pA.data()?.photoUrl || "";
    const photoB = pB.data()?.photoUrl || "";

    await matchRef.set({
      users: uids,
      user1Id: uids[0],
      user2Id: uids[1],
      user1Name: uids[0] === userId ? nameA : nameB,
      user2Name: uids[1] === userId ? nameA : nameB,
      user1PhotoUrl: uids[0] === userId ? photoA : photoB,
      user2PhotoUrl: uids[1] === userId ? photoA : photoB,
      createdAt: FieldValue.serverTimestamp(),
      lastActivityAt: FieldValue.serverTimestamp(),
      lastMessage: "Kalian telah cocok! Silakan mulai menyapa.",
      lastMessageTimestamp: FieldValue.serverTimestamp(),
      status: "active",
    });

    // Kirim Notifikasi Match
    const tokens = [uA.data()?.fcmToken, uB.data()?.fcmToken].filter(t => t);
    if (tokens.length > 0) {
      await messaging.sendEach(tokens.map(token => ({
        token,
        notification: { title: "🎉 Kamu Match!", body: "Kamu memiliki kecocokan baru di Sepadan!" },
        data: { type: "new_match", matchId },
      })));
    }
  } catch (error) {
    logger.error("detectMatch error", error);
  }
});

/**
 * 2. TRIGGER: Notifikasi Chat Baru
 */
export const onMessageCreated = onDocumentCreated({
  document: "matches/{matchId}/messages/{messageId}",
  region: "asia-southeast2",
  memory: "256MiB",
}, async (event) => {
  const { matchId } = event.params;
  const msgData = event.data?.data();
  if (!msgData) return;

  try {
    const matchSnap = await db.collection("matches").doc(matchId).get();
    const matchData = matchSnap.data();
    if (!matchData) return;

    const receiverId = matchData.users.find((id: string) => id !== msgData.senderId);
    const receiverSnap = await db.collection("users").doc(receiverId).get();
    const token = receiverSnap.data()?.fcmToken;

    if (token) {
      const senderName = matchData.user1Id === msgData.senderId ? matchData.user1Name : matchData.user2Name;
      await messaging.send({
        token,
        notification: { title: senderName, body: msgData.text },
        data: { type: "new_message", matchId },
      });
    }
  } catch (error) {
    logger.error("onMessageCreated error", error);
  }
});

/**
 * 3. SCHEDULED: Notifikasi Renungan Pagi (06:00 WIB)
 */
export const sendDailyDevotional = onSchedule({
  schedule: "0 6 * * *",
  timeZone: "Asia/Jakarta",
  region: "asia-southeast2",
}, async () => {
  try {
    const devoSnap = await db.collection("daily_devotionals").orderBy("date", "desc").limit(1).get();
    if (devoSnap.empty) return;

    const devo = devoSnap.docs[0].data();
    const usersSnap = await db.collection("users").where("notificationSettings.dailyDevo", "==", true).get();
    const tokens = usersSnap.docs.map(d => d.data().fcmToken).filter(t => t);

    if (tokens.length > 0) {
      const chunks = [];
      for (let i = 0; i < tokens.length; i += 500) chunks.push(tokens.slice(i, i + 500));
      for (const chunk of chunks) {
        await messaging.sendEachForMulticast({
          tokens: chunk,
          notification: { title: `📖 ${devo.title}`, body: devo.content?.substring(0, 100) + "..." },
          data: { type: "daily_devo", id: devoSnap.docs[0].id },
        });
      }
    }
  } catch (error) {
    logger.error("sendDailyDevotional error", error);
  }
});
