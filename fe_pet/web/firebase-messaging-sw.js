importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDSZYTXmvclmiyQ3rCxPAh1e_EToXycFbQ",
  authDomain: "hcm202-2d75e.firebaseapp.com",
  projectId: "hcm202-2d75e",
  storageBucket: "hcm202-2d75e.firebasestorage.app",
  messagingSenderId: "837187985882",
  appId: "1:837187985882:web:a2012ea4bbf3b3003660e3"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png"
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
