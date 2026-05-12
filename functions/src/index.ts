// ============================================================
// 📁 functions/src/index.ts
// ✅ Cloud Functions for SEPADAN App
// ✅ All notifications: dailyDevo, newMatch, newMessage
// ============================================================

import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Initialize
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// ─────────────────────────────────────────────────────────
// HELPER: Check if notification is enabled
// Returns TRUE if:
//   - notificationSettings doesn't exist (default ON)
//   - notificationSettings.[type] doesn't exist (default ON)
//   - notificationSettings.[type] === true
// Returns FALSE only if notificationSettings.[type] === false
// ─────────────────────────────────────────────────────────
function isNotificationEnabled(
  userData: FirebaseFirestore.DocumentData | undefined,
  type: "dailyDevo" | "newMatch" | "newMessage"
): boolean {
  if (!userData) return false;
  if (!userData.fcmToken) return false;
  
  // If no notificationSettings, default to enabled
  if (!userData.notificationSettings) return true;
  
  // If specific setting doesn't exist, default to enabled
  if (userData.notificationSettings[type] === undefined) return true;
  
  // Return the actual setting
  return userData.notificationSettings[type] === true;
}

// ─────────────────────────────────────────────────────────
// TEST FUNCTION
// ─────────────────────────────────────────────────────────
export const helloWorld = onRequest(
  { region: "asia-southeast2" },
  (req, res) => {
    res.send("Hello from SEPADAN! Functions are working.");
  }
);

// ─────────────────────────────────────────────────────────
// 1. DAILY DEVOTIONAL - 5:00 AM WIB
// ─────────────────────────────────────────────────────────
export const sendDailyDevotional = onSchedule(
  {
    schedule: "0 5 * * *",
    timeZone: "Asia/Jakarta",
    region: "asia-southeast2",
  },
  async () => {
    console.log("🕔 sendDailyDevotional started at 5:00 AM WIB");

    try {
      // ✅ FIX: Calculate today in WIB (UTC+7), not UTC
      // When this runs at 5:00 AM WIB = 22:00 UTC previous day
      // So we need to use WIB time to get correct "today"
      const now = new Date();
      const wibOffset = 7 * 60 * 60 * 1000; // UTC+7 in milliseconds
      const wibNow = new Date(now.getTime() + wibOffset);
      
      // Get start of today in WIB, then convert back to UTC for Firestore query
      const todayWIB = new Date(wibNow.getFullYear(), wibNow.getMonth(), wibNow.getDate());
      const todayUTC = new Date(todayWIB.getTime() - wibOffset);
      
      const tomorrowUTC = new Date(todayUTC.getTime() + 24 * 60 * 60 * 1000);

      console.log(`📅 Today WIB: ${todayWIB.toISOString()}, Query range: ${todayUTC.toISOString()} - ${tomorrowUTC.toISOString()}`);

      const devoSnap = await db
        .collection("daily_devotionals")
        .where("date", ">=", Timestamp.fromDate(todayUTC))
        .where("date", "<", Timestamp.fromDate(tomorrowUTC))
        .limit(1)
        .get();

      if (devoSnap.empty) {
        // Fallback: get the latest devotional up to today
        console.log("⚠️ No devotional for exact today, trying latest...");
        const fallbackSnap = await db
          .collection("daily_devotionals")
          .where("date", "<=", Timestamp.fromDate(tomorrowUTC))
          .orderBy("date", "desc")
          .limit(1)
          .get();
        
        if (fallbackSnap.empty) {
          console.log("❌ No devotional found at all");
          return;
        }

        const devo = fallbackSnap.docs[0].data();
        const devoTitle = devo.title || "Renungan Hari Ini";
        console.log(`📖 Fallback devotional: "${devoTitle}"`);
        
        await _sendDevoNotification(devoTitle, fallbackSnap.docs[0].id);
        return;
      }

      const devo = devoSnap.docs[0].data();
      const devoTitle = devo.title || "Renungan Hari Ini";
      console.log(`📖 Today's devotional: "${devoTitle}"`);

      await _sendDevoNotification(devoTitle, devoSnap.docs[0].id);
    } catch (error) {
      console.error("❌ Error:", error);
    }
  }
);

