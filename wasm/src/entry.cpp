#include "config.h"
#include <emscripten.h>
#include <emscripten/bind.h>

#if HAVE_THREADS
#include <atomic>
#include <functional>
#include <thread>
#include <emscripten/proxying.h>
emscripten::ProxyingQueue queue;
#endif

using namespace std;

extern int main(int argc, char **argv);

/**
 * Export flags
 */

EMSCRIPTEN_BINDINGS(ffmpeg)
{
  emscripten::constant("simd", false); // reserved for future use
  emscripten::constant("thread", (bool)HAVE_THREADS);
  emscripten::constant("wasi", false); // reserved for future use
}

extern "C"
{
  /**
   * @brief Just a wrapper of main()
   */
  int EMSCRIPTEN_KEEPALIVE exec(int argc, char **argv)
  {
    return main(argc, argv);
  }

#if HAVE_THREADS
  /**
   * @brief Execute main() asynchronously in a new thread
   * @param callback call when finish
   * @return true if `func` was successfully
// enqueued and the target thread notified
   */
  bool EMSCRIPTEN_KEEPALIVE execAsync(int argc, char **argv, void (*resolve)(int code), void (*reject)(int code))
  {
    shared_ptr<int> code{0};
    atomic<bool> start{false};
    thread taskThread([&]()
                      { 
                        while (!start)
                          sched_yield();
                        queue.execute(); });
    auto result = queue.proxyCallback(
        taskThread.native_handle(),
        [argc, argv, &code]()
        {
          *code = exec(argc, argv);
        },
        [&resolve, &code]()
        {
          resolve(*code);
        },
        [&reject, &code]()
        {
          reject(*code);
        });
    start = true;
    taskThread.detach();
    return result;
  }

#endif
}