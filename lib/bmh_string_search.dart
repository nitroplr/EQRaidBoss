bool bmhContains({required String pattern, required String text, required int algo}) {
  if (algo == 0) return BoyerMooreHorspoolSearch(pattern: pattern, text: text) > -1;
  if (algo == 1) return BoyerMooreHorspoolSimpleSearch(pattern: pattern, text: text) > -1;
  if (algo == 2) return text.contains(pattern);
  if (algo == 3) return searchW3BM(text, pattern) > -1;
  return BoyerMooreHorspoolSearch(pattern: pattern, text: text) > -1;
}

int BoyerMooreHorspoolSearch({required String pattern, required String text}) {
  List<int> patternUnits = pattern.codeUnits;
  List<int> textUnits = text.codeUnits;
  List<int> shift = List.generate(256, (index) => patternUnits.length);

  for (int k = 0; k < patternUnits.length - 1; k++) {
    shift[patternUnits[k]] = patternUnits.length - 1 - k;
  }

  int i = 0, j = 0;

  while ((i + patternUnits.length) <= textUnits.length) {
    j = patternUnits.length - 1;

    while (textUnits[i + j] == patternUnits[j]) {
      j -= 1;
      if (j < 0) return i;
    }

    i = i + shift[textUnits[i + patternUnits.length - 1]];
  }
  return -1;
}

int BoyerMooreHorspoolSimpleSearch({required String pattern, required String text}) {
  int patternSize = pattern.length;
  int textSize = text.length;
  List<int> patternUnits = pattern.codeUnits;
  List<int> textUnits = text.codeUnits;

  int i = 0, j = 0;

  while ((i + patternSize) <= textSize) {
    j = patternSize - 1;
    while (textUnits[i + j] == patternUnits[j]) {
      j--;
      if (j < 0) return i;
    }
    i++;
  }
  return -1;
}

int NO_OF_CHARS = 256;

//A utility function to get maximum of two integers
int max(int a, int b) {
  return (a > b) ? a : b;
}

//The preprocessing function for Boyer Moore's
//bad character heuristic
void badCharHeuristic(List<int> str, int size, List<int> badchar) {

// Fill the actual value of last occurrence
// of a character (indices of table are ascii and values are index of occurrence)
  for (int i = 0; i < size; i++) {
    badchar[str[i]] = i;
  }
}

/* A pattern searching function that uses Bad
     Character Heuristic of Boyer Moore Algorithm */
int searchW3BM(String text, String pattern) {
  int m = pattern.length;
  int n = text.length;
  List<int> patternUnits = pattern.codeUnits;
  List<int> textUnits = text.codeUnits;
  List<int> badchar = List.generate(NO_OF_CHARS, (index) => -1);;

  badCharHeuristic(patternUnits, m, badchar);

  int s = 0;
  while (s <= (n - m)) {
    int j = m - 1;

    while (j >= 0 && patternUnits[j] == textUnits[s + j]) {
      j--;
    }

    if (j < 0) {
      return s;
      //for searching the string for multiple occurrences - from https://www.geeksforgeeks.org/boyer-moore-algorithm-for-pattern-searching/
      //s += (s + m < n) ? m - badchar[textUnits[s + m]] : 1;
    } else {
      s += max(1, j - badchar[textUnits[s + j]]);
    }
  }
  return -1;
}
