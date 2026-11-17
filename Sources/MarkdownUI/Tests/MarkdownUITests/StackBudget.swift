import Foundation

/// Runs `body` on the current thread after using up stack until only `bytes` remain.
///
/// The simulator's main thread has an 8MB stack while a device's has 1MB, so a deep
/// recursion that kills a phone passes on the simulator. Burning the difference first
/// makes the simulator behave like a device that is already part-way into a layout pass.
@inline(never)
func withRemainingStack(_ bytes: Int, _ body: () -> Void) {
  let thread = pthread_self()
  let top = UInt(bitPattern: pthread_get_stackaddr_np(thread))
  let bottom = top - UInt(pthread_get_stacksize_np(thread))
  burnStack(until: bottom + UInt(bytes), body)
}

@inline(never)
private func burnStack(until limit: UInt, _ body: () -> Void) {
  var frame: (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64,
              UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64) =
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
  let here = withUnsafeMutablePointer(to: &frame) { UInt(bitPattern: $0) }
  if here <= limit {
    body()
  } else {
    burnStack(until: limit, body)
  }
  // Keeps the frame (and the recursion) from being optimized away.
  withExtendedLifetime(frame) {}
}

/// Runs `body` on a new thread with the given stack size and waits for it.
func onThread(stackSize: Int, _ body: @escaping () -> Void) {
  let done = DispatchSemaphore(value: 0)
  let thread = Thread {
    body()
    done.signal()
  }
  thread.stackSize = stackSize
  thread.start()
  done.wait()
}