// ─────────────────────────────────────────────────────────
// HELPER: Send devotional notification to all eligible users
// ─────────────────────────────────────────────────────────
async function _sendDevoNotification(devoTitle: string, devoId: string) {
  const usersSnap = await db.collection("users").get();

  const tokens: string[] = [];
  usersSnap.forEach((doc) => {
    const data = doc.data();
    if (isNotificationEnabled(data, "dailyDevo")) {
      tokens.push(data.fcmToken);
    }
  });

  if (tokens.length === 0) {
    console.log("❌ No eligible users found");
    return;
  }

  console.log(`📤 Sending to ${tokens.length} users`);

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: "📖 Renungan Hari Ini",
      body: devoTitle,
    },
    data: {
      type: "daily_devotional",
      devoId: devoId,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "daily_devotional",
      },
    },
  });

  console.log(`✅ Success: ${response.successCount}, Failed: ${response.failureCount}`);
}

// ─────────────────────────────────────────────────────────
// 2. DETECT MATCH - When user likes someone who liked them back
// ─────────────────────────────────────────────────────────
export const detectMatch = onDocumentCreated(
  {
    document: "likes/{userId}/liked/{targetId}",
    region: "asia-southeast2",
  },
  async (event) => {
    const { userId, targetId } = event.params;
    console.log(`💕 Checking match: ${userId} → ${targetId}`);

    try {
      // Check if target has liked this user back
      const reverseLike = await db
        .collection("likes")
        .doc(targetId)
        .collection("liked")
        .doc(userId)
        .get();

      if (!reverseLike.exists) {
        console.log("❌ No reverse like, no match");
        return;
      }

      // Check if match already exists
      const existingMatches = await db
        .collection("matches")
        .where("users", "array-contains", userId)
        .get();

      for (const doc of existingMatches.docs) {
        const users = doc.data().users as string[];
        if (users.includes(targetId)) {
          console.log("⏭️ Match already exists");
          return;
        }
      }

      // Create new match
      const matchRef = db.collection("matches").doc();
      await matchRef.set({
        users: [userId, targetId],
        user1Id: userId,
        user2Id: targetId,
        createdAt: Timestamp.now(),
        lastActivityAt: Timestamp.now(),
        lastMessage: null,
      });

      console.log(`✅ Match created: ${matchRef.id}`);

      // Get profiles and user data for notifications
      const [profile1, profile2, user1, user2] = await Promise.all([
        db.collection("profiles").doc(userId).get(),
        db.collection("profiles").doc(targetId).get(),
        db.collection("users").doc(userId).get(),
        db.collection("users").doc(targetId).get(),
      ]);

      const name1 = profile1.data()?.name || "Seseorang";
      const name2 = profile2.data()?.name || "Seseorang";
      const photo1 = profile1.data()?.photos?.[0] || "";
      const photo2 = profile2.data()?.photos?.[0] || "";

      // Send notification to user1 if enabled
      if (isNotificationEnabled(user1.data(), "newMatch")) {
        await messaging.send({
          token: user1.data()!.fcmToken,
          notification: {
            title: "💕 It's a Match!",
            body: `Kamu dan ${name2} saling menyukai!`,
          },
          data: {
            type: "new_match",
            matchId: matchRef.id,
            otherUserId: targetId,
            otherUserName: name2,
            otherUserPhoto: photo2,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "matches",
            },
          },
        });
        console.log(`📤 Match notification sent to ${userId}`);
      }

      // Send notification to user2 if enabled
      if (isNotificationEnabled(user2.data(), "newMatch")) {
        await messaging.send({
          token: user2.data()!.fcmToken,
          notification: {
            title: "💕 It's a Match!",
            body: `Kamu dan ${name1} saling menyukai!`,
          },
          data: {
            type: "new_match",
            matchId: matchRef.id,
            otherUserId: userId,
            otherUserName: name1,
            otherUserPhoto: photo1,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "matches",
            },
          },
        });
        console.log(`📤 Match notification sent to ${targetId}`);
      }
    } catch (error) {
      console.error("❌ Error in detectMatch:", error);
    }
  }
);

