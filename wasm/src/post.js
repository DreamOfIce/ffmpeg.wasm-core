/**
 * Export the function for exiting the runtime
 */
Module["exit"] = function () {
  noExitRuntime = false; // noExitRuntime should be false to exit the runtime
  return exitJS(0);
};
