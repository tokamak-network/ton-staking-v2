export const formatToken = (value: string | undefined, decimals = 27, precision = 4) => {
  if (!value) return "-";
  try {
    const big = BigInt(value);
    const base = 10n ** BigInt(decimals);
    const integer = big / base;
    const fraction = big % base;
    const fractionStr = fraction.toString().padStart(decimals, "0").slice(0, precision);
    return `${integer.toString()}.${fractionStr}`;
  } catch {
    return value ?? "-";
  }
};
