#include "fairy_stockfish_shim.h"

#include <atomic>
#include <condition_variable>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <exception>
#include <iostream>
#include <mutex>
#include <streambuf>
#include <string>
#include <thread>

int fs_main(int argc, char* argv[]);

namespace {

// Feeds std::cin from queued command lines; blocks the engine thread when the
// queue is empty, like a terminal waiting for input.
class LineInputBuffer : public std::streambuf {
 public:
  void push(std::string line) {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      lines_.push_back(std::move(line));
    }
    available_.notify_one();
  }

  void reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    lines_.clear();
    current_.clear();
    setg(nullptr, nullptr, nullptr);
  }

 protected:
  int_type underflow() override {
    if (gptr() < egptr()) return traits_type::to_int_type(*gptr());

    std::unique_lock<std::mutex> lock(mutex_);
    available_.wait(lock, [this] { return !lines_.empty(); });
    current_ = std::move(lines_.front());
    lines_.pop_front();
    char* begin = &current_[0];
    setg(begin, begin, begin + current_.size());
    return traits_type::to_int_type(*gptr());
  }

 private:
  std::mutex mutex_;
  std::condition_variable available_;
  std::deque<std::string> lines_;
  std::string current_;
};

// Collects std::cout / std::cerr output and hands every complete line to the
// Dart callback. Search threads write concurrently, hence the mutex.
class LineOutputBuffer : public std::streambuf {
 public:
  void set_callback(fs_line_callback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    callback_ = callback;
    pending_.clear();
  }

  void emit_line(const std::string& line) {
    std::lock_guard<std::mutex> lock(mutex_);
    emit_locked(line);
  }

 protected:
  int_type overflow(int_type ch) override {
    if (traits_type::eq_int_type(ch, traits_type::eof())) return traits_type::not_eof(ch);
    char c = traits_type::to_char_type(ch);
    std::lock_guard<std::mutex> lock(mutex_);
    append_locked(&c, 1);
    return ch;
  }

  std::streamsize xsputn(const char* s, std::streamsize count) override {
    std::lock_guard<std::mutex> lock(mutex_);
    append_locked(s, count);
    return count;
  }

 private:
  void append_locked(const char* s, std::streamsize count) {
    for (std::streamsize i = 0; i < count; ++i) {
      if (s[i] == '\n') {
        emit_locked(pending_);
        pending_.clear();
      } else if (s[i] != '\r') {
        pending_.push_back(s[i]);
      }
    }
  }

  void emit_locked(const std::string& line) {
    if (callback_ == nullptr) return;
    char* copy = strdup(line.c_str());
    if (copy != nullptr) callback_(copy);
  }

  std::mutex mutex_;
  fs_line_callback callback_ = nullptr;
  std::string pending_;
};

LineInputBuffer g_input;
LineOutputBuffer g_output;
std::thread g_engine_thread;
std::atomic<bool> g_running{false};
std::streambuf* g_original_cin = nullptr;
std::streambuf* g_original_cout = nullptr;
std::streambuf* g_original_cerr = nullptr;

void run_engine() {
  char program_name[] = "fairy-stockfish";
  char* argv[] = {program_name, nullptr};
  try {
    fs_main(1, argv);
  } catch (const std::exception& error) {
    g_output.emit_line(std::string(FS_ERROR_PREFIX) + error.what());
  } catch (...) {
    g_output.emit_line(std::string(FS_ERROR_PREFIX) + "unknown native exception");
  }
  g_output.emit_line(FS_EXIT_SENTINEL);
}

}  // namespace

extern "C" {

int fs_start(fs_line_callback on_line) {
  bool expected = false;
  if (!g_running.compare_exchange_strong(expected, true)) return FS_ALREADY_RUNNING;

  g_input.reset();
  g_output.set_callback(on_line);
  g_original_cin = std::cin.rdbuf(&g_input);
  g_original_cout = std::cout.rdbuf(&g_output);
  g_original_cerr = std::cerr.rdbuf(&g_output);
  std::cin.clear();

  try {
    g_engine_thread = std::thread(run_engine);
  } catch (const std::exception&) {
    std::cin.rdbuf(g_original_cin);
    std::cout.rdbuf(g_original_cout);
    std::cerr.rdbuf(g_original_cerr);
    g_output.set_callback(nullptr);
    g_running = false;
    return FS_THREAD_ERROR;
  }
  return FS_OK;
}

void fs_send(const char* line) {
  if (line == nullptr || !g_running) return;
  g_input.push(std::string(line) + "\n");
}

void fs_free(char* line) { std::free(line); }

int fs_join(void) {
  if (!g_running) return FS_NOT_RUNNING;
  if (g_engine_thread.joinable()) g_engine_thread.join();

  std::cin.rdbuf(g_original_cin);
  std::cout.rdbuf(g_original_cout);
  std::cerr.rdbuf(g_original_cerr);
  g_output.set_callback(nullptr);
  g_running = false;
  return FS_OK;
}

}  // extern "C"
