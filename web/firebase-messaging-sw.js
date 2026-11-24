importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAwpdb5xup0u87luCz04CyrZORmjsjtRyg",
  authDomain: "pertemuan-9-a85b7.firebaseapp.com",
  projectId: "pertemuan-9-a85b7",
  storageBucket: "pertemuan-9-a85b7.firebasestorage.app",
  messagingSenderId: "144588025310",
  appId: "1:144588025310:web:f21fa710476d076186014f",
  measurementId: "G-Y8G1E69VJ6",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Background message:", payload);

  const notificationTitle = payload.notification?.title || "Notifikasi Baru";
  const notificationOptions = {
    body: payload.notification?.body || "Ada pesan baru.",
    icon: "/icons/Icon-192.png",
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  event.waitUntil(clients.openWindow("/"));
});
