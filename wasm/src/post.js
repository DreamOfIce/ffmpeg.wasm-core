/**
 * Export the function for exiting the runtime
 */
Module["exit"] = function () {
  noExitRuntime = false; // noExitRuntime should be false to exit the runtime
  try {
    return exitJS(0);
  } catch (err) {
    if (!(err instanceof ExitStatus)) return false;
  }
  return true;
};
