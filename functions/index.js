const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentUpdated, onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

// ─── CONFIG ────────────────────────────────────────────────────────────────
// Set your bot token in functions/.env as: TELEGRAM_TOKEN=your_token_here
// For production deploy: firebase functions:secrets:set TELEGRAM_TOKEN
function getBotToken() {
  return process.env.TELEGRAM_TOKEN || "";
}

// ─── HELPERS ───────────────────────────────────────────────────────────────

/**
 * Send a Telegram message to a specific chat ID.
 */
async function sendTelegramMessage(chatId, text) {
  const token = getBotToken();
  if (!token || !chatId) return;

  const url = `https://api.telegram.org/bot${token}/sendMessage`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        chat_id: chatId,
        text: text,
        parse_mode: "HTML",
      }),
    });
    const data = await res.json();
    if (!data.ok) {
      console.error("Telegram API error:", data.description);
    }
  } catch (err) {
    console.error("Failed to send Telegram message:", err);
  }
}

/**
 * Fetch a user document from Firestore.
 */
async function getUser(uid) {
  if (!uid) return null;
  const doc = await db.collection("users").doc(uid).get();
  return doc.exists ? doc.data() : null;
}

/**
 * Send a Telegram notification to a user by their uid.
 */
async function notifyUser(uid, message) {
  const user = await getUser(uid);
  if (!user || !user.telegramChatId) return;
  await sendTelegramMessage(user.telegramChatId, message);
}

// ─── WEBHOOK: Handle Telegram messages from users ──────────────────────────

/**
 * HTTPS endpoint that Telegram sends all updates to (the webhook).
 * When a user sends /start <uid> to the bot, we save their chat_id.
 */
