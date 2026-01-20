'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "e2335f179f11fce9fa5524b71a6230e8",
"version.json": "52b1e8c032116686167f23aa252c5c01",
"favicon.ico": "6cadc4195b22c7207d0253a99d4956e9",
"index.html": "5656bffbad1c1cd210fd7bd5a86e1336",
"/": "5656bffbad1c1cd210fd7bd5a86e1336",
"main.dart.js": "bda0f65a24dfb35941322d00eecdb500",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/favicon.ico": "6cadc4195b22c7207d0253a99d4956e9",
"icons/apple-touch-icon.png": "31fcf77cf9f14a30bc50d9a784be9271",
"icons/icon-192.png": "6710f0ca62642fd6064425999ad5e2ec",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/icon-192-maskable.png": "dccde69cef4958c16d60dbe3dedd04ba",
"icons/icon-512-maskable.png": "a95d53068a869efced6c584d42339161",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/icon-512.png": "fe179860948377feee63834ba4c5a20c",
"manifest.json": "1a8f9b4f1417f94e8311bb7c6a597e16",
"assets/NOTICES": "ff7ddf1663764af68687bd3a753f37f1",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "38ae92547ec734755f8bd2039ecc7983",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "d869bd9116e6a7eb8a2378ac65b1b942",
"assets/fonts/MaterialIcons-Regular.otf": "0e590dbab16939d0f30f7bcfcc6b6fa5",
"assets/assets/web_app/flutter_bootstrap.js": "47d53f88e0991a3e99ea19791083e662",
"assets/assets/web_app/version.json": "170e4ff046ac630cc2aae9c3a5ea808a",
"assets/assets/web_app/favicon.ico": "6cadc4195b22c7207d0253a99d4956e9",
"assets/assets/web_app/index.html": "5656bffbad1c1cd210fd7bd5a86e1336",
"assets/assets/web_app/main.dart.js": "bda0f65a24dfb35941322d00eecdb500",
"assets/assets/web_app/flutter.js": "888483df48293866f9f41d3d9274a779",
"assets/assets/web_app/favicon.png": "5dcef449791fa27946b3d35ad8803796",
"assets/assets/web_app/icons/favicon.ico": "6cadc4195b22c7207d0253a99d4956e9",
"assets/assets/web_app/icons/apple-touch-icon.png": "31fcf77cf9f14a30bc50d9a784be9271",
"assets/assets/web_app/icons/Icon-192.png": "6710f0ca62642fd6064425999ad5e2ec",
"assets/assets/web_app/icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"assets/assets/web_app/icons/icon-192-maskable.png": "dccde69cef4958c16d60dbe3dedd04ba",
"assets/assets/web_app/icons/icon-512-maskable.png": "a95d53068a869efced6c584d42339161",
"assets/assets/web_app/icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"assets/assets/web_app/icons/Icon-512.png": "fe179860948377feee63834ba4c5a20c",
"assets/assets/web_app/manifest.json": "1a8f9b4f1417f94e8311bb7c6a597e16",
"assets/assets/web_app/web_app_manifest.txt": "d593f1564af7eb1da837b231b683770a",
"assets/assets/web_app/assets/AssetManifest.json": "09085d04ec05d20098382fb67764ea9c",
"assets/assets/web_app/assets/NOTICES": "fa5cbced819a18519441ccacd005b040",
"assets/assets/web_app/assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/assets/web_app/assets/AssetManifest.bin.json": "07fa9279d4e14e4f4ce84e41d7723cd6",
"assets/assets/web_app/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/assets/web_app/assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/assets/web_app/assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/web_app/assets/AssetManifest.bin": "89b7528df4b9b9c899fe3723dc1dba4f",
"assets/assets/web_app/assets/fonts/MaterialIcons-Regular.otf": "0e590dbab16939d0f30f7bcfcc6b6fa5",
"assets/assets/web_app/canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"assets/assets/web_app/canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"assets/assets/web_app/canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"assets/assets/web_app/canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"assets/assets/web_app/canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"assets/assets/web_app/canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"assets/assets/web_app/canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"assets/assets/web_app/canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"assets/assets/web_app/canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"assets/assets/web_app/canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"assets/assets/web_app/canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"assets/assets/web_app/canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
