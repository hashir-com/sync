// src/index.ts - COMPLETE CLEAN VERSION
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

admin.initializeApp();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

console.log("Firebase Functions initialized GEMINI_API_KEY is set:", !!process.env.GEMINI_API_KEY);

// Use environment variables for Gmail credentials
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

// ========== SCHEDULED FUNCTIONS ==========

export const deleteExpiredEvents = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "UTC",
  },
  async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    logger.info("Running expired events cleanup job");

    const snapshot = await db
      .collection("events")
      .where("endTime", "<", now)
      .get();

    if (snapshot.empty) {
      logger.info("No expired events found");
      return;
    }

    const batch = db.batch();
    let deleteCount = 0;

    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      deleteCount++;
    });

    await batch.commit();

    logger.info(`Deleted ${deleteCount} expired events`);
  }
);

// ========== EMAIL FUNCTIONS ==========

export const sendBookingConfirmationEmail = onDocumentCreated(
  { document: "bookings/{bookingId}" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const bookingData = snap.data();
    const userEmail = bookingData.userEmail;
    const amount = bookingData.totalAmount;
    const bookingId = event.params.bookingId;

    if (!userEmail) {
      logger.error("Booking has no userEmail");
      return;
    }

    let eventTitle = bookingData.eventId;
    let organizerName = "";
    let startTimeText = "";
    let endTimeText = "";
    try {
      const eventSnap = await admin
        .firestore()
        .collection("events")
        .doc(bookingData.eventId)
        .get();
      if (eventSnap.exists) {
        const ev = eventSnap.data() as any;
        eventTitle = ev.title || eventTitle;
        organizerName = ev.organizerName || "";
      }
      const st = bookingData.startTime?.toDate?.() || new Date();
      const et = bookingData.endTime?.toDate?.() || new Date();
      startTimeText = st.toLocaleString();
      endTimeText = et.toLocaleString();
    } catch {}

    const mailOptions = {
      from: `"Sync Event" <${process.env.GMAIL_USER}>`,
      to: userEmail,
      subject: `Booking Confirmed • ${bookingData.ticketType?.toUpperCase()} x${
        bookingData.ticketQuantity
      }`,
      html: `
        <div style="font-family: Inter,system-ui,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:640px;margin:auto;padding:24px;background:#f7f7fb">
          <div style="background:#ffffff;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.06);overflow:hidden">
            <div style="background:#111827;color:#fff;padding:16px 20px">
              <h2 style="margin:0;font-size:18px">Sync Event</h2>
            </div>
            <div style="padding:20px">
              <h3 style="margin-top:0">Your booking is confirmed</h3>
              <p style="color:#374151">Thanks for booking with Sync Event. Here are your details:</p>
              <table style="width:100%;border-collapse:collapse">
                <tr><td style="padding:6px 0;color:#6b7280">Booking ID</td><td style="padding:6px 0;text-align:right">${bookingId}</td></tr>
                <tr><td style="padding:6px 0;color:#6b7280">Event</td><td style="padding:6px 0;text-align:right">${eventTitle}</td></tr>
                <tr><td style="padding:6px 0;color:#6b7280">Organizer</td><td style="padding:6px 0;text-align:right">${organizerName}</td></tr>
                <tr><td style="padding:6px 0;color:#6b7280">Ticket</td><td style="padding:6px 0;text-align:right">${bookingData.ticketType?.toUpperCase()} × ${
        bookingData.ticketQuantity
      }</td></tr>
                <tr><td style="padding:6px 0;color:#6b7280">Amount</td><td style="padding:6px 0;text-align:right">₹${amount}</td></tr>
                <tr><td style="padding:6px 0;color:#6b7280">Event Time</td><td style="padding:6px 0;text-align:right">${startTimeText} - ${endTimeText}</td></tr>
                <tr><td style="padding:6px 0;color:#6b7280">Status</td><td style="padding:6px 0;text-align:right">${
        bookingData.status
      }</td></tr>
              </table>
              <p style="margin-top:16px;color:#6b7280;font-size:12px">Cancellation policy: Refunds subject to organizer policy. Bank refunds may take 5-7 business days.</p>
            </div>
          </div>
        </div>
      `,
    } as nodemailer.SendMailOptions;

    try {
      await transporter.sendMail(mailOptions);
      logger.info(`Booking confirmation email sent to ${userEmail}`);
    } catch (error) {
      logger.error("Failed to send email", error);
    }
  }
);