exports.telegramWebhook = onRequest(async (req, res) => {
  const update = req.body;

  if (!update || !update.message) {
    return res.sendStatus(200); // Acknowledge silently
  }

  const msg = update.message;
  const chatId = msg.chat.id.toString();
  const text = (msg.text || "").trim();

  // Handle /start <uid> command
  if (text.startsWith("/start")) {
    const parts = text.split(" ");
    const uid = parts[1]; // The ThumbHQ user ID passed as deep link param

    if (uid) {
      try {
        await db.collection("users").doc(uid).update({
          telegramChatId: chatId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await sendTelegramMessage(
          chatId,
          "✅ <b>ThumbHQ Connected!</b>\n\nYou'll now receive real-time notifications here whenever something needs your attention. 🎉"
        );
      } catch (err) {
        console.error("Error linking Telegram account:", err);
        await sendTelegramMessage(
          chatId,
          "❌ Failed to link your account. Please try again from the app."
        );
      }
    } else {
      await sendTelegramMessage(
        chatId,
        "👋 Welcome to <b>ThumbHQ Bot</b>!\n\nTo link your account, please tap the <b>Link Telegram</b> button inside the ThumbHQ app."
      );
    }
  }

  res.sendStatus(200);
});

// ─── TRIGGER: Project updated ───────────────────────────────────────────────

/**
 * Fires whenever a project document is updated in Firestore.
 * Handles: assignment, revision requests, submission, approval.
 */
exports.onProjectUpdated = onDocumentUpdated("projects/{projectId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const projectTitle = after.title || "a project";

    // ── Strategist assigned ──────────────────────────────────────
    if (!before.strategistId && after.strategistId) {
      await notifyUser(
        after.strategistId,
        `📋 <b>You've been assigned as Strategist!</b>\n\nProject: <b>${projectTitle}</b>\n\nLog in to ThumbHQ to get started.`
      );
    }

    // ── Designer assigned ────────────────────────────────────────
    if (!before.designerId && after.designerId) {
      await notifyUser(
        after.designerId,
        `🎨 <b>You've been assigned as Designer!</b>\n\nProject: <b>${projectTitle}</b>\n\nLog in to ThumbHQ to get started.`
      );
    }

    // ── Strategist sent to revision ──────────────────────────────
    if (
      before.strategistStatus !== "revision" &&
      after.strategistStatus === "revision"
    ) {
      const note = after.strategistRevisionNote || "No note provided.";
      await notifyUser(
        after.strategistId,
        `🔁 <b>Revision Requested (Strategist)</b>\n\nProject: <b>${projectTitle}</b>\nNote: ${note}`
      );
    }

    // ── Designer sent to revision ────────────────────────────────
    if (
      before.designerStatus !== "revision" &&
      after.designerStatus === "revision"
    ) {
      const note = after.designerRevisionNote || "No note provided.";
      await notifyUser(
        after.designerId,
        `🔁 <b>Revision Requested (Designer)</b>\n\nProject: <b>${projectTitle}</b>\nNote: ${note}`
      );
    }

    // ── Strategist submitted ─────────────────────────────────────
    if (
      before.strategistStatus !== "submitted" &&
      after.strategistStatus === "submitted"
    ) {
      // Fetch strategist name
      let strategistName = "Unknown";
      if (after.strategistId) {
        const sDoc = await db.collection("users").doc(after.strategistId).get();
        if (sDoc.exists) strategistName = sDoc.data().displayName || "Unknown";
      }

      const clientName = after.clientName || "No client";
      const deadline = after.deadline
        ? new Date(after.deadline._seconds * 1000).toLocaleDateString("en-US", {
            day: "numeric", month: "short", year: "numeric",
          })
        : "No deadline";
      const ticketSize = after.ticketSize ? `$${after.ticketSize}` : "N/A";

      const managersSnap = await db
        .collection("users")
        .where("role", "==", "manager")
        .get();
      for (const doc of managersSnap.docs) {
        const manager = doc.data();
        if (manager.telegramChatId) {
          await sendTelegramMessage(
            manager.telegramChatId,
            `📤 <b>Brief Submitted for Review</b>\n\n` +
            `🎯 <b>Project:</b> ${projectTitle}\n` +
            `👤 <b>Client:</b> ${clientName}\n` +
            `📋 <b>Strategist:</b> ${strategistName}\n` +
            `📅 <b>Deadline:</b> ${deadline}\n` +
            `💰 <b>Ticket Size:</b> ${ticketSize}\n\n` +
            `The strategist has submitted their brief. Please review it in ThumbHQ.`
          );
        }
      }
    }

    // ── Designer submitted ───────────────────────────────────────
    if (
      before.designerStatus !== "submitted" &&
      after.designerStatus === "submitted"
    ) {
      // Fetch designer name
      let designerName = "Unknown";
      let designerRole = "Designer";
      if (after.designerId) {
        const dDoc = await db.collection("users").doc(after.designerId).get();
        if (dDoc.exists) {
          designerName = dDoc.data().displayName || "Unknown";
          designerRole = dDoc.data().role || "designer";
        }
      }

      const clientName = after.clientName || "No client";
      const deadline = after.deadline
        ? new Date(after.deadline._seconds * 1000).toLocaleDateString("en-US", {
            day: "numeric", month: "short", year: "numeric",
          })
        : "No deadline";
      const ticketSize = after.ticketSize ? `$${after.ticketSize}` : "N/A";

      const managersSnap = await db
        .collection("users")
        .where("role", "==", "manager")
        .get();
      for (const doc of managersSnap.docs) {
        const manager = doc.data();
        if (manager.telegramChatId) {
          await sendTelegramMessage(
            manager.telegramChatId,
            `🖼️ <b>Final Design Submitted for Review</b>\n\n` +
            `🎯 <b>Project:</b> ${projectTitle}\n` +
            `👤 <b>Client:</b> ${clientName}\n` +
            `🎨 <b>Designer:</b> ${designerName} (${designerRole})\n` +
            `📅 <b>Deadline:</b> ${deadline}\n` +
            `💰 <b>Ticket Size:</b> ${ticketSize}\n\n` +
            `The designer has submitted their final design. Please review it in ThumbHQ.`
          );
        }
      }
    }

    // ── Needs approval ───────────────────────────────────────────
    if (
      before.approvalStatus !== "needs_approval" &&
      after.approvalStatus === "needs_approval"
    ) {
      const managersSnap = await db
        .collection("users")
        .where("role", "==", "manager")
        .get();
      for (const doc of managersSnap.docs) {
        const manager = doc.data();
        if (manager.telegramChatId) {
          await sendTelegramMessage(
            manager.telegramChatId,
            `⚠️ <b>Project Needs Approval</b>\n\nProject: <b>${projectTitle}</b>\nPlease review and approve in ThumbHQ.`
          );
        }
      }
    }

    // ── Project approved ─────────────────────────────────────────
    if (
      before.approvalStatus !== "approved" &&
      after.approvalStatus === "approved"
    ) {
      if (after.strategistId) {
        await notifyUser(
          after.strategistId,
          `✅ <b>Project Approved!</b>\n\nProject: <b>${projectTitle}</b>\nGreat work! Your commission has been credited. 🎉`
        );
      }
      if (after.designerId) {
        await notifyUser(
          after.designerId,
          `✅ <b>Project Approved!</b>\n\nProject: <b>${projectTitle}</b>\nGreat work! Your commission has been credited. 🎉`
        );
      }
    }

    // ── Brief Updated ─────────────────────────────────────────────
    if (JSON.stringify(before.brief) !== JSON.stringify(after.brief)) {
      const managersSnap = await db
        .collection("users")
        .where("role", "==", "manager")
        .get();
      for (const doc of managersSnap.docs) {
        const manager = doc.data();
        if (manager.telegramChatId) {
          await sendTelegramMessage(
            manager.telegramChatId,
            `📝 <b>Brief Saved</b>\n\nProject: <b>${projectTitle}</b>\nThe brief for this project has been updated.`
          );
        }
      }
    }

    // ── Final Design Updated ──────────────────────────────────────
    if (JSON.stringify(before.finalDesign) !== JSON.stringify(after.finalDesign)) {
      const managersSnap = await db
        .collection("users")
        .where("role", "==", "manager")
        .get();
      for (const doc of managersSnap.docs) {
        const manager = doc.data();
        if (manager.telegramChatId) {
          await sendTelegramMessage(
            manager.telegramChatId,
            `🖼️ <b>Final Design Saved</b>\n\nProject: <b>${projectTitle}</b>\nThe final design for this project has been updated.`
          );
        }
      }
    }
  });

// ─── TRIGGER: New chat message ──────────────────────────────────────────────

/**
 * Fires whenever a new message is created in a project's messages subcollection.
 * Notifies all project participants except the sender.
 */
exports.onMessageCreated = onDocumentCreated("projects/{projectId}/messages/{messageId}", async (event) => {
    const message = event.data.data();
    const {projectId} = event.params;

    const projectDoc = await db.collection("projects").doc(projectId).get();
    if (!projectDoc.exists) return;

    const project = projectDoc.data();
    const projectTitle = project.title || "a project";
    const senderName = message.senderName || "Someone";
    const content = message.content || "";
    const senderId = message.senderId;

    // Collect all unique participant UIDs (excluding sender)
    const participantIds = new Set();
    if (project.strategistId && project.strategistId !== senderId) {
      participantIds.add(project.strategistId);
    }
    if (project.designerId && project.designerId !== senderId) {
      participantIds.add(project.designerId);
    }

    // Also notify manager if they're not the sender
    const managersSnap = await db
      .collection("users")
      .where("role", "==", "manager")
      .get();
    for (const doc of managersSnap.docs) {
      if (doc.id !== senderId) {
        participantIds.add(doc.id);
      }
    }

    // Trim message preview to 100 chars
    const preview =
      content.length > 100 ? content.substring(0, 100) + "..." : content;

    const notificationText =
      `💬 <b>New Message in ${projectTitle}</b>\n\n` +
      `<b>${senderName}:</b> ${preview}`;

    // Send notification to each participant
    await Promise.all(
      Array.from(participantIds).map((uid) =>
        notifyUser(uid, notificationText)
      )
    );
  });