// ─────────────────────────────────────────────────────────
// 3. NEW MESSAGE NOTIFICATION
// ─────────────────────────────────────────────────────────
export const onNewMessage = onDocumentCreated(
  {
    document: "matches/{matchId}/messages/{msgId}",
    region: "asia-southeast2",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const matchId = event.params.matchId;
    const senderId = data.senderId as string;
    const text = (data.text as string) || "Sent a message";

    console.log(`💬 New message in match ${matchId} from ${senderId}`);

    try {
      // Get match document
      const matchDoc = await db.collection("matches").doc(matchId).get();
      if (!matchDoc.exists) return;

      const matchData = matchDoc.data()!;
      const users = matchData.users as string[];
      const receiverId = users.find((u) => u !== senderId);

      if (!receiverId) return;

      // Get receiver and sender data
      const [receiverDoc, senderProfile] = await Promise.all([
        db.collection("users").doc(receiverId).get(),
        db.collection("profiles").doc(senderId).get(),
      ]);

      const receiverData = receiverDoc.data();
      const senderName = senderProfile.data()?.name || "Seseorang";
      const senderPhoto = senderProfile.data()?.photos?.[0] || "";

      // Check if notification is enabled
      if (!isNotificationEnabled(receiverData, "newMessage")) {
        console.log("⏭️ Receiver has disabled message notifications");
        return;
      }

      // Send notification
      await messaging.send({
        token: receiverData!.fcmToken,
        notification: {
          title: senderName,
          body: text.length > 100 ? text.substring(0, 97) + "..." : text,
        },
        data: {
          type: "new_message",
          matchId: matchId,
          senderId: senderId,
          senderName: senderName,
          senderPhoto: senderPhoto,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "messages",
          },
        },
      });

      console.log(`📤 Message notification sent to ${receiverId}`);

      // Update match's lastActivityAt and lastMessage
      await matchDoc.ref.update({
        lastActivityAt: Timestamp.now(),
        lastMessage: {
          text: text,
          senderId: senderId,
          timestamp: Timestamp.now(),
        },
      });
    } catch (error) {
      console.error("❌ Error in onNewMessage:", error);
    }
  }
);

// ─────────────────────────────────────────────────────────
// 4. TEST ENDPOINT - Check notification setup
// ─────────────────────────────────────────────────────────
export const testNotificationSetup = onRequest(
  { region: "asia-southeast2" },
  async (req, res) => {
    try {
      // Check daily devotionals
      const devoSnap = await db
        .collection("daily_devotionals")
        .orderBy("date", "desc")
        .limit(1)
        .get();

      // Check users
      const usersSnap = await db.collection("users").get();

      let usersWithToken = 0;
      let usersWithDailyDevo = 0;
      let usersWithNewMatch = 0;
      let usersWithNewMessage = 0;

      usersSnap.forEach((doc) => {
        const data = doc.data();
        if (data.fcmToken) usersWithToken++;
        if (isNotificationEnabled(data, "dailyDevo")) usersWithDailyDevo++;
        if (isNotificationEnabled(data, "newMatch")) usersWithNewMatch++;
        if (isNotificationEnabled(data, "newMessage")) usersWithNewMessage++;
      });

      res.json({
        success: true,
        devotional: {
          found: !devoSnap.empty,
          latestTitle: devoSnap.docs[0]?.data()?.title || "N/A",
          latestDate: devoSnap.docs[0]?.data()?.date?.toDate() || "N/A",
        },
        users: {
          total: usersSnap.size,
          withFcmToken: usersWithToken,
          dailyDevoEnabled: usersWithDailyDevo,
          newMatchEnabled: usersWithNewMatch,
          newMessageEnabled: usersWithNewMessage,
        },
      });
    } catch (error) {
      res.status(500).json({ error: String(error) });
    }
  }
);