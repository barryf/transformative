self.addEventListener('install', e => {
 e.waitUntil(
   // after the service worker is installed,
   // open a new cache
   caches.open('barryfrost-com-cache').then(cache => {
     // add all URLs of resources we want to cache
     return cache.addAll([
       '/'
     ]);
   })
 );
});