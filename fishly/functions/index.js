/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onValueWritten} = require("firebase-functions/v2/database");
const {initializeApp} = require("firebase-admin/app");
const {getDatabase} = require("firebase-admin/database");

// Initialize Firebase Admin
initializeApp();

// Set global options for cost control
setGlobalOptions({maxInstances: 10, region: "asia-southeast1"});

// sensorAlert function - triggers when sensor data is written to Firebase
exports.sensorAlert = onValueWritten({
  ref: "/Sensors",
  region: "asia-southeast1",
}, (event) => {
  // Get the data that was written
  const data = event.data.after.val();

  // Skip if no data
  if (!data) return null;

  // Extract sensor values
  const temperature = data["temperature_C"] || 0;
  const ph = data["pH Value"] || 0;
  const waterLevel = data["Water Level"] || 0;
  const turbidity = data["turbidity_NTU"] || 0;

  const notifications = [];
  const timestamp = new Date().toISOString();

  // Check temperature (20-30°C range) - FIXED: Now uses 30°C instead of 29°C
  if (temperature < 20 || temperature > 30) {
    notifications.push({
      title: "Critical Sensor Alert",
      description: `Temperature out of range: ${temperature.toFixed(2)}°C`,
      type: "critical",
      status: "unread",
      timestamp: timestamp,
    });
  }

  // Check pH (6.5-8.5 range)
  if (ph < 6.5 || ph > 8.5) {
    notifications.push({
      title: "Critical Sensor Alert",
      description: `pH out of range: ${ph.toFixed(2)}`,
      type: "critical",
      status: "unread",
      timestamp: timestamp,
    });
  }

  // Check water level (<80% is normal)
  if (waterLevel >= 80) {
    notifications.push({
      title: "Critical Sensor Alert",
      description: `Water level too high: ${waterLevel.toFixed(1)}%`,
      type: "warning",
      status: "unread",
      timestamp: timestamp,
    });
  }

  // Check turbidity (<80 NTU is normal)
  if (turbidity >= 80) {
    notifications.push({
      title: "Critical Sensor Alert",
      description: `Turbidity too high: ${turbidity.toFixed(2)} NTU`,
      type: "warning",
      status: "unread",
      timestamp: timestamp,
    });
  }

  // Write notifications to Firebase if any alerts were triggered
  if (notifications.length > 0) {
    const db = getDatabase();
    const notificationsRef = db.ref("notifications");

    // Add each notification
    const promises = notifications.map((notification) =>
      notificationsRef.push(notification),
    );

    return Promise.all(promises);
  }

  return null;
});
