import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Inisialisasi Admin SDK
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

interface ProfileData {
  displayName?: string;
  photoUrl?: string;
  [key: string]: any;
}

interface UserData {
  fcmToken?: string;
  [key: string]: any;
}

/**
 * 1. TRIGGER: Saat ada Like Baru
 * Fungsi untuk mendeteksi Mutual Like dan membuat dokumen Match
 */
export const detectMatch = onDocumentCreated(
  {
    document: "likes/{userId}/liked/{targetId}",
    region: "asia-southeast2",
    timeoutSeconds: 90,
    memory: "512MiB",
  },
  async (event) => {
    const userId = event.params.userId as string;
    const targetId = event.params.targetId as string;

    if (!userId || !targetId || userId === targetId) return;

    try {
      // Cek apakah ada like balik
      const reciprocalSnap = await db
        .collection("likes")
        .doc(targetId)
        .collection("liked")
        .doc(userId)
        .get();

      if (!reciprocalSnap.exists) return;

      // Buat matchId yang konsisten (alfabetis)
      const uids = [userId, targetId].sort((a, b) => a.localeCompare(b));
      const matchId = `${uids[0]}_${uids[1]}`;
      const matchRef = db.collection("matches").doc(matchId);

      const matchSnap = await matchRef.get();
      if (matchSnap.exists) return;

      // Ambil data profil & FCM token
      const [profileSnapA, profileSnapB, userSnapA, userSnapB] = await Promise.all([
        db.collection("profiles").doc(userId).get(),
        db.collection("profiles").doc(targetId).get(),
        db.collection("users").doc(userId).get(),
        db.collection("users").doc(targetId).get(),
      ]);

      const profileA = profileSnapA.data() as ProfileData;
      const profileB = profileSnapB.data() as ProfileData;
      const nameA = profileA?.displayName || "Pengguna";
      const nameB = profileB?.displayName || "Pengguna";

      // Buat dokumen Match
      await matchRef.set({
        users: uids,
        user1Id: uids[0],
        user2Id: uids[1],
        user1Name: uids[0] === userId ? nameA : nameB,
        user2Name: uids[1] === userId ? nameA : nameB,
        user1PhotoUrl: uids[0] === userId ? (profileA?.photoUrl || "") : (profileB?.photoUrl || ""),
        user2PhotoUrl: uids[1] === userId ? (profileA?.photoUrl || "") : (profileB?.photoUrl || ""),
        createdAt: FieldValue.serverTimestamp(),
        lastActivityAt: FieldValue.serverTimestamp(),
        lastMessage: "Kalian telah cocok! Silakan mulai menyapa.",
        lastMessageTimestamp: FieldValue.serverTimestamp(),
        status: "active",
      });

      logger.info(`Match Created: ${matchId}`);

      // Kirim Notifikasi Match
      const tokens = [
        (userSnapA.data() as UserData)?.fcmToken,
        (userSnapB.data() as UserData)?.fcmToken,
      ].filter(t => t);

      if (tokens.length > 0) {
        const payload = tokens.map(token => ({
          token,
          notification: {
            title: "🎉 Kamu Match!",
            body: `Kamu match dengan seseorang yang baru!`,
          },
          data: { type: "new_match", matchId },
        }));
        // @ts-ignore
        await Promise.all(payload.map(p => messaging.send(p)));
      }
    } catch (error) {
      logger.error("Error in detectMatch", error);
    }
  }
);

/**
 * 2. TRIGGER: Saat ada Pesan Chat Baru
 * Fungsi untuk mengirim push notification ke penerima pesan
 */
export const onMessageCreated = onDocumentCreated(
  {
    document: "matches/{matchId}/messages/{messageId}",
    region: "asia-southeast2",
  },
  async (event) => {
    const { matchId } = event.params;
    const messageData = event.data?.data();
    if (!messageData) return;

    const senderId = messageData.senderId;

    try {
      // 1. Cari tahu siapa penerimanya
      const matchSnap = await db.collection("matches").doc(matchId).get();
      const matchData = matchSnap.data();
      if (!matchData) return;

      const uids: string[] = matchData.users;
      const receiverId = uids.find(id => id !== senderId);
      if (!receiverId) return;

      // 2. Ambil token FCM penerima
      const receiverSnap = await db.collection("users").doc(receiverId).get();
      const token = (receiverSnap.data() as UserData)?.fcmToken;

      if (token) {
        const senderName = matchData.user1Id === senderId ? matchData.user1Name : matchData.user2Name;
        
        await messaging.send({
          token: token,
          notification: {
            title: `Pesan dari ${senderName}`,
            body: messageData.text,
          },
          data: { 
            type: "new_message", 
            matchId,
            senderId 
          },
        });
        logger.info(`Notif chat dikirim ke ${receiverId}`);
      }
    } catch (e) {
      logger.error("Gagal kirim notif chat", e);
    }
  }
);
