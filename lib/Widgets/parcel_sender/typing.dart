import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

class Typing {
  static const int a = 30;
  static const int b = 48;
  static const int c = 46;
  static const int d = 32;
  static const int e = 18;
  static const int f = 33;
  static const int g = 34;
  static const int h = 35;
  static const int i = 23;
  static const int j = 36;
  static const int k = 37;
  static const int l = 38;
  static const int m = 50;
  static const int n = 49;
  static const int o = 24;
  static const int p = 25;
  static const int q = 16;
  static const int r = 19;
  static const int s = 31;
  static const int t = 20;
  static const int u = 22;
  static const int v = 47;
  static const int w = 17;
  static const int x = 45;
  static const int y = 21;
  static const int z = 44;
  static const int space = 57;
  static const int one = 2;
  static const int two = 3;
  static const int three = 4;
  static const int four = 5;
  static const int five = 6;
  static const int six = 7;
  static const int seven = 8;
  static const int eight = 9;
  static const int nine = 10;
  static const int zero = 11;
  static const int backspace = 14;

  static Future<void> typeNumber({required int number}) async {
    String numberString = number.toString();
    for (int charIndex = 0; charIndex < numberString.length; charIndex++) {
      String char = numberString[charIndex];
      switch (char) {
        case '0':
          {
            await _typeCharacter(zero);
          }
          break;
        case '1':
          {
            await _typeCharacter(one);
          }
          break;
        case '2':
          {
            await _typeCharacter(two);
          }
          break;
        case '3':
          {
            await _typeCharacter(three);
          }
          break;
        case '4':
          {
            await _typeCharacter(four);
          }
          break;
        case '5':
          {
            await _typeCharacter(five);
          }
          break;
        case '6':
          {
            await _typeCharacter(six);
          }
          break;
        case '7':
          {
            await _typeCharacter(seven);
          }
          break;
        case '8':
          {
            await _typeCharacter(eight);
          }
          break;
        case '9':
          {
            await _typeCharacter(nine);
          }
          break;
        default:
          break;
      }
    }
  }

  static Future<void> typeString({required String text}) async {
    text.toLowerCase();
    for (int charIndex = 0; charIndex < text.length; charIndex++) {
      String char = text[charIndex];
      switch (char) {
        case 'a':
          {
            await _typeCharacter(a);
          }
          break;
        case 'b':
          {
            await _typeCharacter(b);
          }
          break;
        case 'c':
          {
            await _typeCharacter(c);
          }
          break;
        case 'd':
          {
            await _typeCharacter(d);
          }
          break;
        case 'e':
          {
            await _typeCharacter(e);
          }
          break;
        case 'f':
          {
            await _typeCharacter(f);
          }
          break;
        case 'g':
          {
            await _typeCharacter(g);
          }
          break;
        case 'h':
          {
            await _typeCharacter(h);
          }
          break;
        case 'i':
          {
            await _typeCharacter(i);
          }
          break;
        case 'j':
          {
            await _typeCharacter(j);
          }
          break;
        case 'k':
          {
            await _typeCharacter(k);
          }
          break;
        case 'l':
          {
            await _typeCharacter(l);
          }
          break;
        case 'm':
          {
            await _typeCharacter(m);
          }
          break;
        case 'n':
          {
            await _typeCharacter(n);
          }
          break;
        case 'o':
          {
            await _typeCharacter(o);
          }
          break;
        case 'p':
          {
            await _typeCharacter(p);
          }
          break;
        case 'q':
          {
            await _typeCharacter(q);
          }
          break;
        case 'r':
          {
            await _typeCharacter(r);
          }
          break;
        case 's':
          {
            await _typeCharacter(s);
          }
          break;
        case 't':
          {
            await _typeCharacter(t);
          }
          break;
        case 'u':
          {
            await _typeCharacter(u);
          }
          break;
        case 'v':
          {
            await _typeCharacter(v);
          }
          break;
        case 'w':
          {
            await _typeCharacter(w);
          }
          break;
        case 'x':
          {
            await _typeCharacter(x);
          }
          break;
        case 'y':
          {
            await _typeCharacter(y);
          }
          break;
        case 'z':
          {
            await _typeCharacter(z);
          }
          break;
        default:
          break;
      }
    }
  }

  static Future<void> _typeCharacter(int character) async {
    final kbd = calloc<INPUT>();
    kbd.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    kbd.ref.ki.time = 0;
    kbd.ref.ki.wVk = 0;
    kbd.ref.ki.dwExtraInfo = 0;
    kbd.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_SCANCODE;
    kbd.ref.ki.wScan = character;
    SendInput(1, kbd, sizeOf<INPUT>());
    await Future.delayed(const Duration(milliseconds: 20));
    kbd.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(1, kbd, sizeOf<INPUT>());
  }

  static Future<void> deleteText()async{
    for (int i = 0; i < 35; i++) {
      final kbd = calloc<INPUT>();
      kbd.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
      kbd.ref.ki.time = 0;
      kbd.ref.ki.wVk = 0;
      kbd.ref.ki.dwExtraInfo = 0;
      kbd.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_SCANCODE;
      kbd.ref.ki.wScan = backspace;
      SendInput(1, kbd, sizeOf<INPUT>());
      await Future.delayed(const Duration(milliseconds: 5));
      kbd.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
      SendInput(1, kbd, sizeOf<INPUT>());
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }
}
