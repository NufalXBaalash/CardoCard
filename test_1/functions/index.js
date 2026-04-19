const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// Helper to get service account email automatically
let serviceAccountEmail;
admin.auth().listUsers(1).then(() => {
  // This is just to trigger internal discovery if needed
}).catch(() => {});

exports.getCustomToken = onCall({
  cors: true,
  region: "us-central1", // You can change this to your preferred region
}, async (request) => {
  // In v2, the input data is in request.data
  const data = request.data;
  const rawUid = data.uid ? String(data.uid).trim() : null;

  console.log(`[NFC Auth] 2nd Gen Processing. Raw UID: "${rawUid}" (Length: ${rawUid ? rawUid.length : 0})`);

  if (!rawUid) {
    throw new HttpsError("invalid-argument", "No UID provided.");
  }

  try {
    // 1. Try to find the document in Firestore
    // Normalize UID (remove spaces, convert to lowercase if needed)
    const normalizedUid = rawUid.toLowerCase();
    const userRef = admin.firestore().collection("users").doc(normalizedUid);
    let doc = await userRef.get();

    // Try original case if lowercase fails
    if (!doc.exists) {
        doc = await admin.firestore().collection("users").doc(rawUid).get();
    }

    if (!doc.exists) {
      console.error(`[NFC Auth] FAILURE: Document "users/${rawUid}" not found.`);
      throw new HttpsError(
          "not-found",
          "NFC card not registered. (ID: " + rawUid + ")",
      );
    }

    const docData = doc.data();
    let targetAuthUid = rawUid;

    // 2. Handle Mapping (if the card UID is mapped to a real user UID)
    if (docData.type === "nfc_mapping") {
      targetAuthUid = docData.linkedUser;
      console.log(`[NFC Auth] Mapping found -> Target User: ${targetAuthUid}`);
    } else {
      console.log(`[NFC Auth] Direct user found -> Target User: ${targetAuthUid}`);
    }

    // 3. Verify user exists in Firebase Auth
    try {
      await admin.auth().getUser(targetAuthUid);
    } catch (authError) {
      console.error(`[NFC Auth] Auth Error: User ${targetAuthUid} missing from Firebase Auth.`);
      throw new HttpsError("not-found", "User account exists in DB but not in Auth system.");
    }

    // 4. Success - Generate Custom Token
    const customToken = await admin.auth().createCustomToken(targetAuthUid);
    console.log(`[NFC Auth] SUCCESS: Token generated for ${targetAuthUid}`);

    return {customToken};

  } catch (error) {
    console.error("[NFC Auth] CRITICAL ERROR:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message);
  }
});
