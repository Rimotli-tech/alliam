{{flutter_js}}
{{flutter_build_config}}

async function startAlliam() {
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    const wasControlled = navigator.serviceWorker.controller != null;
    await Promise.all(registrations.map((registration) => registration.unregister()));

    if (
      wasControlled &&
      sessionStorage.getItem('alliam-service-worker-cleared') !== 'true'
    ) {
      sessionStorage.setItem('alliam-service-worker-cleared', 'true');
      window.location.reload();
      return;
    }
  }

  sessionStorage.removeItem('alliam-service-worker-cleared');
  _flutter.loader.load();
}

startAlliam();
