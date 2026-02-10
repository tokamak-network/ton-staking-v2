export const normalize = (value: string) =>
  value.toLowerCase().replace(/[^a-z0-9]/g, "");

export const levenshtein = (a: string, b: string) => {
  const matrix = Array.from({ length: a.length + 1 }, () =>
    Array(b.length + 1).fill(0)
  );

  for (let i = 0; i <= a.length; i += 1) matrix[i][0] = i;
  for (let j = 0; j <= b.length; j += 1) matrix[0][j] = j;

  for (let i = 1; i <= a.length; i += 1) {
    for (let j = 1; j <= b.length; j += 1) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost
      );
    }
  }

  return matrix[a.length][b.length];
};

export const similarity = (a: string, b: string) => {
  const na = normalize(a);
  const nb = normalize(b);
  if (!na || !nb) return 0;
  const distance = levenshtein(na, nb);
  return 1 - distance / Math.max(na.length, nb.length);
};

export const findBestMatch = (target: string, candidates: string[]) => {
  let best = "";
  let bestScore = 0;

  for (const candidate of candidates) {
    const score = similarity(target, candidate);
    if (score > bestScore) {
      bestScore = score;
      best = candidate;
    }
  }

  return { best, score: bestScore };
};
