'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "f610a9ff67272f440030e51f0b359176",
"version.json": "437348f6fe59292942e4dd48ef4adf57",
"favicon.ico": "6cadc4195b22c7207d0253a99d4956e9",
"index.html": "5656bffbad1c1cd210fd7bd5a86e1336",
"/": "5656bffbad1c1cd210fd7bd5a86e1336",
"main.dart.js": "37fe92f161847dbb85cc41cdc5d4866f",
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
".git/config": "ad76d16b20d6a17ea5b5f2e39a5d49c1",
".git/objects/59/238587b8604dc1b05745d6f428bdc3d952c33e": "0baa59a537ec1a8c2cfd447dfa111794",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/6a/ed031ff0390c45fcf05e720f08b64439ce5591": "b3ba967430683d7712a0622d20ad61e3",
".git/objects/35/c59585fc06e17cb30a2b4dfb1a80b1fab6f2bd": "89a7145b2f514058cda89b090dd1d90c",
".git/objects/69/b2023ef3b84225f16fdd15ba36b2b5fc3cee43": "6ccef18e05a49674444167a08de6e407",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/05/685baf984ad2b8236b852f3190c7a981c875a0": "3fe18952f83ba7a278869527e8eb62a8",
".git/objects/a3/bb966889d4a654537b1c35a231864a18efa9e9": "38d37c5f50722b0a037128fdcdedd567",
".git/objects/b5/df4230301011c91fa1d452cf5eebf0b1080bc0": "afda0ba88b77b0be499331c169ea8ad6",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/ad/2f90b78480aeb6608226d9db4ecbd3ec06aaeb": "4add97a99941aa0e9eed0f2173416ade",
".git/objects/ad/d1bdf024b24676c642558992fa91bdd6bf1106": "66e4c96fe833f3a7a0ecc7657b99da0e",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/bb/1adab03b3c21483b8be48dc8800343844c406c": "309fe7fb159affc9c0e9c6deeddb254c",
".git/objects/d0/101e197a6e0f96d21d0ccf61d6e78d2656c764": "e7ab2363191e31ba02430d1f959fe04a",
".git/objects/d1/8cfacc1a2f9256657c0920bdc045ee4e1e4921": "623e3106752ad59cba9e19493c8aaf03",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/ab/7fd82eed1c903ce4cd5fea2b693dd7979c4bad": "c7a3aec21114f038a25fa89997639a37",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/c0/e50c0e6719771009be470d2392af4710fb8f8e": "4a0c03db191ade960a6ea6e8c9367cbf",
".git/objects/ee/f86d7266d01c5516afad4977e49e2788752f04": "b994163526cd773aee21887c69583b3f",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/ed/80e2a0eb90d83338d14d436b2daaf55d37121b": "c24344fc8bb0e5464510ccedad9a1eb9",
".git/objects/c1/5a42ba516ee6d735372bfe177dcfdc05100e0a": "d83131080faf69cae681c38cc802c811",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/7b/637e4f6653155ed08ef2468155ca8b7021c937": "e8b61e2d0d2392119c4c2568e1012da9",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/62/397ce654c6d563378a5daefb063fe261a260aa": "cdff82de9f5d7b058e22d9ad745d0346",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3f/d48681da24254dddb4b932dc1b1c5a162fe72d": "8a2c6ebff96d4146c8f603c16e28f07f",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/08/6855173c0994f4b34f6bd1b125c662f8345a9a": "3560e0d31f24d53ef7e084c4b07dcf2c",
".git/objects/01/59f3facec904e5bc622f24367008422e0414c6": "2e472898070cd09ef1d1ac630eab34b8",
".git/objects/55/db3991aa8a11bb733da39d75a5fa8c2d929934": "fdd6317e253244578a4cdc54c0d9c09c",
".git/objects/64/0c44f4b8b3f3848fc72127945272da08f1fb0e": "29b66ca463fb2ecd3d0c464acf26ed8a",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/ba/9f1984cccb08c4dbea3f94a99afb3177657ff2": "ac22c08c26c1a80d06d4ef7a4c85ac22",
".git/objects/a9/01bf1a359ecf44478aef8e1696e9406443e4f8": "e1d74829fa7369e4310c5d95e25d7311",
".git/objects/a9/91f51138ffe059d588003dc7936aff059a0428": "b73a35563fa129bd884d8b5c53ee9231",
".git/objects/b7/1c7f140b537e5c491596e152a2bae756ec3a27": "320edf34a45ad0ab327f0e36c9e77b85",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/cc/fab74c1f56c330985060e2247607eaedb3c7d7": "ad5b6117df489509af208438785f208b",
".git/objects/e6/bf27b38fd1b3abead144caef97381f4ee15301": "d9425cc0893e3204eaf648023cd535c1",
".git/objects/e6/adceef7dc3f15e881fbb473da9a04d481e3db6": "204edb9e6cc97a48efea1c24b0d4dd73",
".git/objects/e6/eb8f689cbc9febb5a913856382d297dae0d383": "466fce65fb82283da16cdd7c93059ff3",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/79/92351afc3e51112968311050fb82409e768817": "59ed4d8edb9b20f48533d3f54f7f12f5",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/2b/6fd4eb0a3840075b1e154f9a992d93f0e46c3e": "b4f79f39613a9423d091da39693c43cf",
".git/objects/13/c0c590d1647a871b9abf4e0411798fecd27679": "a63a53f81ae7c3c405cfb56877adefc2",
".git/objects/7f/b575e050aa27e749428f86e8552a71dc3db8f8": "7e9acb541d89bbed1ba5655e26500a66",
".git/objects/7a/4929393fd48e018e77b9d4615f0c380209c2bc": "86d0f63bb52753d2fbd92780c2d7749c",
".git/objects/25/2cf4aeec994ce126d6262a1158dda878750e9a": "71848e5ef2e0f28e0144f677f84f42dc",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "2a283724ce5b3b18ce7d2fd806401987",
".git/logs/refs/heads/gh-pages": "1c7ed9d2fa746b9edc3f76ad5ca30b00",
".git/logs/refs/remotes/origin/gh-pages": "d0a7df58f53b5545f8aa06f7069688e3",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/gh-pages": "c491326fe186fe1e97524ba9e915c176",
".git/refs/remotes/origin/gh-pages": "c491326fe186fe1e97524ba9e915c176",
".git/index": "54af18eb697a6de35190058c4ffa3700",
".git/COMMIT_EDITMSG": "8439beb8b1732c0a2985d22d90c57484",
"assets/NOTICES": "ff7ddf1663764af68687bd3a753f37f1",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "401f98b5c8813e503026c78276217076",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "5ac9d9ee103155c5af36a4c20b32f00d",
"assets/fonts/MaterialIcons-Regular.otf": "9bfbd4cea638aaf5c858b227331a14d6",
"assets/assets/web_app/flutter_bootstrap.js": "99b41e7eea78381a885fb324695f87b8",
"assets/assets/web_app/version.json": "52b1e8c032116686167f23aa252c5c01",
"assets/assets/web_app/favicon.ico": "6cadc4195b22c7207d0253a99d4956e9",
"assets/assets/web_app/index.html": "5656bffbad1c1cd210fd7bd5a86e1336",
"assets/assets/web_app/main.dart.js": "37fe92f161847dbb85cc41cdc5d4866f",
"assets/assets/web_app/flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"assets/assets/web_app/favicon.png": "5dcef449791fa27946b3d35ad8803796",
"assets/assets/web_app/icons/favicon.ico": "6cadc4195b22c7207d0253a99d4956e9",
"assets/assets/web_app/icons/apple-touch-icon.png": "31fcf77cf9f14a30bc50d9a784be9271",
"assets/assets/web_app/icons/icon-192.png": "6710f0ca62642fd6064425999ad5e2ec",
"assets/assets/web_app/icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"assets/assets/web_app/icons/icon-192-maskable.png": "dccde69cef4958c16d60dbe3dedd04ba",
"assets/assets/web_app/icons/icon-512-maskable.png": "a95d53068a869efced6c584d42339161",
"assets/assets/web_app/icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"assets/assets/web_app/icons/icon-512.png": "fe179860948377feee63834ba4c5a20c",
"assets/assets/web_app/manifest.json": "1a8f9b4f1417f94e8311bb7c6a597e16",
"assets/assets/web_app/web_app_manifest.txt": "723fcbf589c0b4b5ea529cc9df707dd6",
"assets/assets/web_app/assets/NOTICES": "ff7ddf1663764af68687bd3a753f37f1",
"assets/assets/web_app/assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/assets/web_app/assets/AssetManifest.bin.json": "401f98b5c8813e503026c78276217076",
"assets/assets/web_app/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/assets/web_app/assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/assets/web_app/assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/web_app/assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/assets/web_app/assets/AssetManifest.bin": "5ac9d9ee103155c5af36a4c20b32f00d",
"assets/assets/web_app/assets/fonts/MaterialIcons-Regular.otf": "9bfbd4cea638aaf5c858b227331a14d6",
"assets/assets/web_app/canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"assets/assets/web_app/canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"assets/assets/web_app/canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"assets/assets/web_app/canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"assets/assets/web_app/canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"assets/assets/web_app/canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"assets/assets/web_app/canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"assets/assets/web_app/canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"assets/assets/web_app/canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"assets/assets/web_app/canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"assets/assets/web_app/canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"assets/assets/web_app/canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"assets/assets/img/logo.png": "2153f1de91be8d4370949876477027f5",
"assets/assets/img/logo.svg": "2db00111fff30e343ca1e8705ee05143",
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
