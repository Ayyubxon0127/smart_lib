const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
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

/**
 * Triggered on new book reservation (reservations collection).
 * Notify all librarians about the new book request.
 */
exports.notifyLibrariansOnNewBookRequest = onDocumentCreated(
  "reservations/{resId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return null;

    const studentName = data.studentName || "Talaba";
    const bookId = data.bookId || "";
    const resId = event.params.resId;

    if (!bookId) return null;

    // Fetch book title
    let bookTitle = "Kitob";
    try {
      const bookSnap = await db.collection("books").doc(bookId).get();
      if (bookSnap.exists) {
        bookTitle = bookSnap.data()?.title || "Kitob";
      }
    } catch (err) {
      console.error("Error fetching book:", err);
    }

    // Get all librarians
    const librarians = await db
      .collection("users")
      .where("role", "==", "librarian")
      .get();

    if (librarians.empty) return null;

    // Create notification for each librarian
    const batch = db.batch();
    for (const librarianDoc of librarians.docs) {
      const notifRef = db.collection("notifications").doc();
      batch.set(notifRef, {
        userId: librarianDoc.id,
        title: "Yangi kitob so'rovi 📚",
        message: `${studentName} "${bookTitle}" kitobini so'radi`,
        type: "book_request",
        targetScreen: "reservations",
        targetId: resId,
        createdAt: new Date(),
        isRead: false,
      });
    }

    await batch.commit();
    return null;
  }
);

/**
 * Triggered when seat_booking status changes to "arrived".
 * Notify all librarians that a student has arrived.
 */
exports.notifyLibrariansOnStudentArrival = onDocumentUpdated(
  "seat_bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return null;

    // Only fire when status transitions to "arrived".
    if (before.status === after.status || after.status !== "arrived") {
      return null;
    }

    const studentName = after.studentName || "Talaba";
    const roomName = after.roomName || "Xona";
    const bookingId = event.params.bookingId;

    const librarians = await db
      .collection("users")
      .where("role", "==", "librarian")
      .get();

    if (librarians.empty) return null;

    const batch = db.batch();
    for (const librarianDoc of librarians.docs) {
      const notifRef = db.collection("notifications").doc();
      batch.set(notifRef, {
        userId: librarianDoc.id,
        title: "Talaba keldi 🟢",
        message: `${studentName} ${roomName} xonasiga keldi`,
        type: "arrival_confirmed",
        targetScreen: "rooms",
        targetId: bookingId,
        createdAt: new Date(),
        isRead: false,
      });
    }

    await batch.commit();
    return null;
  }
);

/**
 * Keep books/{bookId}.rating and reviewCount in sync with reviews subcollection.
 */
exports.aggregateBookRatingOnReviewWrite = onDocumentWritten(
  "books/{bookId}/reviews/{reviewId}",
  async (event) => {
    const { bookId } = event.params;
    if (!bookId) return null;

    const reviewsSnap = await db
      .collection("books")
      .doc(bookId)
      .collection("reviews")
      .get();

    const reviewCount = reviewsSnap.size;
    let rating = 0;

    if (reviewCount > 0) {
      let total = 0;
      for (const doc of reviewsSnap.docs) {
        const val = Number(doc.data()?.rating ?? 0);
        total += Number.isFinite(val) ? val : 0;
      }
      rating = total / reviewCount;
    }

    await db.collection("books").doc(bookId).update({
      rating,
      reviewCount,
    });

    return null;
  }
);
