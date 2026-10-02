{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      if (window.dismissVmnLoader) {
        window.dismissVmnLoader();
      }
    } catch (e) {
      console.error("Flutter initialization error:", e);
      if (window.dismissVmnLoader) {
        window.dismissVmnLoader();
      }
    }
  }
});
