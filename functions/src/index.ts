import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

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

export const detectMatch = onDocumentCreated(
  {
    document: "likes/{userId}/liked/{targetId}",
    region: "asia-southeast2",
    timeoutSeconds: 90,
    memory: "512MiB",
    minInstances: 0,
    maxInstances: 10,
  },
  async (event) => {
    const userId = event.params.userId as string;
    const targetId = event.params.targetId as string;

    if (!userId || !targetId || userId === targetId) {
      logger.info("Invalid like: self-like or missing params", { userId, targetId });
      return;
    }

    logger.info(`New like detected: ${userId} → ${targetId}`);

    try {
      // Cek apakah ada like balik (reciprocal)
      const reciprocalRef = db
        .collection("likes")
        .doc(targetId)
        .collection("liked")
        .doc(userId);

      const reciprocalSnap = await reciprocalRef.get();

      if (!reciprocalSnap.exists) {
        logger.info(`No reciprocal like from ${targetId} to ${userId}`);
        return;
      }

      // Buat matchId yang konsisten (uid kecil dulu)
      const uids = [userId, targetId].sort((a, b) => a.localeCompare(b));
      const matchId = `${uids[0]}_${uids[1]}`;

      const matchRef = db.collection("matches").doc(matchId);

      // Cek apakah match sudah ada (hindari duplikat)
      const matchSnap = await matchRef.get();
      if (matchSnap.exists) {
        logger.info(`Match already exists: ${matchId}`);
        return;
      }

      // Ambil data profil dan user
      const [profileSnapA, profileSnapB, userSnapA, userSnapB] = await Promise.all([
        db.collection("profiles").doc(userId).get(),
        db.collection("profiles").doc(targetId).get(),
        db.collection("users").doc(userId).get(),
        db.collection("users").doc(targetId).get(),
      ]);

      // Ambil nama dan foto dengan fallback aman
      const profileA = profileSnapA.exists ? (profileSnapA.data() as ProfileData) : {};
      const profileB = profileSnapB.exists ? (profileSnapB.data() as ProfileData) : {};

      const nameA = profileA.displayName || "Pengguna";
      const nameB = profileB.displayName || "Pengguna";
      const photoA = profileA.photoUrl || "";
      const photoB = profileB.photoUrl || "";

      // Struktur data match yang lebih fleksibel
      await matchRef.set({
        users: uids,                    // array [uid1, uid2] → memudahkan query di client
        user1Id: uids[0],
        user2Id: uids[1],
        user1Name: nameA,
        user2Name: nameB,
        user1PhotoUrl: photoA,
        user2PhotoUrl: photoB,
        createdAt: FieldValue.serverTimestamp(),
        lastActivityAt: FieldValue.serverTimestamp(),
        lastMessageAt: null,
        status: "active",               // bisa digunakan untuk block/unmatch nanti
      });

      logger.info(`Match created successfully: ${matchId} (${nameA} ↔ ${nameB})`);

      // Siapkan push notification
      const tokenA = userSnapA.exists ? (userSnapA.data() as UserData)?.fcmToken : null;
      const tokenB = userSnapB.exists ? (userSnapB.data() as UserData)?.fcmToken : null;

      const notifications: Array<Promise<any>> = [];

      // Notifikasi ke user A
      if (tokenA) {
        notifications.push(
          messaging.send({
            token: tokenA,
            notification: {
              title: "🎉 Kamu Match!",
              body: `Kamu match dengan ${nameB}!`,
            },
            data: {
              type: "new_match",
              matchId,
              otherUserId: targetId,
              otherUserName: nameB,
              otherUserPhoto: photoB,
            },
            android: { priority: "high" },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  contentAvailable: true,
                },
              },
            },
          })
        );
      }

      // Notifikasi ke user B
      if (tokenB) {
        notifications.push(
          messaging.send({
            token: tokenB,
            notification: {
              title: "🎉 Kamu Match!",
              body: `Kamu match dengan ${nameA}!`,
            },
            data: {
              type: "new_match",
              matchId,
              otherUserId: userId,
              otherUserName: nameA,
              otherUserPhoto: photoA,
            },
            android: { priority: "high" },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  contentAvailable: true,
                },
              },
            },
          })
        );
      }

      if (notifications.length > 0) {
        await Promise.allSettled(notifications); // gunakan allSettled agar satu gagal tidak stop yang lain
        logger.info(`Push notifications processed for match ${matchId} (${notifications.length} sent)`);
      }
    } catch (error) {
      logger.error("Error in match detection", {
        userId,
        targetId,
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      });
    }
  }
);