export const handleRefundRequests = onDocumentCreated(
  { document: "refundRequests/{requestId}" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as any;
    const { bookingId, refundType } = data;
    const requestRef = snap.ref;

    try {
      const bookingRef = admin
        .firestore()
        .collection("bookings")
        .doc(bookingId);
      const bookingSnap = await bookingRef.get();
      if (!bookingSnap.exists) throw new Error("Booking not found");
      const booking = bookingSnap.data() as any;

      if (booking.status === "refunded") {
        await requestRef.update({
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const amount = Number(booking.totalAmount || 0);
      if (refundType === "wallet") {
        const walletRef = admin
          .firestore()
          .collection("wallets")
          .doc(booking.userId);
        await admin.firestore().runTransaction(async (tx) => {
          const w = await tx.get(walletRef);
          const current = w.exists ? (w.data() as any).balance || 0 : 0;
          tx.set(
            walletRef,
            { userId: booking.userId, balance: current + amount },
            { merge: true }
          );
          tx.update(bookingRef, { status: "refunded", refundAmount: amount });
        });
      } else {
        const paymentId = booking.paymentId;
        const key = process.env.RAZORPAY_KEY_ID as string;
        const secret = process.env.RAZORPAY_KEY_SECRET as string;
        const credentials = Buffer.from(`${key}:${secret}`).toString("base64");
        const resp = await fetch(
          `https://api.razorpay.com/v1/payments/${paymentId}/refund`,
          {
            method: "POST",
            headers: {
              Authorization: `Basic ${credentials}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ amount: Math.round(amount * 100) }),
          }
        );
        if (!resp.ok) {
          const text = await resp.text();
          throw new Error(`Razorpay refund failed: ${text}`);
        }
        await bookingRef.update({ status: "refunded", refundAmount: amount });
      }

      const mailOptions = {
        from: `"Sync Event" <${process.env.GMAIL_USER}>`,
        to: booking.userEmail,
        subject: `Refund Processed • ${
          refundType === "wallet" ? "Wallet" : "Bank"
        }`,
        html: `
          <div style="font-family: Inter,system-ui,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:640px;margin:auto;padding:24px;background:#f7f7fb">
            <div style="background:#ffffff;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.06);overflow:hidden">
              <div style="background:#111827;color:#fff;padding:16px 20px">
                <h2 style="margin:0;font-size:18px">Sync Event</h2>
              </div>
              <div style="padding:20px">
                <h3 style="margin-top:0">Your refund has been processed</h3>
                <p style="color:#374151">We have processed your cancellation and refund.</p>
                <table style="width:100%;border-collapse:collapse">
                  <tr><td style="padding:6px 0;color:#6b7280">Booking ID</td><td style="padding:6px 0;text-align:right">${bookingId}</td></tr>
                  <tr><td style="padding:6px 0;color:#6b7280">Amount</td><td style="padding:6px 0;text-align:right">₹${amount}</td></tr>
                  <tr><td style="padding:6px 0;color:#6b7280">Method</td><td style="padding:6px 0;text-align:right">${refundType}</td></tr>
                </table>
                <p style="margin-top:16px;color:#6b7280;font-size:12px">Bank refunds can take 5-7 business days to reflect.</p>
              </div>
            </div>
          </div>
        `,
      } as nodemailer.SendMailOptions;

      await transporter.sendMail(mailOptions);
      await requestRef.update({
        status: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error("Refund processing failed", err as any);
      try {
        await requestRef.update({
          status: "failed",
          error: String(err),
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch {}
    }
  }
);

export const sendCancellationEmailOnBookingCancel = onDocumentWritten(
  { document: "bookings/{bookingId}" },
  async (event) => {
    const before = event.data?.before?.data() as any | undefined;
    const after = event.data?.after?.data() as any | undefined;
    if (!after || !before) return;
    if (before.status === after.status) return;
    if (after.status !== "cancelled") return;

    try {
      const userEmail = after.userEmail;
      const bookingId = event.params.bookingId;
      const amount = after.totalAmount;
      if (!userEmail) return;

      const mailOptions = {
        from: `"Sync Event" <${process.env.GMAIL_USER}>`,
        to: userEmail,
        subject: `Booking Cancelled • ${bookingId}`,
        html: `
          <div style="font-family: Inter,system-ui,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:640px;margin:auto;padding:24px;background:#f7f7fb">
            <div style="background:#ffffff;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.06);overflow:hidden">
              <div style="background:#7f1d1d;color:#fff;padding:16px 20px">
                <h2 style="margin:0;font-size:18px">Sync Event</h2>
              </div>
              <div style="padding:20px">
                <h3 style="margin-top:0">Your booking has been cancelled</h3>
                <p style="color:#374151">We have cancelled your booking ${bookingId}. A refund of ₹${amount} will be processed based on your chosen method.</p>
                <p style="margin-top:16px;color:#6b7280;font-size:12px">Bank refunds can take 5-7 business days to reflect.</p>
              </div>
            </div>
          </div>
        `,
      } as nodemailer.SendMailOptions;
      await transporter.sendMail(mailOptions);
    } catch (e) {
      logger.error("Failed to send cancellation email", e as any);
    }
  }
);

// ========== CHAT NOTIFICATIONS ==========

export const sendChatPushNotification = onDocumentCreated(
  { document: "chats/{chatId}/messages/{messageId}" },
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const { senderId, senderName, receiverId, text } = message;

    if (!receiverId || senderId === receiverId) return;

    const userSnap = await admin
      .firestore()
      .collection("users")
      .doc(receiverId)
      .get();

    if (!userSnap.exists) return;

    const fcmToken = userSnap.data()?.fcmToken;
    if (!fcmToken) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: senderName ?? "New message",
        body: text ?? "📩 New message",
      },
      data: {
        type: "chat",
        chatId: event.params.chatId,
      },
      android: { priority: "high" },
    });
  }
);

// ========== AI FUNCTIONS ==========

export const generateEventDescription = onCall(
  {
    secrets: [GEMINI_API_KEY],
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new Error("Authentication required");
      }

      const { title, date, time, duration, location, existingDescription } =
        request.data;

      if (!title || !date || !location) {
        throw new Error("Missing required fields");
      }

      const apiKey = GEMINI_API_KEY.value();

      const prompt = existingDescription
        ? `Improve this event description: ${existingDescription}`
        : `Create a brief, engaging event description for: ${title} on ${date} at ${location}. Time: ${time}. Duration: ${duration}.`;

      const models = [
        "gemini-pro",
        "gemini-1.5-pro-latest",
        "gemini-1.5-flash-latest",
      ];

      for (const model of models) {
        try {
          logger.info(`Trying model: ${model}`);

          const res = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
            {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: {
                  temperature: 0.7,
                  maxOutputTokens: 500,
                },
              }),
            }
          );

          const data = await res.json();

          if (res.ok) {
            const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) {
              logger.info(`Success with model: ${model}`);
              return {
                text: text.replace(/\*\*/g, "").replace(/\*/g, "").trim(),
              };
            }
          } else {
            logger.warn(`Model ${model} failed:`, JSON.stringify(data));
          }
        } catch (e) {
          logger.warn(`Model ${model} error:`, e);
        }
      }

      throw new Error(
        "All models failed. Please check your API key and try again."
      );
    } catch (error: any) {
      logger.error("Error:", error);
      throw new Error(error.message || "Failed to generate description");
    }
  }
);

export const generateEventIdeas = onCall(
  {
    secrets: [GEMINI_API_KEY],
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new Error("Authentication required");
      }

      const { title, date, location } = request.data;

      if (!title || !date || !location) {
        throw new Error("Missing required fields");
      }

      const apiKey = GEMINI_API_KEY.value();

      const prompt = `Generate 5 creative ideas for: ${title} on ${date} at ${location}. Format as numbered list.`;

      const models = [
        "gemini-pro",
        "gemini-1.5-pro-latest",
        "gemini-1.5-flash-latest",
      ];

      for (const model of models) {
        try {
          logger.info(`Trying model: ${model}`);

          const res = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
            {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: {
                  temperature: 0.8,
                  maxOutputTokens: 600,
                },
              }),
            }
          );

          const data = await res.json();

          if (res.ok) {
            const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) {
              logger.info(`Success with model: ${model}`);
              return {
                text: text.replace(/\*\*/g, "").replace(/\*/g, "").trim(),
              };
            }
          } else {
            logger.warn(`Model ${model} failed:`, JSON.stringify(data));
          }
        } catch (e) {
          logger.warn(`Model ${model} error:`, e);
        }
      }

      throw new Error(
        "All models failed. Please check your API key and try again."
      );
    } catch (error: any) {
      logger.error("Error:", error);
      throw new Error(error.message || "Failed to generate ideas");
    }
  }
);