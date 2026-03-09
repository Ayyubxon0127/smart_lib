const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Triggered whenever a new document is written to `notifications/{notifId}`.
 * Fetches the target user's FCM token and sends a push notification.
 *
 * Expected notification document fields:
 *   userId      : String  — recipient uid
 *   title       : String  — notification title
 *   message     : String  — notification body
 *   type        : String  — NotifType constant (bookRequest, arrivalConfirmed, …)
 *   targetScreen: String? — screen to open on tap (NotifScreen constant)
 *   targetId    : String? — e.g. bookId for bookDetail navigation
 *   isRead      : bool    — always false on creation
 *   createdAt   : Timestamp
 */
exports.sendPushOnNotification = onDocumentCreated(
  "notifications/{notifId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return null;

    const { userId, title, message, targetScreen, targetId } = data;
    if (!userId || !title) return null;

    // Fetch the recipient's FCM token
    const userSnap = await db.collection("users").doc(userId).get();
    if (!userSnap.exists) return null;

    const fcmToken = userSnap.data()?.fcmToken;
    if (!fcmToken || typeof fcmToken !== "string") return null;

    // Build the FCM message (v1 API via Admin SDK)
    const fcmMessage = {
      token: fcmToken,
      notification: {
        title: title,
        body: message ?? "",
      },
      data: {
        // These are picked up by FcmService._handlePayload on the Flutter side
        targetScreen: targetScreen ?? "",
        targetId: targetId ?? "",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "fcm_high",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      await messaging.send(fcmMessage);
    } catch (err) {
      // Token may be stale — clear it so we don't retry
      if (
        err.code === "messaging/registration-token-not-registered" ||
        err.code === "messaging/invalid-registration-token"
      ) {
        await db.collection("users").doc(userId).update({ fcmToken: null });
      }
      console.error("FCM send error:", err.code, err.message);
    }

    return null;
  }
);
