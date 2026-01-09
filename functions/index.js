
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onNewMatch = functions.firestore
    .document("matches/{matchId}")
    .onCreate(async (snap, context) => {
      const matchData = snap.data();
      const users = matchData.users;

      if (!users || users.length !== 2) {
        console.log("Invalid users array in match document.");
        return null;
      }

      const user1Id = users[0];
      const user2Id = users[1];

      // Get both users' profiles to find their names and FCM tokens
      const user1ProfileDoc = await admin.firestore().collection("profiles").doc(user1Id).get();
      const user2ProfileDoc = await admin.firestore().collection("profiles").doc(user2Id).get();

      if (!user1ProfileDoc.exists || !user2ProfileDoc.exists) {
        console.log("One or both user profiles not found.");
        return null;
      }

      const user1Profile = user1ProfileDoc.data();
      const user2Profile = user2ProfileDoc.data();

      const fcmToken1 = user1Profile.fcmToken;
      const fcmToken2 = user2Profile.fcmToken;

      // Notification for User 1
      if (fcmToken1) {
        const payload1 = {
          notification: {
            title: "You have a new match!",
            body: `You matched with ${user2Profile.name}! 🎉`,
            clickAction: "FLUTTER_NOTIFICATION_CLICK", // Important for Flutter
          },
          data: {
              matchId: context.params.matchId,
              matchedUserId: user2Id
          }
        };
        try {
            await admin.messaging().sendToDevice(fcmToken1, payload1);
            console.log(`Notification sent to ${user1Profile.name}`);
        } catch(error) {
            console.error(`Error sending notification to ${user1Profile.name}:`, error);
        }
      }

      // Notification for User 2
      if (fcmToken2) {
        const payload2 = {
          notification: {
            title: "You have a new match!",
            body: `You matched with ${user1Profile.name}! 🎉`,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
           data: {
              matchId: context.params.matchId,
              matchedUserId: user1Id
          }
        };
         try {
            await admin.messaging().sendToDevice(fcmToken2, payload2);
            console.log(`Notification sent to ${user2Profile.name}`);
        } catch(error) {
            console.error(`Error sending notification to ${user2Profile.name}:`, error);
        }
      }

      return null;
    });
