// This file provides a stub for non-web platforms.
// It ensures that the app can compile and run, but the
// web-specific functionality won't be available (and shouldn't be called).

String? getBrowserLanguage() {
  // Return null or throw an UnsupportedError if this function
  // were to be accidentally called on a non-web platform.
  // For getting a language code, returning null is often safest.
  return null;
  // Or:
  // throw UnsupportedError('getBrowserLanguage is only available on the web platform.');
}
