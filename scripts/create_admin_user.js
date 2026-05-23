/**
 * Script to create the admin Firebase Auth user and their Firestore profile.
 * Run with: node scripts/create_admin_user.js
 *
 * Requires: npm install firebase-admin
 * And a service account key placed at: scripts/serviceAccountKey.json
 */

const admin = require('firebase-admin');
const path = require('path');

// ─── Config ──────────────────────────────────────────────────────────────────
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');

const ADMIN_USER = {
  email: 'easternrp8@gmail.com',
  password: 'Admin@1234',        // Change this to your preferred password
  displayName: 'System Administrator',
  staffId: 'ADMIN001',
  region: 'Head Office',
  accountType: 'Admin',
  phone: '',
};
// ─────────────────────────────────────────────────────────────────────────────

let serviceAccount;
try {
  serviceAccount = require(SERVICE_ACCOUNT_PATH);
} catch (e) {
  console.error('\n❌  Could not find serviceAccountKey.json at:', SERVICE_ACCOUNT_PATH);
  console.error('   Please download it from:');
  console.error('   Firebase Console → Project Settings → Service Accounts → Generate new private key');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

async function createAdminUser() {
  console.log(`\n🔧  Creating Firebase Auth user: ${ADMIN_USER.email}`);

  let uid;
  try {
    // Try to get existing user first
    const existing = await auth.getUserByEmail(ADMIN_USER.email);
    uid = existing.uid;
    console.log(`ℹ️   User already exists (uid: ${uid}). Updating password…`);
    await auth.updateUser(uid, {
      password: ADMIN_USER.password,
      displayName: ADMIN_USER.displayName,
    });
    console.log(`✅  Password updated.`);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      // Create fresh
      const created = await auth.createUser({
        email: ADMIN_USER.email,
        password: ADMIN_USER.password,
        displayName: ADMIN_USER.displayName,
        emailVerified: true,
      });
      uid = created.uid;
      console.log(`✅  Auth user created (uid: ${uid})`);
    } else {
      throw err;
    }
  }

  // Write / merge Firestore profile
  console.log(`\n📝  Writing Firestore profile to Users/${uid}…`);
  await db.collection('Users').doc(uid).set({
    email: ADMIN_USER.email,
    name: ADMIN_USER.displayName,
    staffId: ADMIN_USER.staffId,
    region: ADMIN_USER.region,
    accountType: ADMIN_USER.accountType,
    phone: ADMIN_USER.phone,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`✅  Firestore profile written.`);
  console.log(`\n🎉  Done! You can now log in at https://easternrp-cd71e.web.app`);
  console.log(`   Email:    ${ADMIN_USER.email}`);
  console.log(`   Password: ${ADMIN_USER.password}`);
  process.exit(0);
}

createAdminUser().catch((err) => {
  console.error('\n❌  Error:', err.message);
  process.exit(1);
});
